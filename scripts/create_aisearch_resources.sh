#!/bin/bash

# Grant execute permissions
chmod +x ./scripts/create_aisearch_resources.sh

# Names
resource_group_name="rg-rg-AZAI-DLUHC-Chatbot-Dev"
aisearch_resource_name="gptkb-j253mq57f222s"
aisearch_endpoint="https://${aisearch_resource_name}.search.windows.net"
openai_resource_name="cog-j253mq57f222s"
openai_endpoint="https://${openai_resource_name}.openai.azure.com"
emedding_model_name="embedding"
storage_account_name="azai2839304chatbot"
blob_container_name="content"

datasource_name="api-datasource-script"
skillset_name="api-skillset-script"
indexer_name="api-indexer-script"
index_name="api-index-script"

# Api-keys
aisearch_api_key=$(az search admin-key show --service-name $aisearch_resource_name --resource-group $resource_group_name --query "primaryKey" --output "tsv")
openai_api_key=$(az cognitiveservices account keys list --resource-group $resource_group_name --name $openai_resource_name --query "key1" --output "tsv")
blob_connection__string=$(az storage account show-connection-string --name $storage_account_name --resource-group $resource_group_name --output "tsv")

########################## Create Index
api_url_index="${aisearch_endpoint}/indexes?api-version=2023-10-01-preview"

request_body_index='{
  "name": "'"$index_name"'",
  "fields": [
    {
      "name": "id",
      "type": "Edm.String",
      "searchable": true,
      "filterable": false,
      "retrievable": true,
      "sortable": false,
      "facetable": false,
      "key": true,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "analyzer": "keyword",
      "dimensions": null,
      "vectorSearchProfile": null
    },
    {
      "name": "content",
      "type": "Edm.String",
      "searchable": true,
      "filterable": false,
      "retrievable": true,
      "sortable": false,
      "facetable": false,
      "key": false,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "analyzer": "en.lucene",
      "dimensions": null,
      "vectorSearchProfile": null
    },
    {
      "name": "title",
      "type": "Edm.String",
      "searchable": true,
      "filterable": false,
      "retrievable": true,
      "sortable": false,
      "facetable": false,
      "key": false,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "analyzer": "en.lucene",
      "dimensions": null,
      "vectorSearchProfile": null
    },
    {
      "name": "filepath",
      "type": "Edm.String",
      "searchable": true,
      "filterable": false,
      "retrievable": true,
      "sortable": false,
      "facetable": false,
      "key": false,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "analyzer": null,
      "dimensions": null,
      "vectorSearchProfile": null
    },
    {
      "name": "url",
      "type": "Edm.String",
      "searchable": true,
      "filterable": false,
      "retrievable": true,
      "sortable": false,
      "facetable": false,
      "key": false,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "analyzer": null,
      "dimensions": null,
      "vectorSearchProfile": null
    },
    {
      "name": "metadata",
      "type": "Edm.String",
      "searchable": true,
      "filterable": false,
      "retrievable": true,
      "sortable": false,
      "facetable": false,
      "key": false,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "analyzer": null,
      "dimensions": null,
      "vectorSearchProfile": null
    },
    {
      "name": "contentVector",
      "type": "Collection(Edm.Single)",
      "searchable": true,
      "filterable": false,
      "retrievable": true,
      "sortable": false,
      "facetable": false,
      "key": false,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "analyzer": null,
      "dimensions": 1536,
      "vectorSearchProfile": "myHnswProfile"
    },
    {
      "name": "parent_id",
      "type": "Edm.String",
      "searchable": true,
      "filterable": true,
      "retrievable": true,
      "sortable": false,
      "facetable": false,
      "key": false,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "analyzer": null,
      "dimensions": null,
      "vectorSearchProfile": null
    }
  ],
  "semantic": {
    "configurations": [
        {
            "name": "semanticConfiguration",
            "prioritizedFields": {
                "titleField": {
                    "fieldName": "title"
                },
                "prioritizedContentFields": [
                    {
                        "fieldName": "content"
                    }
                ]
            }
        }
    ]
  },
  "vectorSearch": {
    "profiles": [
      {
        "name": "myHnswProfile",
        "algorithm": "myHnsw",
        "vectorizer": "myOpenAi"
      }
    ],
    "algorithms": [
      {
        "name": "myHnsw",
        "kind": "hnsw",
        "hnswParameters": {
          "m": 4,
          "metric": "cosine",
          "efConstruction": 400,
          "efSearch": 500
        }
      }
    ],
    "vectorizers": [
      {
        "name": "myOpenAi",
        "kind": "azureOpenAI",
        "azureOpenAIParameters": {
          "resourceUri": "'"$openai_endpoint"'",
          "deploymentId": "'"$emedding_model_name"'",
          "apiKey": "'"$openai_api_key"'"
        }
      }
    ]
  }
}'

