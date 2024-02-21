import argparse
import dataclasses
import time

from tqdm import tqdm
from azure.identity import AzureDeveloperCliCredential
from azure.core.credentials import AzureKeyCredential
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    SearchableField,
    SearchField,
    SearchFieldDataType,
    SemanticField,
    SemanticSettings,
    SemanticConfiguration,
    SearchIndex,
    PrioritizedFields,
    VectorSearch,
    VectorSearchAlgorithmConfiguration,
    HnswParameters
)
from azure.search.documents import SearchClient

def create_search_index(index_name, index_client):
    print(f"Ensuring search index {index_name} exists")
    if index_name not in index_client.list_index_names():
        index = SearchIndex(
            name=index_name,
            fields=[
                SearchableField(name="id", type="Edm.String", key=True),
                SearchableField(
                    name="content", type="Edm.String", analyzer_name="en.lucene"
                ),
                SearchableField(
                    name="title", type="Edm.String", analyzer_name="en.lucene"
                ),
                SearchableField(name="filepath", type="Edm.String"),
                SearchableField(name="url", type="Edm.String"),
                SearchableField(name="metadata", type="Edm.String"),
                SearchField(name="contentVector", type=SearchFieldDataType.Collection(SearchFieldDataType.Single),
                            hidden=False, searchable=True, filterable=False, sortable=False, facetable=False,
                            vector_search_dimensions=1536, vector_search_configuration="default"),
            ],
            semantic_settings=SemanticSettings(
                configurations=[
                    SemanticConfiguration(
                        name="default",
                        prioritized_fields=PrioritizedFields(
                            title_field=SemanticField(field_name="title"),
                            prioritized_content_fields=[
                                SemanticField(field_name="content")
                            ],
                        ),
                    )
                ]
            ),
            vector_search=VectorSearch(
                algorithm_configurations=[
                    VectorSearchAlgorithmConfiguration(
                        name="default",
                        kind="hnsw",
                        hnsw_parameters=HnswParameters(metric="cosine")
                    )
                ]
            )
        )
        print(f"Creating {index_name} search index")
        index_client.create_index(index)
    else:
        print(f"Search index {index_name} already exists")


def validate_index(index_name, index_client):
    for retry_count in range(5):
        stats = index_client.get_index_statistics(index_name)
        num_chunks = stats["document_count"]
        if num_chunks == 0 and retry_count < 4:
            print("Index is empty. Waiting 60 seconds to check again...")
            time.sleep(60)
        elif num_chunks == 0 and retry_count == 4:
            print("Index is empty. Please investigate and re-index.")
        else:
            print(f"The index contains {num_chunks} chunks.")
            average_chunk_size = stats["storage_size"] / num_chunks
            print(f"The average chunk size of the index is {average_chunk_size} bytes.")
            break


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Prepare documents by extracting content from PDFs, splitting content into sections and indexing in a search index.",
        epilog="Example: newindex.py --searchservice mysearch --index myindex",
    )
    parser.add_argument(
        "--tenantid",
        required=False,
        help="Optional. Use this to define the Azure directory where to authenticate)",
    )
    parser.add_argument(
        "--searchservice",
        help="Name of the Azure Cognitive Search service where content should be indexed (must exist already)",
    )
    parser.add_argument(
        "--index",
        help="Name of the Azure Cognitive Search index where content should be indexed (will be created if it doesn't exist)",
    )
    parser.add_argument(
        "--searchkey",
        required=False,
        help="Optional. Use this Azure Cognitive Search account key instead of the current user identity to login (use az login to set current user for Azure)",
    )
    parser.add_argument(
        "--embeddingendpoint",
        required=False,
        help="Optional. Use this OpenAI endpoint to generate embeddings for the documents",
    )
    args = parser.parse_args()

    # Use the current user identity to connect to Azure services unless a key is explicitly set for any of them
    azd_credential = (
        AzureDeveloperCliCredential()
        if args.tenantid == None
        else AzureDeveloperCliCredential(tenant_id=args.tenantid, process_timeout=60)
    )
    default_creds = azd_credential if args.searchkey == None else None
    search_creds = (
        default_creds if args.searchkey == None else AzureKeyCredential(args.searchkey)
    )


    print("Data preparation script started")
    print("Preparing data for index:", args.index)
    search_endpoint = f"https://{args.searchservice}.search.windows.net/"
    index_client = SearchIndexClient(endpoint=search_endpoint, credential=search_creds)
    search_client = SearchClient(
        endpoint=search_endpoint, credential=search_creds, index_name=args.index
    )
    
    create_search_index(args.index, index_client)
    print("Data preparation for index", args.index, "completed")
