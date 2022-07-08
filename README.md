# UI Bakery on-premise

#### Deploy UI Bakery locally to manage your data from your private network

-----------------------------------------------------------

We understand that you might have lots of data accessible from your private network, that’s why you can use UI Bakery self-hosted version for your benefit.

On-premise version grants you:

- A quick setup process
- Custom branding
- Custom domain hosting
- Google SSO
- SAML-based identity providers
- Data is stored securely under your own VPS

:heavy_check_mark: UI Bakery on-premise version license key can be obtained [here](https://uibakery.io/on-premise-ui-bakery)

:warning: If you have already installed UI Bakery on-premise version, follow [this guide](#updating-on-premise-version) to update your version.

## Table of contents
- [Installation](#installation)
  - [Requirements](#requirements)
  - [Installation steps](#installation-steps)
- [Manual installation](#manual-installation)
- [Kubernetes](#kubernetes)
- [Running a standalone database instance](#running-a-standalone-database-instance)
- [Running on a remote instance](#running-on-a-remote-instance)
- [Google oauth setup](#google-oauth-setup)
- [SAML authentication setup](#saml-authentication-setup)
  - [Authentication settings](#other-authentication-setting)
  - [Limitations](#limitations)
- [Google Sheets connection setup](#google-sheets-connection-setup)
- [Emails configuration](#configuring-email-provider)
  - [Sendgrid](#configure-sendgrid)
  - [Email templates](#change-email-templates)
- [Staying up to date](#updating-on-premise-version)

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

## Running a standalone database instance

In case when a 3rd party MySQL instance is required:

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

## Google OAuth setup

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
1. Run `docker-compose up` if you want to use the embedded database.
1. Or run `docker-compose -f ./docker-compose-external-db.yml` up with environment variables described in [Running a standalone database instance](#running-a-standalone-database-instance) above in case you want to use an external database.

## SAML authentication setup

1. Configure your Identity provider. In identity provider settings, set **Sign on URL** and **Reply URL** to `https://APP_LOCATION/api/auth/login/saml`. Replace `APP_LOCATION` with UI Bakery instance URL. Configure **name** and **role** attributes. You can set claim name in identity provider settings or in UI Bakery env variables `UI_BAKERY_SAML_NAME_CLAIM` and `UI_BAKERY_SAML_ROLE_CLAIM`.

1. Provide URL of your identity provider metadata and entity ID via the following env variables:

   ```bash
   UI_BAKERY_SAML_METADATA_URL=https://your.identityprovider.com/federationmetadata/2007-06/federationmetadata.xml.
   UI_BAKERY_SAML_ENTITY_ID=http://appregestry.com/myapp/primary
   ```

1. Set variable `UI_BAKERY_SAML_ENABLED=true`

1. You can add a role mapping from identity provider role to UI Bakery role via env variable:

   ```bash
   UI_BAKERY_ROLE_MAPPING=identityRoleName->bakeryRoleName,identityRoleName2->bakeryRoleName2 
   ```

1. You can set the variable `UI_BAKERY_SAML_LOGIN_AUTO` to true to enable automatic login. Any unauthorized user will be redirected to SAML login flow.

## Other authentication setting

1. You can disable email authentication by providing the environment variable `UI_BAKERY_GOOGLE_AUTH_ONLY=true`

1. Provide `UI_BAKERY_AUTH_RESTRICTED_DOMAIN=domain.com` environment variable to restrict Google login only to the specified domain.

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
1. Download the new version archive:

   ```bash
   curl -k -L -o ui-bakery-on-premise-vlatest.tar.gz https://storageaccountrguib99d2.blob.core.windows.net/ui-bakery-cloud-on-premise/ui-bakery-on-premise-vlatest.tar.gz 
   ```

1. Unpack archive to the same folder: `tar -xvf ui-bakery-on-premise-vlatest.tar.gz -C ui-bakery-on-premise && cd ui-bakery-on-premise`
1. Restart the application: `docker-compose up --build -d`

### [Supported Environment Variables](ENVIRONMENT_VARIABLES.md#supported-environment-variables)