# API call to create the index
curl -X POST -H "api-key: $aisearch_api_key" -H "Content-Type: application/json" -d "$request_body_index" "$api_url_index"

########################## Create Datasource (Blob)
api_url_datasource_blob="${aisearch_endpoint}/datasources?api-version=2023-11-01"
request_body_datasource='{
  "name": "'"${datasource_name}"'", 
  "description": "data source from script", 
  "type": "azureblob", 
  "credentials": {
    "connectionString": "'"${blob_connection__string}"'"
  },
  "container": {
    "name": "'"${blob_container_name}"'", 
    "query": ""
  }
}'

# API call to create the datasource
curl -X POST -H "api-key: $aisearch_api_key" -H "Content-Type: application/json" -d "$request_body_datasource" "$api_url_datasource_blob"

########################## Create Skillset
api_url_skillset="${aisearch_endpoint}/skillsets?api-version=2023-10-01-Preview"
request_body_skillset='
{
  "name": "'"$skillset_name"'",
  "description": "From a bash script. Skillset to chunk documents and generate embeddings",
  "skills": [
    {
      "@odata.type": "#Microsoft.Skills.Text.AzureOpenAIEmbeddingSkill",
      "name": "#1",
      "description": null,
      "context": "/document/pages/*",
      "resourceUri": "'"$openai_endpoint"'",
      "apiKey": "'"$openai_api_key"'",
      "deploymentId": "'"$emedding_model_name"'",
      "inputs": [
        {
          "name": "text",
          "source": "/document/pages/*"
        }
      ],
      "outputs": [
        {
          "name": "embedding",
          "targetName": "vector"
        }
      ],
      "authIdentity": null
    },
    {
      "@odata.type": "#Microsoft.Skills.Text.SplitSkill",
      "name": "#2",
      "description": "Split skill to chunk documents",
      "context": "/document",
      "defaultLanguageCode": "en",
      "textSplitMode": "pages",
      "maximumPageLength": 2000,
      "pageOverlapLength": 500,
      "maximumPagesToTake": 0,
      "inputs": [
        {
          "name": "text",
          "source": "/document/content"
        }
      ],
      "outputs": [
        {
          "name": "textItems",
          "targetName": "pages"
        }
      ]
    }
  ],
  "indexProjections": {
    "selectors": [
      {
        "targetIndexName": "'"$index_name"'",
        "parentKeyFieldName": "parent_id",
        "sourceContext": "/document/pages/*",
        "mappings": [
          {
            "name": "content",
            "source": "/document/pages/*",
            "sourceContext": null,
            "inputs": []
          },
          {
            "name": "contentVector",
            "source": "/document/pages/*/vector",
            "sourceContext": null,
            "inputs": []
          },
          {
            "name": "title",
            "source": "/document/metadata_storage_name",
            "sourceContext": null,
            "inputs": []
          },
          {
            "name": "filepath",
            "source": "/document/metadata_storage_path",
            "sourceContext": null,
            "inputs": []
          },
          {
            "name": "metadata",
            "source": "/document/metadata_storage_content_type",
            "sourceContext": null,
            "inputs": []
          }
        ]
      }
    ],
    "parameters": {
      "projectionMode": "skipIndexingParentDocuments"
    }
  }
}'
# API call to create the skillset
curl -X POST -H "api-key: $aisearch_api_key" -H "Content-Type: application/json" -d "$request_body_skillset" "$api_url_skillset"

########################## Create Indexer
api_url_indexer="${aisearch_endpoint}/indexers?api-version=2023-11-01"
request_body_indexer='{
    "name" : "'"${indexer_name}"'",
    "dataSourceName" : "'"${datasource_name}"'",
    "skillsetName": "'"${skillset_name}"'",
    "targetIndexName" : "'"${index_name}"'",
    "parameters": {
    "batchSize": null,
    "maxFailedItems": null,
    "maxFailedItemsPerBatch": null,
    "base64EncodeKeys": null,
    "configuration": {
        "dataToExtract": "contentAndMetadata"
      }
    },
    "schedule" : {
        "interval": "P1D",
        "startTime": "2024-02-25T06:00:00.00Z"
    },
    "fieldMappings" : []
}'

# API call to create the indexer
curl -X POST -H "api-key: $aisearch_api_key" -H "Content-Type: application/json" -d "$request_body_indexer" "$api_url_indexer"