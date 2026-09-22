# Federico Cabrera Profile

A dependency-free personal work profile designed for Azure Storage Static Website hosting.

## Local Preview

From this directory, start a static HTTP server:

```sh
python3 -m http.server 8000
```

Open `http://localhost:8000`. The primary document is `index.html`; `404.html` is the Azure error document.

## Publish to Azure Storage Static Website

1. In the Azure portal, open the target Storage Account and enable **Static website** under **Data management**.
2. Set the index document name to `index.html` and the error document path to `404.html`.
3. Upload `index.html`, `404.html`, `styles.css`, and `app.js` to the `$web` container. The Static Website endpoint shown by Azure is the public URL.

With Azure CLI, after signing in and selecting the subscription, upload the files with:

```sh
az storage blob upload-batch \
	--account-name <storage-account-name> \
	--destination '$web' \
	--source . \
	--pattern '*.html' \
	--pattern '*.css' \
	--pattern '*.js' \
	--auth-mode login
```

The `docs/` directory contains source material and is intentionally not part of the published site.