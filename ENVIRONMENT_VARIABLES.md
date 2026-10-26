# Environment variables

## Project assets and AI attachments

Configure these variables in the installation's `.env` file for Docker Compose, or in the backend environment for other deployment methods. Recreate the backend container or redeploy it after changing its environment.

New self-hosted installations use `BAKERY_STORAGE`. Configure one **private** system bucket/container name for the entire installation. On first storage use, Bakery Storage creates it if missing or reuses an existing accessible bucket. Repeated calls, restarts, and concurrent backend instances preserve existing data. Creation/access failures are returned without fallback. UI Bakery never deletes this bucket, and it has no datasource or entry in the user-facing Storage UI. Configuration discovery and URL construction do not create it.

### Storage mode and download lifetimes

| Variable | Default | Description |
| --- | --- | --- |
| `UI_BAKERY_ASSET_STORAGE_MODE` | `BAKERY_STORAGE` | Selects exactly one mode: `BAKERY_STORAGE` uses the configured Bakery Storage provider; `AZURE` uses legacy Azure asset storage. |
| `UI_BAKERY_STORAGE_SYSTEM_BUCKET` | Unset | Private bucket/container name, created automatically if missing; required in `BAKERY_STORAGE` mode. Shared by all projects in the installation. |
| `UI_BAKERY_STORAGE_PROVIDER` | `AZURE_BLOB` | Existing Bakery Storage provider: `S3_COMPATIBLE` or `AZURE_BLOB`. Used in `BAKERY_STORAGE` mode. |
| `UI_BAKERY_ASSET_STORAGE_READ_VALIDITY` | `1m` | Signed-read lifetime for ordinary files in `BAKERY_STORAGE` mode. Uses Spring duration syntax. |
| `UI_BAKERY_ASSET_STORAGE_CHAT_READ_VALIDITY` | `15m` | Signed-read lifetime for AI attachments in `BAKERY_STORAGE` mode. Uses Spring duration syntax. |

Storage modes are mutually exclusive. There is no migration, reading from both modes, or automatic fallback if the selected storage fails. Changing modes or the configured bucket makes existing references unavailable through the installation until the original configuration is restored.

### AWS S3 and S3-compatible storage

Use the existing Bakery Storage connection settings:

```dotenv
UI_BAKERY_ASSET_STORAGE_MODE=BAKERY_STORAGE
UI_BAKERY_STORAGE_SYSTEM_BUCKET=uibakery-system-assets
UI_BAKERY_STORAGE_PROVIDER=S3_COMPATIBLE
UI_BAKERY_STORAGE_S3_ENDPOINT=https://s3.us-east-1.amazonaws.com
UI_BAKERY_STORAGE_S3_REGION=us-east-1
UI_BAKERY_STORAGE_S3_ACCESS_KEY=<access key>
UI_BAKERY_STORAGE_S3_SECRET_KEY=<secret key>
UI_BAKERY_STORAGE_S3_PATH_STYLE=false
```

Replace placeholders with your existing connection values. No separate system-storage credentials mechanism is introduced.

For MinIO or another S3-compatible service, use its endpoint and region, and set `UI_BAKERY_STORAGE_S3_PATH_STYLE=true` when required. The path-style setting defaults to `true`; the AWS S3 example explicitly selects `false`.

The S3 identity needs `s3:CreateBucket` and `s3:ListBucket` on `arn:aws:s3:::uibakery-system-assets` (creation and the `HeadBucket` existence/access check), plus `s3:PutObject` and `s3:GetObject` on `arn:aws:s3:::uibakery-system-assets/assets/*`. Replace the bucket name with a globally unique name for AWS S3. System assets do not require bucket deletion or public access. Existing user-created Bakery Storage buckets may need their existing additional permissions.

Project assets use `assets/{storageProjectId}/images|files/{blobId}` object paths. Public uploaded files use `assets/public-uploaded-files/` in the same bucket, retaining their existing token and file-index behavior.

### Azure Bakery Storage provider

For `BAKERY_STORAGE` mode with a private Azure container, automatically created if missing:

```dotenv
UI_BAKERY_ASSET_STORAGE_MODE=BAKERY_STORAGE
UI_BAKERY_STORAGE_SYSTEM_BUCKET=<private container name>
UI_BAKERY_STORAGE_PROVIDER=AZURE_BLOB
UI_BAKERY_AZURE_BAKERY_STORAGE_CONNECTION_STRING=<connection string>
```

`UI_BAKERY_AZURE_BAKERY_STORAGE_CONNECTION_STRING` falls back to the existing `UI_BAKERY_AZURE_BLOB_STORAGE_CONNECTION_STRING` when unset. The configured account key must permit checking/creating containers, blob reads/writes, and read SAS generation. Keep the container private; system assets need read/write access under `assets/` and do not require container deletion.

The provider-neutral download lifetimes above apply to system assets in this mode. Existing user-facing Bakery Storage presign lifetimes are unchanged.

### Existing Azure installations: before upgrading

Explicitly configure the following **before upgrading** to preserve existing Azure asset storage:

```dotenv
UI_BAKERY_ASSET_STORAGE_MODE=AZURE
```

Keep your existing `UI_BAKERY_AZURE_BLOB_STORAGE_CONNECTION_STRING`, `UI_BAKERY_AZURE_CONTAINER_NAME`, and `UI_BAKERY_AZURE_CONTAINER_PREFIX` settings. Legacy mode continues to use these signed-read lifetimes, expressed in milliseconds:

| Variable | Default |
| --- | --- |
| `UI_BAKERY_AZURE_BLOB_STORAGE_SAS_VALIDITY` | `60000` (one minute) |
| `UI_BAKERY_AZURE_BLOB_STORAGE_CHAT_SAS_VALIDITY` | `900000` (15 minutes) |

Selecting the Azure Bakery Storage provider with `BAKERY_STORAGE` is a different mode from selecting legacy `AZURE`; switching modes does not migrate existing references.

### Network access and AI routing

The storage endpoint must be reachable from the Java backend, users' browsers, the configured AI/model service, and the sandbox that downloads documents. Use an externally reachable HTTPS endpoint for production. An internal-only endpoint is also embedded in signed URLs and must be reachable by every consumer of those URLs.

Keep the system bucket/container private. Signed download links grant temporary read access to their holder; persistent unsigned object references do not make the bucket public. The backend checks project/environment access before signing project asset URLs.

On-prem installations using cloud AI continue uploading and resolving AI attachments through the existing cloud proxy. Self-hosted AI uses the installation's selected local asset-storage mode.
