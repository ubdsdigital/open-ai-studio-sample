import argparse

from azure.identity import AzureDeveloperCliCredential
import azure.identity as id
import urllib3


def update_redirect_uris(credential, app_id, uri):
    headers = urllib3.HTTPHeaderDict()
    headers.add("Content-Type", "application/json")
    headers.add("Authorization", "Bearer " + credential.get_token("https://graph.microsoft.com/.default").token)

    try:
        resp = urllib3.request(
            "PATCH",
            f"https://graph.microsoft.com/v1.0/applications/{app_id}",
            # headers={
            #     "Authorization": "Bearer "
            #     + credential.get_token("https://graph.microsoft.com/.default").token,
            # },
            headers=headers,
            json={
                "web": {
                    "redirectUris": [
                        "http://localhost:5000/.auth/login/aad/callback",
                        f"{uri}/.auth/login/aad/callback",
                    ]
                }
            },
        )
    except Exception as e:
        print(f"Exception: {e.__doc__}")

    # print(resp.status)
    # # 200
    # print(resp.data)
    # # b"{\n  "origin": "104.232.115.37"\n}\n"
    # print(resp.headers)
    # # HTTPHeaderDict({"Content-Length": "32", ...})


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
    args = parser.parse_args()

    credential = AzureDeveloperCliCredential()

# Testing to see what the credential is
    try:
        print(f"Here is the credential {credential}")
    except:
        print("An exception occured")

# Another credential test
    try: 
        credential = id.AzureDeveloperCliCredential()
    except id.CredentialUnavailableError:
        print("Credential Unavailable Error")
    except id.CredentialAuthenticationError:
        print("ClientAuthenticationError")

    print(
        f"Updating application registration {args.appid} with redirect URI for {args.uri}"
    )
    update_redirect_uris(credential, args.appid, args.uri)
