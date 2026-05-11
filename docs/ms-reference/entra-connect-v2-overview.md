# What is Microsoft Entra Connect and Connect Health
Source: https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/whatis-azure-ad-connect
Fetched: 2026-05-05

---

# What is Microsoft Entra Connect and Connect Health?

Microsoft Entra Connect is an on-premises Microsoft application designed to meet and accomplish your hybrid identity goals. If you're evaluating how to best meet your goals, you should also consider the cloud-managed solution [Microsoft Entra Cloud Sync](https://learn.microsoft.com/en-us/azure/active-directory/cloud-sync/what-is-cloud-sync).

> **Important:** Azure AD Connect V1 has been retired as of August 31, 2022 and is no longer supported. Azure AD Connect V1 installations may **stop working unexpectedly**. If you are still using an Azure AD Connect V1 you need to upgrade to Microsoft Entra Connect V2 immediately.

## Consider moving to Microsoft Entra Cloud Sync

Microsoft Entra Cloud Sync is the future of synchronization for Microsoft. It replaces Microsoft Entra Connect.

Before moving to Microsoft Entra Connect V2.0, you should consider moving to cloud sync. You can see if cloud sync is right for you by accessing the [Check sync tool](https://aka.ms/M365Wizard) from the portal or via the link provided.

For more information, see [What is cloud sync?](https://learn.microsoft.com/en-us/azure/active-directory/cloud-sync/what-is-cloud-sync)

## Microsoft Entra Connect features

- **[Password hash synchronization](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/whatis-phs)** - A sign-in method that synchronizes a hash of a user's on-premises AD password with Microsoft Entra ID.
- **[Pass-through authentication](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-pta)** - A sign-in method that allows users to use the same password on-premises and in the cloud, but doesn't require the additional infrastructure of a federated environment.
- **[Federation integration](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-fed-whatis)** - Federation is an optional part of Microsoft Entra Connect and can be used to configure a hybrid environment using an on-premises AD FS infrastructure. It also provides AD FS management capabilities such as certificate renewal and additional AD FS server deployments.
- **[Synchronization](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-sync-whatis)** - Responsible for creating users, groups, and other objects. And, making sure identity information for your on-premises users and groups is matching the cloud. This synchronization also includes password hashes.
- **[Health Monitoring](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/whatis-azure-ad-connect#what-is-azure-ad-connect-health)** - Microsoft Entra Connect Health can provide robust monitoring and provide a central location in the Microsoft Entra admin center to view this activity.

> **Important:** Microsoft Entra Connect Health for Sync requires Microsoft Entra Connect Sync V2. If you are still using Azure AD Connect V1 you must upgrade to the latest version. Azure AD Connect V1 is retired on August 31, 2022. Microsoft Entra Connect Health for Sync will no longer work with Azure AD Connect V1 in December 2022.

## What is Microsoft Entra Connect Health?

Microsoft Entra Connect Health provides robust monitoring of your on-premises identity infrastructure. It enables you to maintain a reliable connection to Microsoft 365 and Microsoft Online Services. This reliability is achieved by providing monitoring capabilities for your key identity components. Also, it makes the key data points about these components easily accessible.

The information is presented in the [Microsoft Entra Connect Health portal](https://aka.ms/aadconnecthealth). Use the Microsoft Entra Connect Health portal to view alerts, performance monitoring, usage analytics, and other information. Microsoft Entra Connect Health enables the single lens of health for your key identity components in one place.

## Why use Microsoft Entra Connect?

Integrating your on-premises directories with Microsoft Entra ID makes your users more productive by providing a common identity for accessing both cloud and on-premises resources. Users and organizations can take advantage of:

- Users can use a single identity to access on-premises applications and cloud services such as Microsoft 365.
- Single tool to provide an easy deployment experience for synchronization and sign-in.
- Provides the newest capabilities for your scenarios. Microsoft Entra Connect replaces older versions of identity integration tools such as DirSync and Azure AD Sync.

## Why use Microsoft Entra Connect Health?

When authenticating with Microsoft Entra ID, your users are more productive because there's a common identity to access both cloud and on-premises resources. Ensuring the environment is reliable, so that users can access these resources, becomes a challenge. Microsoft Entra Connect Health helps monitor and gain insights into your on-premises identity infrastructure thus ensuring the reliability of this environment. It's as simple as installing an agent on each of your on-premises identity servers.

Microsoft Entra Connect Health for AD FS supports AD FS on Windows Server 2012 R2, Windows Server 2016, Windows Server 2019, Windows Server 2022, and Windows Server 2025. It also supports monitoring the web application proxy servers that provide authentication support for extranet access.

Key benefits and best practices:

| Key Benefits | Best Practices |
| --- | --- |
| Enhanced security | Extranet lockout trends, Failed sign-ins report, Privacy compliant |
| Get alerted on all critical ADFS system issues | Server configuration and availability, Performance and connectivity, Regular maintenance |
| Easy to deploy and manage | Quick agent installation, Agent auto upgrade to the latest, Data available in portal within minutes |
| Rich usage metrics | Top applications usage, Network locations and TCP connections, Token requests per server |
| Great user experience | Dashboard fashion from Microsoft Entra admin center, Alerts through emails |

## License requirements for using Microsoft Entra Connect

Using this feature is free and included in your Azure subscription.

## License requirements for using Microsoft Entra Connect Health

Using this feature requires Microsoft Entra ID P1 licenses. To find the right license for your requirements, see [Compare generally available features of Microsoft Entra ID](https://www.microsoft.com/security/business/identity-access-management/azure-ad-pricing).
