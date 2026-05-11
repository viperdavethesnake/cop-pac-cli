# Set Up Microsoft 365 Copilot and Assign Licenses
Source: https://learn.microsoft.com/en-us/microsoft-365/admin/misc/microsoft-365-copilot-setup
Fetched: 2026-05-05

> **Note:** The originally requested URL returned HTTP 404. This file contains content from the canonical Microsoft 365 Copilot setup page. Canonical URL: https://learn.microsoft.com/en-us/microsoft-365/copilot/microsoft-365-copilot-setup

---

As part of your [Microsoft 365 Copilot adoption](microsoft-365-copilot-enablement-resources), the next step is to enable security features, configure the update channel, and assign Copilot licenses to users. This article provides guidance for IT administrators on how to prepare your organization for Microsoft 365 Copilot. It covers foundational implementation and readiness activities, licensing, and steps to ensure a secure and compliant deployment.

## Prerequisites

### Admin center roles

This article uses the following admin centers. These admin centers require a specific role to complete the tasks in the article.

- [**Microsoft 365 admin center**](https://admin.microsoft.com): Different roles are available depending on the task you need to complete. For more information about roles, see [Commonly used Microsoft 365 admin center roles](/en-us/microsoft-365/admin/add-users/about-admin-roles#commonly-used-microsoft-365-admin-center-roles).
- [**SharePoint admin center**](https://go.microsoft.com/fwlink/?linkid=2185219): Sign in as the [SharePoint administrator](/en-us/sharepoint/sharepoint-admin-role).
- [**Microsoft Purview portal**](https://purview.microsoft.com): Different roles are available depending on the task you need to complete. For more information, see [Permissions in the Microsoft Purview portal](/en-us/purview/purview-permissions).

### Licensing

To purchase Microsoft 365 Copilot, make sure you have an appropriate subscription plan. Microsoft 365 Copilot licenses are available as an add-on to other licensing plans. For more information, see [Microsoft 365 Copilot license options](microsoft-365-copilot-licensing).

You can purchase Microsoft 365 Copilot licenses through the [Microsoft 365 admin center marketplace](https://admin.microsoft.com/adminportal/home#/catalog), Microsoft partners, or your Microsoft account team.

## Readiness activities

To ensure a smooth transition to Microsoft 365 Copilot, use the following readiness checklist:

- **Set up a test environment**: To validate configurations and test scenarios, establish a test environment with necessary licenses.
- **Conduct pilot testing**: To identify any issues and gather feedback, do pilot testing with a select group of users.
- **Develop a communication plan**: Create a communication plan to inform users about the upcoming changes and provide them with the necessary resources and support.
- **Review conditional access policies**: Make sure that you appropriately configure conditional access policies. Microsoft 365 Copilot supports tenant-level conditional access policies in SharePoint.
- **Review SharePoint Search and Advanced Management Policies**: Use SharePoint Advanced Management to control access to content, prevent oversharing, and manage content lifecycle. For more information, see [Get ready for Microsoft 365 Copilot with SharePoint Advanced Management](/en-us/sharepoint/get-ready-copilot-sharepoint-advanced-management).
- **Ensure network compliance**: Make sure that your network meets the requirements for Microsoft 365 Copilot services.

## Security measures

To ensure a secure and compliant environment for Microsoft 365 Copilot, it's crucial to implement robust security measures.

### Multifactor authentication (MFA)

Multifactor authentication is a critical security measure that requires users to provide two or more verification factors to access a resource. When you implement MFA, it helps protect against unauthorized access and enhances the security of your organization's data.

Steps to implement MFA:

- **Enable MFA for all users**: Use the Microsoft 365 admin center to enable MFA for all users in your organization.
- **Configure conditional access policies**: Set up conditional access policies to enforce MFA based on user risk, location, and device compliance.
- **Educate users**: Provide training and resources to help users understand the importance of MFA and how to use it effectively.

### Audit logging

Audit logging is essential for tracking and monitoring activities within your Microsoft 365 environment.

Steps to implement audit logging:

- **Enable unified audit logging**: To capture all user and admin activities, turn on unified audit logging in the Microsoft Purview portal.
- **Configure audit log retention**: Set up retention policies to ensure that audit logs are retained for the required period.
- **Monitor and review logs**: Regularly monitor and review audit logs to identify any suspicious activities or potential security threats.

### Restrict sensitive info from Copilot

To protect sensitive information during the deployment and use of Microsoft 365 Copilot:

- **Identify most popular sites and assess oversharing**: Export the top 100 most used sites from the SharePoint admin center and run the SharePoint Advanced Management permission state report.
- **Grant Copilot access to popular, low-risk sites**: Cross-reference the report results with the top 100 used sites.
- **Turn on proactive audit and protection**: Disable **everyone except external users (EEEU)** at the tenant level and enable Purview Audit to monitor Copilot interaction activity.
- **Implement access controls and labeling**: Start a SharePoint Advanced Management Access Review for all sites that are overshared. Then apply restricted access control on business-critical sites.

## Get started and deploy

### Step 1: Update channels

**Use the Current Channel or Monthly Enterprise Channel to update apps**

Microsoft 365 Copilot follows the Microsoft 365 Apps standard practice for deployment and updates. It's available in all update channels, *except* for Semi-Annual Enterprise Channel.

Your options:

- **Production channels:**
    - **Current Channel** provides your users with the newest Microsoft 365 app features as soon as they're ready. It provides the best experience for a fast-moving product, like Copilot.
    - **Monthly Enterprise Channel** is more predictable for when Microsoft releases new Microsoft 365 app features each month. A good option for organizations that want to validate features before release to Current Channel.
- **Preview channels** include **Current Channel (Preview)** and **Beta Channel**. Great for validating the product before rolling out to the rest of the organization.

### Step 2: Provision Microsoft 365 Copilot licenses

**Assign Copilot licenses by using the Microsoft 365 admin center**

Before you assign Copilot licenses, make sure that you provision users and assign Microsoft 365 licenses to users in your tenant. Your options:

- Use the [Microsoft 365 Copilot setup guide in the Microsoft 365 admin center](https://admin.microsoft.com/Adminportal/Home?Q=learndocs#/modernonboarding/microsoft365copilotsetupguide)
- Use the Microsoft 365 admin center features to [Add users and assign licenses](/en-us/microsoft-365/admin/add-users/add-users).
- [Use PowerShell to assign Microsoft 365 licenses](/en-us/microsoft-365/enterprise/assign-licenses-to-user-accounts-with-microsoft-365-powershell).

To assign Copilot licenses:

1. Sign in to the [Microsoft 365 admin center](https://admin.microsoft.com) and go to **Billing** > **Licenses**.
2. Select **Microsoft 365 Copilot**.
3. In the product details page, assign licenses to users and manage their access to Copilot and other apps and services.
4. To check if a user is added, go to **Users** > **Active Users**.

When you assign licenses, Copilot shows up in Microsoft 365 apps, like Word and Excel. For some apps, users might need to wait up to 24 hours for Copilot to appear. They might also need to restart or refresh the app.

> **Note:**
> - It's not supported to assign Copilot licenses to cross-tenant users, including guests.
> - For education customers, the Copilot license is listed under **Microsoft 365 A3 Extra Features for faculty** or **Microsoft 365 A5 Extra Features for faculty**.

### Step 3: Configure settings for Copilot

**Configure more Copilot features**

You can manage settings by using the Copilot Control System. It provides centralized access to admin features and controls.

To access these settings, go to the [Microsoft 365 admin center](https://admin.microsoft.com) > **Copilot**.

With the Copilot Control System, you can:

- View the status of Copilot license assignments.
- Access the latest information on Copilot.
- Manage data security and compliance controls.
- Submit feedback on behalf of users.
- Configure plugins and permissions.
- Enable the use of web data as grounding data in Copilot.

### Step 4: Deploy to some users and measure adoption

When you're ready to assign Copilot licenses to your users, follow these three phases:

1. **Pilot**: To test the deployment and gather feedback, assign licenses to a small group of users.
2. **Deploy**: Assign licenses to a larger group of users.
3. **Operate**: Monitor usage and adoption, and make adjustments as needed.

#### Pilot

**Create a group of early adopters**

To help drive adoption, create a group of early adopters:

1. Identify users across various business groups in your organization, ideally with high usage of existing Microsoft 365 features.
2. Assign these users Microsoft 365 Copilot licenses and onboard them to Copilot.
3. As these users get more comfortable with using Copilot, they can speak to how they use it best, and where it's most valuable for them.

For more information about driving adoption, visit the [Microsoft 365 Copilot adoption hub](https://adoption.microsoft.com/Copilot/).

#### Deploy

**Fully deploy Copilot licenses to all users in your organization**

1. Use the Microsoft 365 admin center to assign licenses to individual users or groups of users.
2. Before users begin using Copilot, make sure that you assign the appropriate licenses to them.

During this phase, also include the following activities:

- Focus on preventing oversharing by limiting external sharing, restricting access to certain files or folders, and setting up alerts.
- Use sensitivity labels to classify and protect sensitive information.

#### Operate

**Get insights and user sentiment**

To measure the impact of Copilot on your organization, use the [Copilot Dashboard from Viva Insights](/en-us/viva/insights/org-team-insights/copilot-dashboard), and the [Microsoft 365 usage reports in the admin center](/en-us/microsoft-365/admin/activity-reports/activity-reports).

For more information, see:

- [Copilot Control System measurement and reporting](copilot-control-system/measurement-reporting)
- [Open the Microsoft Copilot Dashboard from Viva Insights](https://aka.ms/copilotdashboard)
- [Microsoft 365 reports in the admin center - Microsoft 365 Copilot usage](/en-us/microsoft-365/admin//activity-reports/microsoft-365-copilot-usage)
- [Microsoft 365 reports in the admin center - Microsoft 365 Copilot readiness](/en-us/microsoft-365/admin//activity-reports/microsoft-365-copilot-readiness)
