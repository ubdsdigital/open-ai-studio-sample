import argparse

from azure.identity import AzureDeveloperCliCredential
import urllib3


def update_redirect_uris(credential, app_id, uri):
    urllib3.request(
        "PATCH",
        f"https://graph.microsoft.com/v1.0/applications/{app_id}",
        headers={
            "Authorization": "Bearer "
            + credential.get_token("https://graph.microsoft.com/.default").token,
        },
        json={
            "web": {
                "redirectUris": [
                    "http://localhost:5000/.auth/login/aad/callback",
                    f"{uri}/.auth/login/aad/callback",
                ]
            }
        },
    )
### Adding a new update_redirect_uri function so we can use the client_id to add the redirect uri
    
def test_update_redirect_uris(credential, client_id, uri):
    urllib3.request(
        "PATCH",
        f"https://graph.microsoft.com/v1.0/applications/{client_id}",
        headers={
            "Authorization": "Bearer "
            + credential.get_token("https://graph.microsoft.com/.default").token,
        },
        json={
            "web": {
                "redirectUris": [
                    "http://localhost:5000/.auth/login/aad/callback",
                    f"{uri}/.auth/login/aad/callback",
                ]
            }
        },
    )

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Add a redirect URI to a registered application",
        epilog="Example: auth_update.py --appid 123 --uri https://abc.azureservices.net",
    )
    parser.add_argument(
        "--appid",
        required=False,
        help="Required. ID of the application to update.",
    )
    parser.add_argument(
        "--uri",
        required=False,
        help="Required. URI of the deployed application.",
    )
    # Add client_id as an argument
    parser.add_argument(
        "--clientid",
        required=False,
        help="Required. URI of the deployed application.",
    )
    args = parser.parse_args()

    credential = AzureDeveloperCliCredential()

    print(
        f"Updating application registration {args.appid} with redirect URI for {args.uri}"
    )
    # update_redirect_uris(credential, args.appid, args.uri)

# Add new print statement to show redirect uri is being added to app registration (via the clientid)
    print(
        f"Updating application registration {args.clientid} with redirect URI for {args.uri}"
    )
    # Call the test redirect uri
    test_update_redirect_uris(credential, args.client_id, args.uri)