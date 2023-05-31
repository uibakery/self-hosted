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

:warning: If you have already installed UI Bakery on-premise version, follow [this guide](https://docs.uibakery.io/on-premise/updating-on-premise-version) to update your version.

## Table of contents

- [Installation](#installation)
  - [Requirements](#requirements)
  - [Basic installation](#basic-installation)
  - [Other installation options](#other-installation-options)
  
- [Documentation](#documentation)

## Installation

This document describes how to deploy ui-bakery on-prem via `install.sh` script.

:warning: The script installs docker and docker-compose, which may upgrade some dependencies under the hood. Please be advised that if you run this script on the OS used as a server for other applications, those applications may break due to that potential dependencies upgrade.

### Requirements

- Linux-based OS (e.g. Ubuntu 18.04).
- Minimum 1 `vCPUs`, 2 `GiB` memory and 5 `GiB` of storage.
- Must have full rights to use "sudo".

### Basic installation

1. Run this command preferably from `/home` Linux directory to download, install and launch UI Bakery:

   ```bash
   curl -k -L -o install.sh https://raw.githubusercontent.com/uibakery/self-hosted/main/install.sh && bash ./install.sh
   ```

1. In the process, upon request, enter the previously received license code, hosting URL and port.
1. Once the installation is completed, open the browser using URL and port provided earlier. By default it is [http://localhost:3030/](http://localhost:3030/).

**NOTE**: If Docker of the version less than the required (minimum 20.10.11) is already installed on the server, and/or Docker Compose (minimum 1.29.2), the script will be stopped. You need to update the versions of components manually and run the script again.

### Other installation options
For additional installation instructions, such as those for Azure, AWS, GCP, Kubernetes, and more, please visit the [documentation website](https://docs.uibakery.io/on-premise/installing-on-premise-version).

## Documentation

For instructions on installing, updating, and managing the on-premise instance, please refer to the [documentation website](https://docs.uibakery.io/on-premise/ui-bakery-on-premise).


