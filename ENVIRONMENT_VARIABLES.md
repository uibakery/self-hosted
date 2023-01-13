# Supported environment variables

| Environment variable name                   | Description                                                                                     |
|---------------------------------------------|-------------------------------------------------------------------------------------------------|
| UI_BAKERY_LICENSE_KEY                       | UI Bakery license key. To get your key [contact us](https://uibakery.io/contact-us).            |
| UI_BAKERY_APP_SERVER_NAME                   | Full domain address where UI Bakery is hosted. For example `https://bakery.mycompany.com`.      |
| UI_BAKERY_PORT                              | Defines the port UI Bakery is run on.                                                           |
| UI_BAKERY_SINGLE_ORGANIZATION               | When `true`, only one organization can exist. All other attempts to register new one will fail. |
| UI_BAKERY_MAINTENANCE_TIME_GMT              | Enables maintenance mode notice, format - Wed Sep 28 2022 16:08:13 GMT+0100                     |
| UI_BAKERY_MAINTENANCE_NOTICE_PRIOR_HOURS    | How many hours prior to maintenance the notice must be shown                                    |
| UI_BAKERY_EMBEDDED_ENABLE_ACTIONS_EXECUTION | If true, allows calling actions when UI Bakery is embedded in an iframe                         |

## Database

| Environment variable name                       | Description                                                                                                                                                                                       |
|-------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| UI_BAKERY_DB_DATABASE                           | MySQL database name, must be specified when external database is used.                                                                                                                            |
| UI_BAKERY_DB_HOST                               | MySQL host name, must be specified when external database is used.                                                                                                                                |
| UI_BAKERY_DB_PASSWORD                           | MySQL user password, must be specified when external database is used.                                                                                                                            |
| UI_BAKERY_DB_PORT                               | MySQL port, must be specified when external database is used.                                                                                                                                     |
| UI_BAKERY_DB_USERNAME                           | MySQL user name, must be specified when external database is used.                                                                                                                                |
| UI_BAKERY_DB_POOL_SIZE                          | Database connection pool size, can be specified when external database is used. Default value is `100`.                                                                                           |

## Encryption secrets

| Environment variable name                       | Description                                                                                                                                                                                       |
|-------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| UI_BAKERY_CREDENTIALS_SECRET                    | Encryption key for data source credentials. Must be exactly 32 characters long. Changing this variable on existed instance may lead to losing access to already connected data source.            |
| UI_BAKERY_JWT_SECRET                            | JWT secret is used to sign user requests to UI Bakery API.                                                                                                                                        |
| UI_BAKERY_JWT_REFRESH_SECRET                    | Similar to `UI_BAKERY_JWT_SECRET` but for refresh token.                                                                                                                                          |                                                                 |

## Datasources

| Environment variable name                       | Description                                                                                                                                                                                       |
|-------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| UI_BAKERY_DATASOURCE_TIMEOUT                    | Datasource request timeout in milliseconds. Default value is `90000`.                                                                                                                             |
| UI_BAKERY_DATASOURCE_MAX_SIZE                   | Datasource request maximum response size in bytes. Default value is `102400000`.                                                                                                                  |
| UI_BAKERY_GSHEET_CLIENT_ID                      | Google Sheet API Client Id. Must be provided when GSheet datasource is required.                                                                                                                  |
| UI_BAKERY_GSHEET_CLIENT_SECRET                  | Google Sheet API Client Secret. Must be provided when GSheet datasource is required.                                                                                                              |
| UI_BAKERY_SALESFORCE_CLIENT_ID                  | Salesforce API Client Id. Must be provided when Salesforce datasource is required.                                                                                                                |
| UI_BAKERY_SALESFORCE_CLIENT_SECRET              | Salesforce API Client Secret. Must be provided when Salesforce datasource is required.                                                                                                            |

## Authentication

| Environment variable name                     | Description                                                                                                                                                                                       |
|-----------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| UI_BAKERY_EMAIL_AUTH_ENABLED                  | By default is `true`. Can be set to `false` to allow authentication only with OAuth2 or SAML SSO.                                                                                                 |
| UI_BAKERY_REGISTER_URL                        | URL for UI Bakery Sign Up page. Default value is `/register`.                                                                                                                                     |
| UI_BAKERY_GOOGLE_CLIENT_ID                    | Google OAuth Client Id. Must be provided to enable authentication with Google.                                                                                                                    |
| UI_BAKERY_AUTH_RESTRICTED_DOMAIN              | Used to restrict which email addresses are allowed to authenticate with OAuth2. For example `mycompany.com`                                                                                       |
| UI_BAKERY_OAUTH_CLIENT_ID                     | OAuth2 client id.                                                                                                                                                                                 |
| UI_BAKERY_OAUTH_SECRET                        | OAuth2 client secret.                                                                                                                                                                             |
| UI_BAKERY_OAUTH_SCOPE                         | OAuth2 scope, space separated string.                                                                                                                                                             |
| UI_BAKERY_OAUTH_AUTH_URL                      | Authorization URL for OAuth2.                                                                                                                                                                     |
| UI_BAKERY_OAUTH_TOKEN_URL                     | Token endpoint URL for OAuth2.                                                                                                                                                                    |
| UI_BAKERY_OAUTH_USERINFO_URL                  | Userinfo endpoint URL for OAuth2.                                                                                                                                                                 |
| UI_BAKERY_OAUTH_EMAIL_KEY                     | Email key attribute name for OAuth2. Default is 'email'.                                                                                                                                          |
| UI_BAKERY_OAUTH_ID_KEY                        | Id key attribute name for OAuth2. Default is 'sub'.                                                                                                                                               |
| UI_BAKERY_SAML_ENABLED                        | Set to `true` to enable SAML authentication.                                                                                                                                                      |
| UI_BAKERY_SAML_ENTITY_ID                      | Global unique name (Entity ID) for SAML Entity. For example `http://adapplicationregistry.onmicrosoft.com/myorganization/myapp`. Required for SAML authentication.                                |
| UI_BAKERY_SAML_METADATA_URL                   | URL to SAML metadata XML. Required for SAML authentication.                                                                                                                                       |
| UI_BAKERY_SSO_LOGIN_AUTO                      | When `true`, SSO authentication flow starts as soon as a user opens Sign In or Sign up page. When `false`, a user must click `Login with SAML` explicitly.                                        |
| UI_BAKERY_SSO_NAME_CLAIM                      | Name of the custom attribute for SSO that will be used for UI Bakery user name. Default value is `name`.                                                                                          |
| UI_BAKERY_SSO_ROLE_CLAIM                      | Name of the custom attribute for SSO that will be used for UI Bakery role mapping. Default value is `role`.                                                                                       |
| UI_BAKERY_SSO_SYNC_ROLES                      | Enable roles synchronization from Identity Server to UI Bakery                                                                                                                                    |
| UI_BAKERY_SSO_SYNC_ROLES_ON_LOGIN             | Enable roles sync on login                                                                                                                                                                        |
| UI_BAKERY_SSO_HARD_SYNC_ROLES                 | Rewrite roles on sync                                                                                                                                                                             |
| UI_BAKERY_SSO_SYNC_ROLES_FOR_EDITOR_AND_ADMIN | Sync roles for admin and editor user roles as well                                                                                                                                                |
| UI_BAKERY_SSO_ROLE_MAPPING                    | Key pair role mapping where a key is a SSO provider custom claim and value is UI Bakery role name, UI_BAKERY_SSO_ROLE_MAPPING=identityRoleName->bakeryRoleName,identityRoleName2->bakeryRoleName2 |

## Branding

| Environment variable name                           | Description                                                                                               |
|-----------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| UI_BAKERY_APP_TITLE                                 | HTML `<title/>` tag content. Default value is `UI Bakery`.                                                |
| UI_BAKERY_GTM                                       | An arbitary HTML tag that will be added after the <body> open tag. Can be used to provide custom styles or scripts `<style>.header-container {  background-color: aquamarine; }</style>`       |
| UI_BAKERY_BRANDING_AUTH_BACKGROUND_URL              | URL to image. Allows you to set custom background image for auth screen.                                  |
| UI_BAKERY_BRANDING_AUTH_CARD_STYLES                 | CSS styles for card on auth screens. `background: transparent; box-shadow: none;`.                        |
| UI_BAKERY_BRANDING_AUTH_HEADER_STYLES               | CSS styles for card headers ("Login" and "Signup") on auth screens. `font-weight: 600; font-size: 2rem;`. |
| UI_BAKERY_BRANDING_AUTH_GOOGLE_BTN_STYLES           | CSS styles for "LOGIN WITH GOOGLE" button on auth screens. `background: white; border: none;`.            |
| UI_BAKERY_BRANDING_AUTH_LOGO_STYLES                 | CSS styles for logo on auth screens. `margin-bottom: 2rem; width: 100%; height: 2.5rem;`                  |
| UI_BAKERY_BRANDING_FAVICON                          | URL to image. Allows you to set custom favicon.                                                           |
| UI_BAKERY_BRANDING_LOADER                           | Loader image. `<svg class="loader-logo"></svg>`, `class="loader-logo"` is required.                       |
| UI_BAKERY_BRANDING_LOADER_STYLES                    | CSS styles for loader. `background: #003D4C; transform: scale(2)`.                                        |
| UI_BAKERY_BRANDING_LOGO_URL                         | URL to image. Allows you to replace UI Bakery logo.                                                       |
| UI_BAKERY_BRANDING_MENU_LOGO_URL                    | URL to image. Allows you to replace UI Bakery logo in top left corner of the workspace.                   |
| UI_BAKERY_BRANDING_AUTH_FORGOT_PASSWORD_LINK_HIDDEN | `true` or `false` - show the reset password link.                                                         |
| UI_BAKERY_BRANDING_AUTH_SIGN_UP_LINK_HIDDEN         | `true` or `false` - show the sign up link.                                                                |

## Mailing

| Environment variable name                       | Description                                                                                                                                                                                       |
|-------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| UI_BAKERY_MAILING_PROVIDER                      | Should be set to `sendgrid` to enable email messages. Default value is `noop`                                                                                                                     |
| SENDGRID_API_KEY                                | SendGrid API key. Required if transactional emails to users are required.                                                                                                                         |
| SENDGRID_EMAIL_FROM                             | Email sender address for welcome email. Default value is `admin@uibakery.io`.                                                                                                                     |
| SENDGRID_NAME_FROM                              | Email sender name for welcome email. Default value is `Admin`.                                                                                                                                    |
| SENDGRID_SYSTEM_EMAIL_FROM                      | Email sender address. Default value is `admin@uibakery.io`.                                                                                                                                       |
| SENDGRID_SYSTEM_NAME_FROM                       | Email sender name. Default value is `Admin`.                                                                                                                                                      |
| UI_BAKERY_MAILING_WELCOME_SUBJECT               | Subject for welcome email. Default value is `Welcome to UI Bakery workspace`.                                                                                                                     |
| UI_BAKERY_MAILING_WELCOME_TEMPLATE              | Can be HTML string or SendGrid email template ID. Supported variables: `{{userName}}` and `{{userEmail}}`.                                                                                        |
| UI_BAKERY_MAILING_CONFIRM_EMAIL_CHANGE_SUBJECT  | Subject for email change email. Default value is `Change email request`.                                                                                                                          |
| UI_BAKERY_MAILING_CONFIRM_EMAIL_CHANGE_TEMPLATE | Can be HTML string or SendGrid email template ID. Supported variables: `{{userName}}`, `{{userEmail}}` and `{{changeEmailUrl}}`.                                                                  |
| UI_BAKERY_MAILING_RESET_PASSWORD_SUBJECT        | Subject for password reset email. Default value is `Reset password request`.                                                                                                                      |
| UI_BAKERY_MAILING_RESET_PASSWORD_TEMPLATE       | Can be HTML string or SendGrid email template ID. Supported variables: `{{userName}}`, `{{userEmail}}` and `{{resetPasswordUrl}}`.                                                                |
| UI_BAKERY_MAILING_SHARE_WITH_USER_SUBJECT       | Subject for inviting user email. Default value is `You are invited to UI Bakery workspace`.                                                                                                       |
| UI_BAKERY_MAILING_SHARE_WITH_USER_TEMPLATE      | Can be HTML string or SendGrid email template ID. Supported variables: `{{userName}}`, `{{userEmail}}`, `{{organizationUrl}}` and `{{organizationName}}`.                                         |
