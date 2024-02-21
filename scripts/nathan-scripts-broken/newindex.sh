 #!/bin/sh

. ./scripts/loadenv.sh

echo 'Running "newindex.py"'
./.venv/bin/python ./scripts/nathan-scripts/newindex.py --searchservice "$AZURE_SEARCH_SERVICE" --index "$AZURE_SEARCH_INDEX" --tenantid "$AZURE_TENANT_ID" --embeddingendpoint "$AZURE_OPENAI_EMBEDDING_ENDPOINT"
