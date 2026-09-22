# Federico Cabrera Profile

A dependency-free personal work profile designed for Azure Storage Static Website hosting.

## Project Structure

```text
.
├── index.html        # Main profile page
├── 404.html          # Azure static website error page
├── styles.css        # Complete responsive visual system
├── app.js            # Navigation, filters, and progressive effects
├── assets/img/       # Certification badge images
└── internal-docs/    # Private source material, ignored by Git
```

## Local Preview

From this directory, start a static HTTP server:

```sh
python3 -m http.server 8000
```

Open `http://localhost:8000`. The primary document is `index.html`; `404.html` is the Azure error document.

## Publish to Azure Storage Static Website

1. In the Azure portal, open the target Storage Account and enable **Static website** under **Data management**.
2. Set the index document name to `index.html` and the error document path to `404.html`.
3. Upload `index.html`, `404.html`, `styles.css`, `app.js`, and `assets/img/` to the `$web` container. The Static Website endpoint shown by Azure is the public URL.

With Azure CLI, after signing in and selecting the subscription, configure the static website and upload the public files with:

```sh
az storage blob service-properties update \
	--account-name <storage-account-name> \
	--static-website \
	--index-document index.html \
	--404-document 404.html \
	--auth-mode login

for file in index.html 404.html styles.css app.js; do
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
	--destination-path assets/img \
	--source assets/img \
	--overwrite \
	--auth-mode login
```

The `internal-docs/` directory contains resume and profile source material. It is ignored by Git and must not be uploaded to the public site.