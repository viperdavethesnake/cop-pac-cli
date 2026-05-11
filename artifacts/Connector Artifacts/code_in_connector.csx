    using System;
    using System.Net;
    using System.Net.Http;
    using System.Threading.Tasks;
    using Newtonsoft.Json.Linq;
    using System.Text;
    using System.Linq;
    using System.Collections.Specialized;

    public class Script : ScriptBase
    {
        // Configuration constants for chunking
        private const int DEFAULT_CHUNK_SIZE_BYTES = 60000; // 60K chunk
        private const string CHUNK_QUERY_PARAM = "chunk";
        private const string CHUNK_SIZE_PARAM = "chunkSize";
        private const string USE_CHUNKING_PARAM = "useChunking";
        
        public override async Task<HttpResponseMessage> ExecuteAsync()
        {
            // Handle possible base64 encoding for OperationId
            string opId = this.Context.OperationId;
            try
            {
                byte[] data = Convert.FromBase64String(opId);
                opId = Encoding.UTF8.GetString(data);
            }
            catch { }
            
            if (opId == "SearchNexus")
            {
                return await HandleSearchWrapper().ConfigureAwait(false);
            }

            if (opId == "GetExternalItem")
            {
                return await HandleGetExternalItemChunked().ConfigureAwait(false);
            }
                        
            // Fallback: unknown operation
            HttpResponseMessage error = new HttpResponseMessage(HttpStatusCode.BadRequest);
            error.Content = CreateJsonContent($"Unknown operation ID '{opId}'");
            return error;
            
        }

        private async Task<HttpResponseMessage> HandleGetExternalItem()
        {
            // Extract path parameters from context
            var pathParams = this.Context.Request.RequestUri.AbsolutePath;
            
            // For now, forward the request directly to Graph API
            var outbound = new HttpRequestMessage(
                HttpMethod.Get, 
                $"https://graph.microsoft.com{pathParams}");
            
            // Preserve query parameters
            if (this.Context.Request.RequestUri.Query != null)
            {
                outbound.RequestUri = new Uri($"https://graph.microsoft.com{pathParams}{this.Context.Request.RequestUri.Query}");
            }
            
            // Forward authorization header
            if (this.Context.Request.Headers.TryGetValues("Authorization", out var authHeaders))
            {
                outbound.Headers.TryAddWithoutValidation("Authorization", authHeaders);
            }
            
            // Forward the request
            return await this.Context.SendAsync(outbound, this.CancellationToken)
                                .ConfigureAwait(false);
        }
        
        private async Task<HttpResponseMessage> HandleGetExternalItemChunked()
        {
            HttpStatusCode statusCode = HttpStatusCode.InternalServerError;

            try
            {
                // Parse query parameters
                NameValueCollection queryParams = System.Web.HttpUtility.ParseQueryString(this.Context.Request.RequestUri.Query);
                
                // Get chunking parameters
                int chunkIndex = 0;
                if (!string.IsNullOrEmpty(queryParams[CHUNK_QUERY_PARAM]))
                {
                    int.TryParse(queryParams[CHUNK_QUERY_PARAM], out chunkIndex);
                }
                
                int chunkSize = DEFAULT_CHUNK_SIZE_BYTES;
                if (!string.IsNullOrEmpty(queryParams[CHUNK_SIZE_PARAM]))
                {
                    int.TryParse(queryParams[CHUNK_SIZE_PARAM], out chunkSize);
                    chunkSize = Math.Max(1024, Math.Min(chunkSize, 10 * 1024 * 1024)); // Min 1KB, Max 10MB
                }
                
                bool useChunking = true;
                if (!string.IsNullOrEmpty(queryParams[USE_CHUNKING_PARAM]))
                {
                    bool.TryParse(queryParams[USE_CHUNKING_PARAM], out useChunking);
                }
    /*
            //Debugging: Enable this to send api params back to caller
            var pathParams = this.Context.Request.RequestUri.AbsolutePath;

            if (pathParams.EndsWith("/chunked", StringComparison.OrdinalIgnoreCase))
            {
                pathParams = pathParams.Substring(0, pathParams.Length - "/chunked".Length);
            }
            JObject wrappedBody = new JObject {
                ["PathParams"] = pathParams,
                ["UseChunking"] = useChunking,
                ["chunksize"] = chunkSize,
                ["chunkIndex"] = chunkIndex
            };
            var response = new HttpResponseMessage(HttpStatusCode.OK);
            response.Content = CreateJsonContent(wrappedBody.ToString());
            return response;
    */           
                // If chunking is explicitly disabled, fall back to original behavior
                if (!useChunking || chunkIndex == 0 && chunkSize <= 0)
                {
                    return await HandleGetExternalItem().ConfigureAwait(false);
                }
                
                // Fetch the full item from Microsoft Graph
                var fullItemResponse = await FetchFullExternalItemForChunking(queryParams).ConfigureAwait(false);
                
                if (!fullItemResponse.IsSuccessStatusCode)
                {
                    return CreateEmptyContentResponse(fullItemResponse.StatusCode); // Error... Return empty response
                }
                statusCode = fullItemResponse.StatusCode;
                
                // Parse the full response
                string responseContent = await fullItemResponse.Content.ReadAsStringAsync().ConfigureAwait(false);
                // If response is empty or invalid JSON, return empty response
                if (string.IsNullOrWhiteSpace(responseContent))
                {   
                    return CreateEmptyContentResponse();
                }   
                var fullItem = JObject.Parse(responseContent);
                
                // Apply chunking logic
                return ApplyChunkingToResponse(fullItem, chunkIndex, chunkSize);
            }
            catch (Exception ex)
            {
                // JSON parsing or processing error - return empty but successful
                return CreateEmptyContentResponse(statusCode);
            }
        
        }

        private HttpResponseMessage CreateEmptyContentResponse(HttpStatusCode statusCode = HttpStatusCode.InternalServerError)
        {
            // Create a response with empty content but successful status
            var emptyResponse = new JObject
            {
                ["id"] = "empty",
                ["@odata.context"] = "https://graph.microsoft.com/v1.0/$metadata#external/connectors/externalItem/$entity",
                ["content"] = new JObject
                {
                    ["type"] = "text",
                    ["value"] = "" // Empty string
                },
                ["chunkMetadata"] = new JObject
                {
                    ["chunkIndex"] = 0,
                    ["chunkSize"] = DEFAULT_CHUNK_SIZE_BYTES,
                    ["totalChunks"] = 1,
                    ["isLastChunk"] = true,
                    ["chunkingEnabled"] = true,
                    ["totalSizeBytes"] = 0,
                    ["errorSuppressed"] = true,
                    ["originalErrorCode"] = ((int)statusCode).ToString() // Include original error code in metadata

                }
            };

            var response = new HttpResponseMessage(HttpStatusCode.OK);
            response.Content = CreateJsonContent(emptyResponse.ToString(Newtonsoft.Json.Formatting.None));

            // Add custom headers indicating empty response
            response.Headers.Add("X-Item-Chunk-Index", "0");
            response.Headers.Add("X-Item-Total-Chunks", "1");
            response.Headers.Add("X-Item-Is-Last-Chunk", "true");
            response.Headers.Add("X-Item-Chunk-Size", DEFAULT_CHUNK_SIZE_BYTES.ToString());
            response.Headers.Add("X-Item-Total-Size", "0");
            response.Headers.Add("X-Item-Empty-Response", "true");
            response.Headers.Add("X-Item-Error-Suppressed", "true");
            response.Headers.Add("X-Item-Original-Error-Code", ((int)statusCode).ToString()); // Log original error

            return response;
        }

        
        private async Task<HttpResponseMessage> FetchFullExternalItemForChunking(NameValueCollection originalQueryParams)
        {
            // Extract path from original request
            var pathParams = this.Context.Request.RequestUri.AbsolutePath;

            if (pathParams.EndsWith("/chunked", StringComparison.OrdinalIgnoreCase))
            {
                pathParams = pathParams.Substring(0, pathParams.Length - "/chunked".Length);
            }
            
            // Remove chunk-related query parameters but keep others
            var cleanQuery = new NameValueCollection();
            
            foreach (string key in originalQueryParams.AllKeys)
            {
                if (key != CHUNK_QUERY_PARAM && 
                    key != CHUNK_SIZE_PARAM && 
                    key != USE_CHUNKING_PARAM)
                {
                    cleanQuery[key] = originalQueryParams[key];
                }
            }
            
            // Rebuild query string
            string queryString = "";
            if (cleanQuery.Count > 0)
            {
                queryString = "?" + string.Join("&", 
                    cleanQuery.AllKeys.Select(key => $"{key}={Uri.EscapeDataString(cleanQuery[key])}"));
            }
            
            // Forward request to Graph API
            var outbound = new HttpRequestMessage(
                HttpMethod.Get, 
                $"https://graph.microsoft.com{pathParams}{queryString}");
            
            // Forward authorization header
            if (this.Context.Request.Headers.TryGetValues("Authorization", out var authHeaders))
            {
                outbound.Headers.TryAddWithoutValidation("Authorization", authHeaders);
            }
            
            // Add accept header
            outbound.Headers.Add("Accept", "application/json");
            
            // Forward the request
            return await this.Context.SendAsync(outbound, this.CancellationToken)
                                .ConfigureAwait(false);
        }
        
        private HttpResponseMessage ApplyChunkingToResponse(JObject fullItem, int chunkIndex, int chunkSize)
        {
            try {
                // Create chunked response structure
                var chunkedItem = new JObject
                {
                    ["id"] = fullItem["id"],
                    ["@odata.context"] = fullItem["@odata.context"],
                    ["chunkMetadata"] = new JObject
                    {
                        ["chunkIndex"] = chunkIndex,
                        ["chunkSize"] = chunkSize,
                        ["totalChunks"] = 0, // Will calculate below
                        ["isLastChunk"] = false,
                        ["chunkingEnabled"] = true
                    }
                };
            
                // Copy all properties except content (we'll handle content separately)
                foreach (var property in fullItem.Properties())
                {
                    if (property.Name != "content" && 
                        property.Name != "@odata.context" && 
                        property.Name != "id")
                    {
                        chunkedItem[property.Name] = property.Value;
                    }
                }
            
                // Handle content chunking
                if (fullItem["content"] != null)
                {
                    var content = fullItem["content"];
                    var contentValue = content["value"]?.ToString();
                
                    if (!string.IsNullOrEmpty(contentValue))
                    {
                        // Calculate chunk boundaries
                        int totalBytes = Encoding.UTF8.GetByteCount(contentValue);
                        int totalChunks = (int)Math.Ceiling((double)totalBytes / chunkSize);
                    
                        // Update chunk metadata
                        chunkedItem["chunkMetadata"]["totalChunks"] = totalChunks;
                        chunkedItem["chunkMetadata"]["totalSizeBytes"] = totalBytes;
                        chunkedItem["chunkMetadata"]["originalContentLength"] = contentValue.Length;
                    
                        if (chunkIndex >= totalChunks)
                        {

                            // Requested chunk beyond available chunks - return empty content
                            chunkedItem["content"] = new JObject
                            {
                                ["type"] = content["type"],
                                ["value"] = "",
                                ["isPartial"] = false,
                                ["chunkInfo"] = new JObject
                                {
                                    ["startByte"] = 0,
                                    ["endByte"] = -1,
                                    ["chunkIndex"] = chunkIndex,
                                    ["totalChunks"] = totalChunks,
                                    ["charsInChunk"] = 0
                                }
                            };

                            chunkedItem["chunkMetadata"]["isLastChunk"] = true;

                        }
                    
                        // Check if this is the last chunk
                        bool isLastChunk = (chunkIndex >= totalChunks - 1);
                        chunkedItem["chunkMetadata"]["isLastChunk"] = isLastChunk;
                    
                        // Extract the appropriate chunk
                        string chunkedContent = GetContentChunk(contentValue, chunkIndex, chunkSize, totalBytes);
                    
                        // Create chunked content object
                        var chunkedContentObj = new JObject
                        {
                            ["type"] = content["type"],
                            ["value"] = chunkedContent,
                            ["isPartial"] = totalChunks > 1,
                            ["chunkInfo"] = new JObject
                            {
                                ["startByte"] = chunkIndex * chunkSize,
                                ["endByte"] = Math.Min((chunkIndex + 1) * chunkSize, totalBytes) - 1,
                                ["chunkIndex"] = chunkIndex,
                                ["totalChunks"] = totalChunks,
                                ["charsInChunk"] = chunkedContent.Length
                            }
                        };
                    
                        chunkedItem["content"] = chunkedContentObj;
                    }
                    else
                    {
                        // Content exists but value is empty or null
                        chunkedItem["content"] = content;
                        chunkedItem["chunkMetadata"]["totalChunks"] = 1;
                        chunkedItem["chunkMetadata"]["isLastChunk"] = true;
                        chunkedItem["chunkMetadata"]["totalSizeBytes"] = 0;
                    }
                }
                else
                {
                    // No content property
                    chunkedItem["content"] = new JObject
                    {
                        ["type"] = "text",
                        ["value"] = ""
                    };
                    chunkedItem["chunkMetadata"]["totalChunks"] = 1;
                    chunkedItem["chunkMetadata"]["isLastChunk"] = true;
                    chunkedItem["chunkMetadata"]["totalSizeBytes"] = 0;
                }
            
                // Return successful response
                var response = new HttpResponseMessage(HttpStatusCode.OK);
                response.Content = CreateJsonContent(chunkedItem.ToString(Newtonsoft.Json.Formatting.None));
            
                // Add custom headers for chunking information
                response.Headers.Add("X-Item-Chunk-Index", chunkIndex.ToString());
                response.Headers.Add("X-Item-Total-Chunks", chunkedItem["chunkMetadata"]["totalChunks"].ToString());
                response.Headers.Add("X-Item-Is-Last-Chunk", chunkedItem["chunkMetadata"]["isLastChunk"].ToString());
                response.Headers.Add("X-Item-Chunk-Size", chunkSize.ToString());
                response.Headers.Add("X-Item-Total-Size", chunkedItem["chunkMetadata"]["totalSizeBytes"].ToString());
            
                return response;
            } 
            catch (Exception)
            {   
                // If anything goes wrong during chunking, return empty response
                return CreateEmptyContentResponse(HttpStatusCode.InternalServerError);
            }  
        }

        private int AdjustForUtf8Boundary(byte[] bytes, int start, int end)
        {
            // Bounds check FIRST
            if (end >= bytes.Length)
            {
                return bytes.Length; // Return the actual length, not an index
            }
    
            int adjustedEnd = end;
    
            // Now we can safely check bytes[adjustedEnd]
            while (adjustedEnd > start && (bytes[adjustedEnd] & 0xC0) == 0x80)
            {
                adjustedEnd--;
            }
    
            return adjustedEnd;
        }

        private string GetContentChunk(string fullContent, int chunkIndex, int chunkSizeBytes, int totalBytes)
        {
            // Convert string to bytes for accurate byte-based chunking
            byte[] contentBytes = Encoding.UTF8.GetBytes(fullContent);
    
            int startByte = chunkIndex * chunkSizeBytes;
    
            if (startByte >= totalBytes || startByte >= contentBytes.Length)
            {
                return string.Empty;
            }
    
            // endByte should be EXCLUSIVE, not inclusive
            int endByte = Math.Min(startByte + chunkSizeBytes, totalBytes);
    
            // Adjust for UTF-8 boundaries - but make sure we don't go out of bounds
            if (endByte < contentBytes.Length)
            {
                endByte = AdjustForUtf8Boundary(contentBytes, startByte, endByte);
            }
            else
            {
                endByte = contentBytes.Length; // Use the actual length
            }
    
            // Final bounds check
            if (endByte <= startByte || startByte >= contentBytes.Length)
            {
                return string.Empty;
            }
    
            int chunkLength = endByte - startByte;
            byte[] chunkBytes = new byte[chunkLength];
            Array.Copy(contentBytes, startByte, chunkBytes, 0, chunkLength);
    
            return Encoding.UTF8.GetString(chunkBytes);
        }

        private int GetUtf8SequenceLength(byte firstByte)
        {
            if ((firstByte & 0x80) == 0) return 1; // 0xxxxxxx
            if ((firstByte & 0xE0) == 0xC0) return 2; // 110xxxxx
            if ((firstByte & 0xF0) == 0xE0) return 3; // 1110xxxx
            if ((firstByte & 0xF8) == 0xF0) return 4; // 11110xxx
            return -1; // Invalid UTF-8
        }
        
        private HttpResponseMessage CreateErrorResponse(string code, string message, HttpStatusCode statusCode)
        {
            var errorResponse = new HttpResponseMessage(statusCode);
            errorResponse.Content = CreateJsonContent(new JObject
            {
                ["error"] = new JObject
                {
                    ["code"] = code,
                    ["message"] = message
                }
            }.ToString());
            return errorResponse;
        }
        
        private async Task<HttpResponseMessage> HandleSearchWrapper()
        {
            // Read original request body
            string rawBody = await this.Context.Request.Content.ReadAsStringAsync().ConfigureAwait(false);
            var input = JObject.Parse(rawBody);
            
            // Extract fields
            int size = Math.Min((int?)input["size"] ?? 50, 50);
            int from = (int?)input["offset"] ?? 0;

            string queryString = (string)input["query"];
            if (queryString == null)
            {
                queryString = "nexus, this is a null string";
            }

            string contentSourceParam = (string)input["contentSource"] ?? "/external/connections/nexus";

            // Build contentSources array from comma-separated string
            JArray contentSourcesArray = new JArray();
        
            if (!string.IsNullOrEmpty(contentSourceParam))
            {
                // Split by comma and trim each entry
                var contentSources = contentSourceParam.Split(',')
                    .Select(source => source.Trim())
                    .Where(source => !string.IsNullOrEmpty(source));
            
                foreach (var source in contentSources)
                {
                    contentSourcesArray.Add(source);
                }
            }
            // If no valid content sources were found, use default
            if (contentSourcesArray.Count == 0)
            {
                contentSourcesArray.Add("/external/connections/nexus");
            }

            // Build wrapped search request
            JObject wrappedBody = new JObject
            {
                ["requests"] = new JArray
                {
                    new JObject
                    {
                        ["entityTypes"] = new JArray("externalItem"),
                        ["contentSources"] = contentSourcesArray,
                        ["query"] = new JObject
                        {
                            ["queryString"] = queryString,
                            ["semanticSearch"] = new JObject
                            {
                                ["semanticEnabled"] = true,
                                ["captions"] = new JObject { ["enabled"] = true, ["highlightEnabled"] = true },
                                ["answers"] = new JObject { ["enable"] = true, ["top"] = 1 }
                            },
                        },
                        ["from"] = from,
                        ["size"] = size,
                        ["fields"] = new JArray
                            (
                                "id", "title", "hitsSnippet", "subject", "authors", 
                                "filename", "owner", "url", "modifiedTime", "modifiedBy", 
                                "tags", "categories", "content", "fileId", "size", 
                                "aclOwner", "fileExtension", "comments", "hidden", 
                                "readOnly", "systemFile", "archiveFile", "aclOwner", 
                                "aclPrimaryGroup", "aclReadAllowedTo", "aclFullControlTo", 
                                "aclWriteAllowedTo", "aclModifyAllowedTo", 
                                "aclReadAndExecuteAllowedTo", "aclSpecialPermsTo",
                                "aclReadDeniedTo", "aclFullControlDeniedTo", 
                                "aclWriteDeniedTo", "aclModifyDeniedTo", 
                                "aclReadAndExecuteDeniedTo", "aclSpecialPermsDeniedTo"                        )
                    }
                }
            };

            string filter = (string)input["filter"] ?? null;
            if (!string.IsNullOrEmpty(filter))
            {
                filter = "({searchTerms}) " + filter;
                wrappedBody["requests"][0]["query"]["queryTemplate"] = filter;
            }

            string[]? fields = null;

            if (input.TryGetValue("fields", out var token) && token is JArray arr)
            {
                fields = arr.Values<string>().ToArray();
            }
            if (fields != null) 
            {
                var fieldsArray = (JArray)wrappedBody["requests"][0]["fields"];
                foreach (var field in fields)
                {
                    fieldsArray.Add(field);
                }
            }

            /*
            //Debugging: Enable this to send constructued search/query request body back to caller
            var response = new HttpResponseMessage(HttpStatusCode.OK);
            response.Content = CreateJsonContent(wrappedBody.ToString());
            return response;
            */
        
            // Build outbound request
            var outbound = new HttpRequestMessage(HttpMethod.Post, "https://graph.microsoft.com/v1.0/search/query");
            outbound.Content = CreateJsonContent(wrappedBody.ToString());

            if (this.Context.Request.Headers.TryGetValues("Authorization", out var authHeaders))
            {
                outbound.Headers.TryAddWithoutValidation("Authorization", authHeaders);
            }

            // Forward the request
            return await this.Context.SendAsync(outbound, this.CancellationToken)
                                .ConfigureAwait(false);
        }
    }


