# Key concepts - Publish and deploy your agent - Microsoft Copilot Studio
Source: https://learn.microsoft.com/en-us/microsoft-copilot-studio/publish-copilot-flow
Fetched: 2026-05-05

> **Note:** The originally requested URL returned HTTP 404. This file contains content from the canonical Copilot Studio publishing page. Canonical URL: https://learn.microsoft.com/en-us/microsoft-copilot-studio/publication-fundamentals-publish-channels

---

By using Copilot Studio, you can publish agents that engage with your customers on multiple platforms or channels. For example, live websites, mobile apps, Microsoft 365 Copilot, and messaging platforms like Teams and Facebook.

Each time you update your agent, you can publish it again from within Copilot Studio. Publishing your agent applies to all the channels associated with your agent.

You need to publish your agent before your customers can engage with it. You can publish your agent on multiple platforms, or *channels*.

After you publish an agent to at least one channel, you can connect it to more channels. Remember to publish your agent again after you make any changes to it.

When you publish an agent, this agent updates on all connected channels. If you make changes to your agent but don't publish after doing so, your customers won't be engaging with the latest content.

Agents have the **Authenticate with Microsoft** option turned on by default. With this option, agents automatically use Microsoft Entra ID authentication for Teams, Power Apps, and Microsoft 365 Copilot without requiring any manual setup.

If you want to allow anyone to chat with an agent, select **No authentication**.

> **Caution:** Selecting the **No authentication** option allows anyone who has the link to chat and interact with your bot or agent. We recommend you apply authentication, especially if you are using your bot or agent within your organization or for specific users, along with [other security and governance controls](security-and-governance).

> **Important:** If you select **No authentication**, your agent can't use [tools](add-tools-custom-agent) with [user credentials](configuration-end-user-authentication).

## Publish the latest content

1. With your agent open for editing, select **Publish**.
2. Select **Publish**, and then confirm. Publishing can take a few minutes.

> **Tip:** To prevent disrupting users who are having an existing conversation with the agent, the latest published content only becomes available after a new session starts. In most channels, a session ends after 30 minutes of inactivity.
>
> In channels that have persistent conversations, such as Microsoft Teams and Omnichannel for Customer Service, you might want to try out the latest published content right away. To do so, enter `start over` in the current session. This command resets the conversation and starts a new session with the latest content you published. Otherwise, it might take one hour after you publish an update for the agent for its latest version to take effect.

## Test your agent

Test your agent after you publish it. You can [make the agent available to users in Teams and Microsoft 365 Copilot](publication-add-bot-to-microsoft-teams) by using the installation link or from various places in the Microsoft Teams app store.

Start by publishing your agent only for yourself, and test the published version before releasing it to a wider audience. You can install the agent for your own use in Microsoft Teams by selecting **Open the agent in Teams**. You can share your agent later, with members of your team or other stakeholders, by selecting **Make the agent available to others** on the **Publish** page.

> **Important:** Avoid making your agent widely available in Teams or Microsoft 365 Copilot before it's fully configured and tested, and you verified that it's available from the applicable agent stores (if any).

If you selected **No authentication** or **Authenticate manually**, select the **Demo website** link to open a prebuilt website in a new browser tab, where you and your teammates can interact with the agent. The demo website is also useful to gather feedback from stakeholders before you roll your agent out to customers.

> **Tip:** **What's the difference between the test chat and the demo website?**
>
> - Use the test chat (the **Test agent** panel) while you're building your agent to make sure conversation flows as you expect and to spot errors.
> - Only share the demo website URL with members of your team and other stakeholders to try out the agent. The demo website isn't intended for production use. You shouldn't share this URL with customers.

## Configure channels

After you publish your agent at least once, add channels so your customers can reach it.

To configure channels for your agent:

1. On the top menu bar, select **Channels**.
2. Select the channel you want from the list of available channels.

Each channel has different connection steps. Learn more:

- [Teams and Microsoft 365 Copilot](publication-add-bot-to-microsoft-teams)
- [SharePoint](publication-add-bot-to-sharepoint)
- [WhatsApp](publication-add-bot-to-whatsapp)
- [Demo Website](publication-connect-bot-to-web-channels)
- [Custom Website](publication-connect-bot-to-web-channels#add-your-agent-to-your-website)
- [Mobile App](publication-connect-bot-to-custom-application)
- [Facebook](publication-add-bot-to-facebook)
- [Azure Bot Service channels](publication-connect-bot-to-azure-bot-service-channels), including:
    - Cortana
    - Slack
    - Telegram
    - Twilio
    - Line
    - Kik
    - GroupMe
    - Direct Line Speech
    - Email

## Channel experience reference table

Different channels offer different user experiences. The following table shows a high-level overview of the experiences for each channel.

| Experience | Website | Teams and Microsoft 365 Copilot | Facebook | Omnichannel for Customer Service |
| --- | --- | --- | --- | --- |
| Customer satisfaction survey | Adaptive card | Text-only | Text-only | Text-only |
| Multiple-choice options | Supported | Supported up to six (as hero card) | Supported up to 13 | Partially Supported |
| Markdown | Supported | Partially Supported | Partially supported | Partially Supported |
| Welcome message | Supported | Supported | Not supported | Supported for Chat. Not supported for other channels. |
| Did-You-Mean | Supported | Supported | Supported | Supported for Microsoft Teams, Chat, Facebook, and text-only channels. |

## Troubleshoot publishing errors

If you run into problems when publishing your agent, use the following troubleshooting steps to resolve common publishing errors:

1. **Verify all configurations are correct.** Make sure that the agent settings, authentication options, and channel configurations are set up properly before publishing.
2. **Check for any missing dependencies.** Ensure that all required components, such as topics, flows, connectors, and data sources, are available and properly configured.
3. **Review error logs for specific error codes and messages.** Go to the **Publish** page and check the publish status for any error details.

## Known limitations

- The customer satisfaction survey in Microsoft Teams is a text-only version instead of an adaptive card.
- Microsoft Teams can render up to six suggested actions in one question node.
- A user can't send or upload attachments to the chat. If they try to send an attachment, the agent replies: *Looks like you tried to send an attachment. Currently, I can only process text. Please try sending your message again without the attachment.*
    - This limitation applies to all channels, even if the channel or user-facing experience supports attachments.
    - Attachments can be supported if the message is sent to a skill, where the skill bot supports the processing of attachments.
