# Federico Nicolas Cabrera Profile

A dependency-free personal work profile designed for Azure Storage Static Website hosting.

## Project Structure

```text
.
├── index.html        # Main profile page
├── 404.html          # Azure static website error page
├── styles.css        # Complete responsive visual system
├── app.js            # Navigation, filters, and progressive effects
├── Makefile          # Local, Terraform, and deployment commands
├── assets/           # Favicon and certification badge images
├── health.json       # Public deployment and reachability status
├── infrastructure/   # Azure Terraform root module
└── internal-docs/    # Private source material, ignored by Git
```

## Local Preview

From this directory, start a static HTTP server:

```sh
python3 -m http.server 8000
```

Open `http://localhost:8000`. The primary document is `index.html`; `404.html` is the Azure error document.

Check the static health endpoint at `http://localhost:8000/health.json`. In production, use `https://www.thefnc.me/health.json`.

The equivalent Make command is:

```sh
make run
```

Use a different port with `make run PORT=8080`.

## Deploy with Terraform

The Terraform root module under `infrastructure/terraform/` creates a resource group and an Azure StorageV2 account with Static Website enabled, then uploads the public root files plus all public assets under `assets/`.

### Prerequisites

- Terraform 1.5 or newer
- Azure CLI
- Permission to create resource groups and Storage Accounts in the target subscription

Authenticate and select the subscription:

```sh
az login
az account set --subscription <subscription-id>
```

Create the local variables file:

```sh
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with the subscription ID, desired resource-group name and location, and a globally unique lowercase Storage Account name.

Initialize, format, validate, and save a plan to `infrastructure/terraform/tfplan.out`:

```sh
make tf-plan
```

Review the plan output, then apply that exact saved plan:

```sh
make tf-show
make tf-apply
```

Terraform creates the resource group and Storage Account, enables the `$web` container, and uploads only:

- `index.html`
- `404.html`
- `styles.css`
- `app.js`
- `health.json`
- `assets/**`

Print the deployed URL after apply:

```sh
terraform output -raw website_url
```

Or run `make tf-output`.

Terraform state and populated `*.tfvars` files are local and ignored by Git. Review every plan before applying because `terraform destroy` will remove the resource group and all resources created inside it.

## Manual Azure Deployment

Terraform is the recommended deployment path. For a manual deployment:

1. In the Azure portal, open the target Storage Account and enable **Static website** under **Data management**.
2. Set the index document name to `index.html` and the error document path to `404.html`.
3. Upload `index.html`, `404.html`, `styles.css`, `app.js`, `health.json`, and `assets/` to the `$web` container. The Static Website endpoint shown by Azure is the public URL.

With Azure CLI, after signing in and selecting the subscription, configure the static website and upload the public files with:

```sh
az storage blob service-properties update \
	--account-name <storage-account-name> \
	--static-website \
	--index-document index.html \
	--404-document 404.html \
	--auth-mode login

for file in index.html 404.html styles.css app.js health.json; do
	az storage blob upload \
		--account-name <storage-account-name> \
		--container-name '$web' \
		--name "$file" \
		--file "$file" \
		--overwrite \
		--auth-mode login
done

az storage blob upload-batch \
	--account-name <storage-account-name> \
	--destination '$web' \
	--destination-path assets \
	--source assets \
	--overwrite \
	--auth-mode login
```

The `internal-docs/` directory contains resume and profile source material. It is ignored by Git and must not be uploaded to the public site.

After Terraform creates the Storage Account, redeploy only the current website content with Azure CLI:

```sh
make deploy
```

The command reads the Storage Account name from Terraform output. To target an existing account explicitly, use `make deploy STORAGE_ACCOUNT=<storage-account-name>`.

Run `make help` to list all available commands, including validation, outputs, cleanup, and destruction.