# Manage application users in the Power Platform admin center
Source: https://learn.microsoft.com/en-us/power-platform/admin/manage-application-users
Fetched: 2026-05-05

---

We're in the process of moving application user management from the legacy web client. Follow these steps to manage application users in the Power Platform admin center.

> **Note:** Deleting an inactive, application user is now supported.

> **Tip:** Check out the video: [Administer application users, security roles, teams, and users in the Power Platform admin center](https://learn-video.azurefd.net/vod/player?id=5799c67e-f283-4cbd-aafa-bc38a3f53276).

## View application users in an environment

On the **Application users** page, you can view and manage application users. The **Custom** app type is your local app registration, as created in Microsoft Entra ID.

1. Sign in to the [Power Platform admin center](https://admin.powerplatform.microsoft.com/).
2. Select **Manage** in the navigation pane.
3. In the **Manage** pane, select **Environments**. Then select an environment.
4. Select **Settings**.
5. Select **Users + permissions**, and then select **Application users**.

## Create an application user

You can create an unlicensed application user in your environment. This application user is given access to your environment's data on behalf of the user who's using your application.

In an environment, you can only have one application user for each Microsoft Entra–registered application.

1. Sign in to the [Power Platform admin center](https://admin.powerplatform.microsoft.com/).
2. Select **Manage** in the navigation pane.
3. In the **Manage** pane, select **Environments**. Then select an environment.
4. Select **Settings**.
5. Select **Users + permissions**, and then select **Application users**.
6. Select **+ New app user** to open the **Create a new app user** pane.
7. Select **+ Add an app** to choose the registered Microsoft Entra application that was created for the selected user, and then select **Add**.

    > **Note:** In addition to entering the Application Name or Application ID, you can also enter an Azure Managed Identity Application ID. For Managed Identity, do not enter the Managed Identity Application Name, use the Managed Identity Application ID instead.
    >
    > Enterprise applications don't show in the list of applications, only Microsoft Entra app registrations show in the list. Search for the multitenant application by name or ID to assign it to the application user.

8. The selected Microsoft Entra app is displayed under **App**. You can select **Edit** to choose another Microsoft Entra application.
9. Under **Business Unit**, select a business unit from the dropdown list.
10. After choosing a business unit, enter an **Email address**.
11. Select the edit icon to select security roles for the new application user. After adding security roles, select **Save**.
12. A window appears asking you to confirm the role assignment. Select **Save**.
13. Select **Create**.

## View or edit the details of an application user

To view or edit the details of an application user, complete the following steps:

1. Sign in to the [Power Platform admin center](https://admin.powerplatform.microsoft.com/).
2. Select **Manage** in the navigation pane.
3. In the **Manage** pane, select **Environments**. Then select an environment.
4. Select **Settings**.
5. Select **Users + permissions**, and then select **Application users**.
6. Select an application user, and then select **Details**.

The **Details** page shows the following properties for the application user:

- Name
- Microsoft Entra application ID
- State
- Assigned security roles
- App type
- Business unit
- Email address

You can edit only the business unit, email address, and security roles properties.

## Sync the application user name with the Microsoft Entra application name

When an application user is first created, the username is the same as the name of the registered Microsoft Entra application. The two names can get out of sync when the name of the Microsoft Entra application is changed. You can sync the application user name with the Microsoft Entra application name by selecting **Refresh** on the **Details** page.

> **Note:** **Refresh** and the Microsoft Entra app name are only shown when the two names are out of sync.

## Manage roles for an application user

In addition to using the entry point on the **Details** page to manage roles, you can select **Edit security roles** on the menu bar on the **Application users** page. If the application user has roles assigned already, those roles appear as selected on the page.

You can select or deselect roles, and then select **Save**. All selected roles become the current assigned roles for the application user. Any unselected roles aren't assigned.

> **Note:** All your application users can run in any environments that are secured with a [security group](control-user-access) without being a member of the security group.

## Activate or deactivate an application user

To activate or deactivate an application user, complete the following steps:

1. Go to the **Application user** page.
    - To activate an application user, select **Activate** on the menu bar, and then select **Activate** in the confirmation dialog.
    - To deactivate an application user, select **Deactivate** on the menu bar, and then select **Deactivate** in the confirmation dialog.

## Delete an inactive, application user

To delete an inactive application user, complete the following steps:

1. Go to the **Application user** page.
2. Select an inactive application user.
3. Select **Delete** on the command bar.
4. Select **Delete** in the confirmation dialog.

> **Note:** Only application users with the **inactive** state can be deleted. You must reassign all records owned by inactive application users before those user records can be deleted. You can add an application user back into the environment if the application user still exists in your Microsoft Entra **App registrations**.

## View the details of system-provided application users

In each of your environments, there's a set of [system-provided application users](system-application-users#application-users). You can now view these application users from the Power Platform admin center.

1. Sign in to the [Power Platform admin center](https://admin.powerplatform.microsoft.com/).
2. Select **Manage** in the navigation pane.
3. In the **Manage** pane, select **Environments**. Then select an environment.
4. Select **Settings**.
5. Select **Users + permissions**, and then select **Application users**.
6. Select the **Filter** option from the command bar.
7. Select the **Platform** option. A list of the platform, application users in the environment is displayed.
8. Select an application user.
9. Select **Details** from the command bar to view details of the platform, application user.
10. Select **Close** to return to the application user list.
