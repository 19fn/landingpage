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
├── robots.txt        # Crawler rules and sitemap location
├── sitemap.xml       # Sitemap for search engines
├── infrastructure/   # Terraform roots: azure/ and aws/
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

The Terraform root module under `infrastructure/azure/` creates a resource group and an Azure StorageV2 account with Static Website enabled, then uploads the public root files plus all public assets under `assets/`.

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
cd infrastructure/azure
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with the subscription ID, desired resource-group name and location, and a globally unique lowercase Storage Account name.

Initialize, format, validate, and save a plan to `infrastructure/azure/tfplan.out`:

```sh
make azure-tf-plan
```

Review the plan output, then apply that exact saved plan:

```sh
make azure-tf-show
make azure-tf-apply
```

Terraform creates the resource group and Storage Account, enables the `$web` container, and uploads only:

- `index.html`
- `404.html`
- `styles.css`
- `app.js`
- `health.json`
- `robots.txt`
- `sitemap.xml`
- `assets/**`

Print the deployed URL after apply:

```sh
terraform output -raw website_url
```

Or run `make azure-tf-output`.

Terraform state and populated `*.tfvars` files are local and ignored by Git. Review every plan before applying because `terraform destroy` will remove the resource group and all resources created inside it.

## Manual Azure Deployment

Terraform is the recommended deployment path. For a manual deployment:

1. In the Azure portal, open the target Storage Account and enable **Static website** under **Data management**.
2. Set the index document name to `index.html` and the error document path to `404.html`.
3. Upload `index.html`, `404.html`, `styles.css`, `app.js`, `health.json`, `robots.txt`, `sitemap.xml`, and `assets/` to the `$web` container. The Static Website endpoint shown by Azure is the public URL.

With Azure CLI, after signing in and selecting the subscription, configure the static website and upload the public files with:

```sh
az storage blob service-properties update \
	--account-name <storage-account-name> \
	--static-website \
	--index-document index.html \
	--404-document 404.html \
	--auth-mode login

for file in index.html 404.html styles.css app.js health.json robots.txt sitemap.xml; do
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
make azure-deploy
```

The command reads the Storage Account name from Terraform output. To target an existing account explicitly, use `make azure-deploy AZURE_STORAGE_ACCOUNT=<storage-account-name>`.

Run `make help` to list all available commands, including validation, outputs, cleanup, and destruction.

## AWS Hosting (S3 + CloudFront)

`infrastructure/aws/` is a separate Terraform root with its own state that hosts the site on AWS. It creates:

- A private S3 bucket readable only by CloudFront (Origin Access Control), with the same public files uploaded
- A CloudFront distribution with HTTP→HTTPS 301, a CloudFront Function that 301s the apex to `www`, and `404.html` as the error page
- An ACM certificate (us-east-1) for `www` and the apex
- A Route 53 hosted zone with alias records for both hostnames
- A GitHub Actions OIDC provider and a deploy role limited to the bucket and cache invalidations

ACM validates the certificate through the Route 53 zone, so the zone must be delegated at the registrar before the certificate (and therefore CloudFront) can be created. Deploy in this order.

Sign in and create the local variables file:

```sh
aws login --profile personal
cd infrastructure/aws
cp terraform.tfvars.example terraform.tfvars
```

1. Create only the hosted zone and print its nameservers:

   ```sh
   terraform init
   terraform apply -target=aws_route53_zone.site
   terraform output route53_name_servers
   ```

2. At the domain registrar, replace the current nameservers with the four Route 53 nameservers. The site is unreachable from this point until step 3 finishes.

3. Plan and apply the full stack. The apply waits on certificate validation until the delegation propagates, then creates CloudFront and the DNS records:

   ```sh
   make aws-tf-plan
   make aws-tf-apply
   ```

4. Verify `https://www.thefnc.me/health.json`, that `http://www.thefnc.me` and `https://thefnc.me` both 301 to `https://www.thefnc.me`, and that a missing path returns the 404 page.

Redeploy content after changes with `make aws-deploy`. Run `make aws-tf-output` to show the bucket, distribution, and deploy role.

For the `Deploy (AWS)` workflow, add these variables to the `production` GitHub Environment from the Terraform outputs: `AWS_DEPLOY_ROLE_ARN`, `AWS_S3_BUCKET`, `AWS_CLOUDFRONT_DISTRIBUTION_ID`, and `AWS_CLOUDFRONT_DOMAIN` (hostname only, for example `www.thefnc.me`).

## CI/CD

GitHub Actions workflows are under `.github/workflows/`:

- `Test` validates static files and Terraform formatting/configuration on pull requests and pushes to `develop` or `main`.
- `Security` runs CodeQL, Gitleaks, and a weekly scheduled scan.
- `Deploy` publishes the static site on pushes to `main` or manual dispatch. It does not run Terraform apply.

`Deploy` picks the hosting target and calls the matching reusable workflow, `deploy-aws.yml` or `deploy-azure.yml`. Pushes use the repository variable `DEPLOY_TARGET` (`aws` or `azure`); switch hosting with `gh variable set DEPLOY_TARGET --body azure`. Manual runs from the Actions tab deploy to the target selected in the run form.

Configure a GitHub Environment named `production` before enabling deployment:

- Environment variable: `AZURE_STORAGE_ACCOUNT_NAME`
- Environment secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID`

The Azure service principal must use GitHub Actions OIDC federation and have `Storage Blob Data Contributor` on the Storage Account. Environment protection rules are recommended for deploy approvals.

For the `production` environment, configure the federated credential subject exactly as `repo:19fn/landingpage:environment:production`. The deployment identity does not need a client secret or Storage Account Contributor access because Terraform configures Static Website and the workflow only uploads public blobs.