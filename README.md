<h3 align="center">
  UI Bakery is a low-code platform to build apps and automations you never had time for
</h3>

<h3 align="center">
  <b><a href="https://cloud.uibakery.io/auth/register?utm_source=github">Get Started</a></b>
  •
  <a href="https://docs.uibakery.io?utm_source=github">Docs</a>
  •
  <a href="https://docs.uibakery.io/starter-guide/tutorials?utm_source=github">Tutorials</a>
  •
  <a href="https://app.getbeamer.com/uibakery/en?utm_source=github">What's new</a> 
  •
  <a href="https://roadmap.uibakery.io?utm_source=github">Roadmap</a> 
</h3>

<a href="https://cloud.uibakery.io/auth/register/?utm_source=github"><img src="assets/hero.png" width="100%" alt="UI Bakery - Internal tools and workflow automations"></a>

## Deploying UI Bakery on-premise

#### Deploy UI Bakery locally to manage your data from your private network

We understand that you might have lots of data accessible from your private network, that’s why you can use UI Bakery self-hosted version for your benefit.

On-premise version grants you:

- A quick setup process
- Custom branding
- Custom domain hosting
- OAuth2 SSO
- SAML-based identity providers
- Data is stored securely under your own VPS

:heavy_check_mark: UI Bakery on-premise version license key can be obtained [here](https://uibakery.io/on-premise-ui-bakery)

:warning: If you have already installed UI Bakery on-premise version, follow [this guide](#updating-on-premise-version) to update your version.

## Table of contents

- [Installation](#installation)
  - [Requirements](#requirements)
  - [Installation steps](#installation-steps)
- [Deploying on Azure VM](#deploying-on-azure-virtual-machine)
- [Deploying on AWS EC2 instance](#deploying-on-aws-ec2-instance)
- [Deploying on Google Cloud Compute Engine VM instance](#deploying-on-google-cloud-compute-engine-vm-instance)
- [Manual installation](#manual-installation)
- [Kubernetes](#kubernetes)
- [Azure container instance](#azure-container-instance)
- [Running a standalone database instance](#running-a-standalone-database-instance)
- [Running on a remote instance](#running-on-a-remote-instance)
- [Google oauth setup](#google-oauth-setup)
- [Generic OAuth2 SSO provider](#generic-oauth2-sso-provider)
- [SAML authentication setup](#saml-authentication-setup)
- [SSO roles synchronization](#sso-roles-synchronization)
- [Authentication settings](#other-authentication-setting)
- [Embedding](#embedding)
- [Limitations](#limitations)
- [Google Sheets connection setup](#google-sheets-connection-setup)
- [Emails configuration](#configuring-email-provider)
  - [Sendgrid](#configure-sendgrid)
  - [Email templates](#change-email-templates)
- [Updating on-premise version](#updating-on-premise-version)
- [How to update licence key](#how-to-update-licence-key)
- [UI Bakery in production](#ui-bakery-in-production)

## Installation

This document describes how to deploy ui-bakery on-prem via `install.sh` script.

:warning: The script installs docker and docker-compose, which may upgrade some dependencies under the hood. Please be advised that if you run this script on the OS used as a server for other applications, those applications may break due to that potential dependencies upgrade.

### Requirements

- :warning: OS Linux Ubuntu 18.04 and above.
- Must have full rights to use "sudo".

### Installation steps

1. Run this command preferably from `/home` Linux directory to download, install and launch UI Bakery:

   ```bash
   curl -k -L -o install.sh https://raw.githubusercontent.com/uibakery/self-hosted/main/install.sh && bash ./install.sh
   ```

1. In the process, upon request, enter the previously received license code, hosting URL and port.
1. Once the installation is completed, open the browser using URL and port provided earlier. By default it is [http://localhost:3030/](http://localhost:3030/).

**NOTE**: If Docker of the version less than the required (minimum 20.10.11) is already installed on the server, and/or Docker Compose (minimum 1.29.2), the script will be stopped. You need to update the versions of components manually and run the script again.

## Deploying on Azure Virtual Machine

1. Open [Azure Portal](http://portal.azure.com/) and on the search field at the top type in `Virtual machines` and select this item in the result search window

1. Click on the `+ Create` button in the top left corner and select `Azure Virtual machine` in the menu

1. Select an image of `Ubuntu 18.04` or higher

1. For instance size, select minimum `Standard_F2s_v2 - 2 vCPUs, 4 GiB memory`

1. In the `Administrator account` section in the `Authentication type` menu item select `SSH public key` and it will generate the keys after VM creation

1. In `Inbound port rules` leave `SSH(22)` as by default

1. In the `Networking` tab select existing or create a new Virtual Network and Subnet used by this VM

1. In `NIC network security group` select `Advanced`

1. In `Configure network security group` click `Create new`

1. Click `+ Add an inbound rule`

1. Add {BakeryPort} (use 3030 by default, you will need to select the same port during UI Bakery installation later) in the `Destination port ranges`

1. In `Protocol` Choose `TCP`

1. Click `Add`

1. Check that `SSH (TCP/22)` is configured by default. If not, add it manually using the same algorithm as for {BakeryPort}

1. Click `Ok` to finish creating a Network security group

1. Click `Review + create`

1. Click `Create`

1. After creating and running the virtual machine, connect to it from outside using SSH protocol.

1. Run this command preferably from the `/home` Linux directory to download, install and launch UI Bakery:

   ```bash
   curl -k -L -o install.sh https://raw.githubusercontent.com/uibakery/self-hosted/main/install.sh && bash ./install.sh
   ```

1. Upon request, enter the previously received license code, hosting URL - Azure Virtual Machine IP address, and port ({BakeryPort} which you selected in the earlier steps 3030 by default).

1. After the installation is completed and launched, enter the bakery from a browser on your local machine at http://{Public IP address Azure VM}:{BakeryPort}

## Deploying on AWS EC2 instance

1. Open [AWS Management Console](http://console.aws.amazon.com/) and select Services - EC2 (Virtual Servers in the Cloud)

1. Select `Network & Security` - `Security Groups`. Click `Create security group` button in the top right corner

1. Input `Bakery` in `Security group name` and `Bakery security group` in `Description`

1. In block `Inbound rules` click `Add rule` button. Select `Custom TCP` in the `Type`, input {BakeryPort} (use 3030 by default, you will need to select the same port during UI Bakery installation later) in the `Port range` and select `Anywhere-IPv4` in the `Source`

1. In block `Inbound rules` click `Add rule` button. Select `SSH` in the `Type` and select `Anywhere-IPv4` in the `Source`

1. Click `Create security group`

1. Select `Network & Security` - `Key Pairs`. Click `Create key pairs` button in the top right corner

1. Input `Bakery` in `Name`. Select `RCA` in `Key pair type`. Select `.pem` in `Private key file format`, if you will be connecting to the VM using OpenSSH, or select `.ppk` in `Private key file format`, if you will be connecting to the VM using Putty

1. Save the key file to the disk of the local machine

1. Select `Instances` - `Instance Types`. Select `t2.medium` in the `Instance types` list. Click `Action` - `Launch instance` button in the top right corner

1. Input 'Bakery' in `Name`

1. Select an image of `Ubuntu Server 18.04` or higher in the `Application and OS Images (Amazon Machine Image)`

1. Select 'Bakery' in `Key pair (login)` - `Key pair name - required`

1. Select 'Bakery' in `Network settings` - `Select existing security group` - `Common security groups`

1. Input 20 GiB in `Configure storage` - `1x`

1. Click `Launch instance` button in the bottom right corner

1. After creating and running the virtual machine, connect to it from outside (OpenSSH or Putty) using SSH protocol (use the previously saved key file)

1. Run this command preferably from the `/home` Linux directory to download, install and launch UI Bakery:

   ```bash
   curl -k -L -o install.sh https://raw.githubusercontent.com/uibakery/self-hosted/main/install.sh && bash ./install.sh
   ```

1. Upon request, enter the previously received license code, hosting URL - Public IPv4 address AWS EC2 Instance, and port ({BakeryPort} which you selected in the earlier steps 3030 by default).

1. After the installation is completed and launched, enter the bakery from a browser on your local machine at http://{Public IPv4 address AWS EC2 Instance}:{BakeryPort}

## Deploying on Google Cloud Compute Engine VM instance

1. Open [Google Cloud Console](http://console.cloud.google.com/). On your project page, select `Navigation Menu` - `Compute Engine` - `VM instances`

1. Select `Create an instance` - `New Vm instance`

1. Input `bakery` in `Name`. Select region and zone

1. Select `E2` in `Series` field and `e2-medium` in `Machine Type` field in the block `Machine configuration - Machine family - General-purpose`

1. Press `Change` button in block `Boot Disk`

1. Select `Ubuntu` in the `Operation System`, `Ubuntu 18.04 LTS` or higher in the `Version` and input `20` in `Size (GB)`. Click `Select` button

1. Click `Create` button at the bottom of the page

1. On your project page, select `Navigation Menu` - `VPC Network` - `Firewall` and press `Create a firewall rule` button

1. Input `bakery` in `Name` and select `All instances in the network` in `Targets`

1. Input `0.0.0.0/0` in `Source IPv4 ranges`

1. Go to the block `Protocols and ports`. Select `Specified protocols and ports` and `TCP`, input `{BakeryPort}` (use 3030 by default, you will need to select the same port during UI Bakery installation later) in the `Port`

1. Click `Create` button at the bottom of the page

1. On your project page, select `Navigation Menu` - `Compute Engine` - `VM instances`

1. Select VM instance `Bakery` and press `SSH - Open in Browser Window`. Will be open `SSH-in-browser` window.

1. Run this command preferably to download, install and launch UI Bakery:

    ```bash
    curl -k -L -o install.sh https://raw.githubusercontent.com/uibakery/self-hosted/main/install.sh && bash ./install.sh
    ```

1. Upon request, enter the previously received license code, hosting URL - External IP address VM Instance, and port ({BakeryPort} which you selected in the earlier steps 3030 by default).

1. After the installation is completed and launched, enter the UI Bakery from a browser on your local machine at http://{External IP address Vm Instance}:{BakeryPort}

## Manual installation

:warning: MySQL instance is included into the out of the box container and doesn't require any additional setup. If you need to have a standalone database, read [Running a standalone database instance](#running-a-standalone-database-instance)

- Install [docker](https://docs.docker.com/engine/install/) 20.10.11 version or higher and [docker-compose](https://docs.docker.com/compose/install/) 1.29.2 version or higher
- Start docker daemon
- Get on-premise сonfiguration files:

  ```bash
  mkdir ui-bakery-on-premise && cd ui-bakery-on-premise && curl -k -L -o docker-compose.yml https://raw.githubusercontent.com/uibakery/self-hosted/main/docker-compose.yml && curl -k -L -o docker-compose-external-db.yml https://raw.githubusercontent.com/uibakery/self-hosted/main/docker-compose-external-db.yml && curl -k -L -o setup.sh https://raw.githubusercontent.com/uibakery/self-hosted/main/setup.sh
  ```

- Get the license key [from UI Backery Team](https://uibakery.io/on-premise-ui-bakery). You'll get a key like of the following format: `eyJhbaj8es9fj9aesI6IkpXVCJ9.eyJsjioOHGEFOJeo0JSe98fJEJSEJFImVtYWlsIjoibmlrLnBvbHRvcmF0c2t5QGdtYWlsLmNvbSJ9.2n9q1LmjnBn62KyAM3FlYZ8PzQcxmIK0_mptNv38ufM`

- Run `./setup.sh`:

  - Enter the license key
  - Enter the port (leave empty for local installation, 3030 port will be used)
  - Enter the server URL (leave empty for local installation)

- Run `docker-compose up -d` to start the containers

- Wait until all containers are up and running

- Open port `3030` or `UI_BAKERY_PORT` (if it was modified in `.env` file or entered in `./setup.sh`) to access UI Bakery instance, then you can create a new account.

## Kubernetes

1. Clone the repository `git clone git@github.com:uibakery/self-hosted.git`
2. Open the `kubernetes` directory
3. Edit the `ui-bakery-configmap.yaml`, and set the required variables inside the `{{ ... }}`, where:

- `UI_BAKERY_APP_SERVER_NAME` - your {server ip address}:3030, for example `http://123.123.123.123:3030`
- `UI_BAKERY_LICENSE_KEY` - get it from UI Bakery team
- You either have to run a [standalone database instance](#running-a-standalone-database-instance) or make sure standard `PersistentVolumeClaim` exists in your cluster.

4. Run `kubectl apply -f .`

Please note that the application will be exposed on a public ip address on port 3030, so DNS and SSL have to be handled by the user.

## Azure container instance

1. Login docker to azure.

```bash
docker login azure
```

2. Create docker context.

```bash
docker context create aci uibakery
```

3. Use new context.

```bash
docker context use uibakery
```

4. Clone ui bakery self-hosted repository.

```bash
git clone https://github.com/uibakery/self-hosted.git && cd self-hosted
```

5. UI Bakery requires db to persist its data. So we have to create one. We suggest you using [**Azure Database for MySQL**](https://azure.microsoft.com/en-us/services/mysql/#overview).

6. Set `UI_BAKERY_LICENSE_KEY` variable in _docker-compose-azure-container-instances.yml_ for `bakery-back` service.

```bash
UI_BAKERY_LICENSE_KEY=${UI_BAKERY_LICENSE_KEY:-eyJhbGciOiJIUz}
```

7. Set `UI_BAKERY_DB_*` variables in _docker-compose-azure-container-instances.yml_ for `bakery-back` service.

```bash
UI_BAKERY_DB_HOST=${UI_BAKERY_DB_HOST:-azure-container-instance-test-db.mysql.database.azure.com}
UI_BAKERY_DB_PORT=${UI_BAKERY_DB_PORT:-3306}
UI_BAKERY_DB_DATABASE=${UI_BAKERY_DB_DATABASE:-bakery}
UI_BAKERY_DB_USERNAME=${UI_BAKERY_DB_USERNAME:-uibakeryuser@azure-container-instance-db}
UI_BAKERY_DB_PASSWORD=${UI_BAKERY_DB_PASSWORD:-uibakerypassword}
```

8. Up azure container instance.

```bash
docker compose -f docker-compose-azure-container-instances.yml up
```

9. Find assigned IP address. Run `docker ps` and in colum _PORTS_ you'll find assigned IP address.

10. Replace all occurrences of `UI_BAKERY_APP_SERVER_NAME` with the IP address retrieved in the previous step.

```bash
UI_BAKERY_APP_SERVER_NAME=https://123.123.123.123
```

11. Restart instance to apply new configuration.

```bash
docker compose -f docker-compose-azure-container-instances.yml up
```

## Running a standalone database instance

In case when a 3rd party MySQL instance is required:

1. Create database and user. User must have the following permissions:
    ```sql
        GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, REFERENCES, INDEX, ALTER, LOCK TABLES, EXECUTE, CREATE ROUTINE, ALTER ROUTINE
    ```

1. Provide the following environment variables:

   ```bash
   UI_BAKERY_DB_HOST=192.168.0.1
   UI_BAKERY_DB_PORT=3306
   UI_BAKERY_DB_DATABASE=bakery
   UI_BAKERY_DB_USERNAME=username
   UI_BAKERY_DB_PASSWORD=password
   ```

1. Run `docker-compose -f ./docker-compose-external-db.yml up` to start the containers, alternatively, `docker-compose -f ./docker-compose-external-db.yml up -d` to run containers in the background.

## Running on a remote instance

If you would like to run UI Bakery not on localhost, but on a server, you need to provide the following variables:

```bash
UI_BAKERY_APP_SERVER_NAME=http://YOUR_DOMAIN_OR_IP:3030
UI_BAKERY_PORT=3030
```

:warning: UI_BAKERY_PORT variable must match port in UI_BAKERY_APP_SERVER_NAME variable

In your DNS provider, configure the following records:

- A or CNAME record with UI Bakery instance host

Then modify your environment variable with the following values:

```bash
UI_BAKERY_APP_SERVER_NAME=https://YOUR_DOMAIN
UI_BAKERY_PORT=80
```

## Google OAuth2 setup

UI Bakery Google OAuth2 can be done by one setting.

1. Create OAuth Client ID in [Google Developer Console](https://console.cloud.google.com/apis/credentials)

   - Create or choose an existing project.
   - Click on “Create credentials”.
   - Choose “OAuth Client ID”.
   - Choose “Web Application” Application type.
   - Specify `http://localhost:3030` or `UI_BAKERY_APP_SERVER_NAME` for authorized javascript origin.
   - Specify `http://localhost:3030/auth/oauth2/callback` or `UI_BAKERY_APP_SERVER_NAME/auth/oauth2/callback` for authorized redirect URLs.
   - Click “Create”.
   - Copy “Your Client ID”.

1. Provide `UI_BAKERY_GOOGLE_CLIENT_ID=Your Client ID` environment variable.
1. Provide `UI_BAKERY_APP_SERVER_NAME=http(s)://youdomain.com` environment variable in case you want to run UI Bakery on a custom domain/IP.

## Generic OAuth2 SSO provider 

UI Bakery supports integration with OAuth2 providers.
Provide the following variables to set up OAuth2 SSO:

   ```bash
   UI_BAKERY_OAUTH_CLIENT_ID=0oa3deycosL4fFEvx5d0
   UI_BAKERY_OAUTH_SECRET=sO8BPgTb5MVs9kS37Qoml5sCEK7faFX78VDP2E3q
   UI_BAKERY_OAUTH_SCOPE=openid email offline_access profile
   UI_BAKERY_OAUTH_AUTH_URL=https://mybakery.okta.com/oauth2/v1/authorize
   UI_BAKERY_OAUTH_TOKEN_URL=https://mybakery.okta.com/oauth2/v1/token
   UI_BAKERY_OAUTH_USERINFO_URL=https://mybakery.okta.com/oauth2/v1/userinfo
   UI_BAKERY_OAUTH_EMAIL_KEY=email
   ```

## SAML authentication setup

1. Configure your Identity provider. In identity provider settings, set **Sign on URL** and **Reply URL** to `https://APP_LOCATION/api/auth/login/saml`. Replace `APP_LOCATION` with UI Bakery instance URL. Configure **name** and **role** attributes. You can set claim name in identity provider settings or in UI Bakery env variables `UI_BAKERY_SSO_NAME_CLAIM` and `UI_BAKERY_SSO_ROLE_CLAIM`.

1. Provide URL of your identity provider metadata and entity ID via the following env variables:

   ```bash
   UI_BAKERY_SAML_METADATA_URL=https://your.identityprovider.com/federationmetadata/2007-06/federationmetadata.xml.
   UI_BAKERY_SAML_ENTITY_ID=http://appregestry.com/myapp/primary
   ```

1. Set variable `UI_BAKERY_SAML_ENABLED=true`

### SSO roles synchronization

By default, UI Bakery will not sync any roles provided by the Identity Provider. 

1. To enable roles synchronization, set the variable `UI_BAKERY_SSO_SYNC_ROLES=true`. Out of the box, UI Bakery will try to match received **roles by names**. Roles sync will be done only during the sign up process. If a match is found (e.g. SSO returned a `support` role and UI Bakery has this role in the workspace), current user roles will be deleted and the matched SSO role(s) will be assinged to the user.

    :warning: During user sign up, a default `user` role will be assigned unless `UI_BAKERY_SSO_HARD_SYNC_ROLES` is enabled.
    
    :warning: If no match is found, UI Bakery will leave the current user roles. See `UI_BAKERY_SSO_HARD_SYNC_ROLES` to change this behaviour.
1. Additionally, you can configure a role mapping from identity provider role id/name to a UI Bakery role:

      ```bash
      UI_BAKERY_SSO_ROLE_MAPPING=identityRoleName->bakeryRoleName,identityRoleName2->bakeryRoleName2
      ```
1. If your setup requires a complete syncronization, when UI Bakery overwrites all roles, removing existing ones and adding new ones received from Identity Provider even if SSO returns no matching roles (e.g. user has no access to the system), use the following variable:
   ```bash
    UI_BAKERY_SSO_HARD_SYNC_ROLES=true
   ```
   
   :warning: Please note, if no roles are found, the user will be removed from the organization and will no longer be able to access it.

1. To sync roles during the login as well, set `UI_BAKERY_SSO_SYNC_ROLES_ON_LOGIN=true`
1. By default, UI Bakery will only sync roles for end-users, leaving the `admin` and `editor` roles untouched. To sync roles for all users, set `UI_BAKERY_SSO_SYNC_ROLES_FOR_EDITOR_AND_ADMIN=true`

    :warning: Please note, this way admin accounts may lose the access to the system in a case of malformed configuration.
   
## Other authentication setting

1. You can set the variable `UI_BAKERY_SSO_LOGIN_AUTO` to true to enable automatic login. Any unauthorized user will be redirected to SSO login flow.

1. You can disable email authentication by providing the environment variable `UI_BAKERY_EMAIL_AUTH_ENABLED=false`

1. Provide `UI_BAKERY_AUTH_RESTRICTED_DOMAIN=domain.com` environment variable to restrict Google login only to the specified domain.

## Embedding

UI Bakery self-hosted can be easily embedden in other web applications and pages. It is also possible to setup two-way communitcation between embedded app and website the app is embedded in.

1. Embed UI Bakery in an iframe where `src` is a link to an Embedded UI Bakery application (e.g. `https://custom-uibakery.com/share/SKDUFYUDF`)

```html
<script src="https://custom-uibakery.com/uibakery-embedded.js"></script>
<iframe width="100%" height="50%" id="uibakery" src="https://custom-uibakery.com/share/SKDUFYUDF"></iframe>
```

2. Add a script tag to the page where UI Bakery app is embedded to communicate with internal app actions:

```html
<input type="number" value="10" />
<button>Execute Action</button>

<script>
  const bakery = UIBakery('#uibakery');
  bakery.onReady(() => {
    document.querySelector('button').addEventListener('click', () => {
      const limit = parseInt(document.querySelector('input').value, 10);

      // execute UI Bakery action with {{params}} = { limit: 10 }
      bakery.triggerAction('actionName', { limit });
    });

    // listen to messages sent from UI Bakery
    bakery.onMessage('customEvent', params => {
      console.log(params);
    });
  });
</script>
```

3. Use the following code to send messages from UI Bakery actions to the parent window

```js

UIBakeryEmbedded.emitMessage('customEvent', {{data}})	;
```

## Limitations

- Emails won’t be sent from the local instance, although the invitation system works in a way that any invited email can access the organization by creating an account.

- Google Sheets connection requires [additional setup](#google-sheets-connection-setup).

# Google Sheets connection setup

Start with creating OAuth Client ID in [Google Developer Console](https://console.cloud.google.com/apis/credentials). Then, follow the below steps:

1. Create a new or choose an existing project.
1. Go to **API & Services** section.
1. Click **ENABLE APIS AND SERVICES** and enable Google Sheets API.
1. Click on **Create credentials** and choose **Create OAuth client ID**.
1. Select **Web Application**.
1. Add Authorized redirect URI with value `http://YOUR_IP_OR_DOMAIN/gsheet-oauth-callback`
1. Click **Create**.
1. Set credentials in `UI_BAKERY_GSHEET_CLIENT_ID` and `UI_BAKERY_GSHEET_CLIENT_SECRET` variables.
1. Go to **OAuth consent screen** and create it with an external type.
1. Publish your consent screen.

# Configuring email provider

By default, UI Bakery On-Premise comes with a **noop** email provider that will only log emails to the backend logs.

## Configure Sendgrid

We suggest using [Sendgrid](https://sendgrid.com/) email provider to send the emails:

1. [Create a Sendgrid](https://app.sendgrid.com/) account or use an existing account
1. [Generate an API Key](https://app.sendgrid.com/settings/api_keys) with the Mail Send access enabled
1. Set the following environment variables:

   ```bash
   UI_BAKERY_MAILING_PROVIDER=sendgrid
   SENDGRID_API_KEY=YOUR_API_KEY
   SENDGRID_EMAIL_FROM=your@company.com # make sure this domain is authorized to send emails in your sendgrid account
   ```

1. Restart the containers.

Once configured, your instance will start using your account to send the user invitation, password reset, and other emails.

## Change email templates

By default, email templates and subjects are provided as environment variables, so you can adjust the emails by modifying their content:

```bash
# tells that email will be sent as plain text/html
UI_BAKERY_MAILING_TEMPLATES_MODE=custom

UI_BAKERY_MAILING_WELCOME_TEMPLATE=Hello userName,<br> Welcome to UI Bakery workspace.
UI_BAKERY_MAILING_WELCOME_SUBJECT=Welcome to UI Bakery workspace

UI_BAKERY_MAILING_RESET_PASSWORD_TEMPLATE=Hello userName,<br> Here's your <a href="resetPasswordUrl">password reset link</a>.
UI_BAKERY_MAILING_RESET_PASSWORD_SUBJECT=Reset password request

UI_BAKERY_MAILING_CONFIRM_EMAIL_CHANGE_TEMPLATE=Hello userName,<br> Here's a link <a href="changeEmailUrl">to change your email</a>.
UI_BAKERY_MAILING_CONFIRM_EMAIL_CHANGE_SUBJECT=Change email request

UI_BAKERY_MAILING_SHARE_WITH_USER_TEMPLATE=Hello userName,<br> Here's a <a href="organizationUrl">link to access the organizationName workspace</a>.
UI_BAKERY_MAILING_SHARE_WITH_USER_SUBJECT=You are invited to UI Bakery workspace
```

You can use the following built-in email variables to add user values to your emails:

```bash
# All emails
userName, userEmail, subject, userId

# Reset password request
resetPasswordUrl

# Invitation email
organizationUrl, organizationName

# Change email request
changeEmailUrl
```

Alternatively, you can set up email temples using [SendGrid dynamic templates](https://mc.sendgrid.com/dynamic-templates) and put template ids instead of plain HTML emails:

```bash
# tells that email will be sent using dynamic templates
UI_BAKERY_MAILING_TEMPLATES_MODE=provided

UI_BAKERY_MAILING_WELCOME_TEMPLATE=d-c3f84d76543941c084ff2de0exxxxxxx
UI_BAKERY_MAILING_RESET_PASSWORD_TEMPLATE=d-c3f84d76543941c084ff2de0exxxxxxx
UI_BAKERY_MAILING_CONFIRM_EMAIL_CHANGE_TEMPLATE=d-c3f84d76543941c084ff2de0exxxxxxx
UI_BAKERY_MAILING_SHARE_WITH_USER_TEMPLATE=d-c3f84d76543941c084ff2de0exxxxxxx
```

:warning: Note, that in this case an email subject will be taken from a dynamic template configuration and variables such as `UI_BAKERY_MAILING_WELCOME_SUBJECT` will be ignored.

This way, you don't need to manage templates content inside of your environment variables and can build more advanced email with images and custom styles.

# Updating on-premise version

Once an update to the on-premise version is available, we will notify you via email.

To update your UI Bakery on-premise version, follow the steps below:

1. Take a full backup of UI Bakery instance.
1. Go to your `ui-bakery-on-premise` folder:

```bash
cd ./ui-bakery-on-premise
```

1. Run `./update.sh` that will download new images and restart your instance:

```bash
./update.sh
```


# How to update licence key

To update your UI Bakery licence key, you need to change the corresponding variable:
```
UI_BAKERY_LICENSE_KEY=key_value
```
For docker-compose setup, the environment variables are located in `ui-bakery-on-premise/.env` file.
To restart your instance, use the following command:
```bash
docker-compose up -d
```


# UI Bakery in production

UI Bakery installation is ready for production out of the box.
However, there is a bunch of additional setup steps we recommend following:   

 - Put your instance behind HTTPS.
 - Use a standalone database.
 - Enable automatic backups for instance and database machines.
 - Store your environment variables in a secure place like secrets manager or key vault.

Make sure you override the following variables:
```
UI_BAKERY_JWT_SECRET
UI_BAKERY_JWT_REFRESH_SECRET
UI_BAKERY_JWT_SERVICE_ACCOUNT_SECRET
UI_BAKERY_CREDENTIALS_SECRET
UI_BAKERY_TEMPLATE_MAKER_PASSWORD
```

If you have used install script, then your .env file already contains unique values for those vars.
Otherwise, you can generate values for these variables with the script:
```
echo "'$(LC_ALL=C tr -cd "A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)\\-+=" < /dev/urandom | head -c 32 | xargs -0)'"
```


You can set the following environment variables to limit resource consumption (MB):
```
JAVA_OPTS=-Xmx1024m
NODE_OPTS=--max-old-space-size=1024
```

You can estimate memory size for both variables with the below multiplying:
```
S - request size in MB
T - time required to process request
N - number of concurent requests 

MEMORY_NEEDED=S*T*N
```


### [Supported Environment Variables](ENVIRONMENT_VARIABLES.md#supported-environment-variables)
