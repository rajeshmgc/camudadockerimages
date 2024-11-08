#!/bin/bash

# Check if necessary arguments are provided
if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <KEYVAULT_NAME> <TENANT_ID> <CLIENT_ID> <CLIENT_SECRET> <SUBSCRIPTION_ID>"
  exit 1
fi

# Assign arguments to variables
KEYVAULT_NAME="$1"
TENANT_ID="$2"
CLIENT_ID="$3"
CLIENT_SECRET="$4"
SUBSCRIPTION_ID="$5"
RESOURCE="https://vault.azure.net"
AZURE_AUTH_URL="https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token"

# Fetch the access token using the Service Principal credentials
ACCESS_TOKEN=$(curl -s -X POST $AZURE_AUTH_URL \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "scope=$RESOURCE/.default" | jq -r '.access_token')

# Check if the ACCESS_TOKEN was successfully retrieved
if [ -z "$ACCESS_TOKEN" ]; then
    echo "Failed to retrieve access token from Azure AD"
    exit 1
fi

# Function to retrieve a secret from Key Vault
get_secret() {
    local secret_name=$1
    curl -s -X GET -H "Authorization: Bearer $ACCESS_TOKEN" \
        "https://${KEYVAULT_NAME}.vault.azure.net/secrets/${secret_name}?api-version=7.0" | jq -r '.value'
}

# Retrieve each secret and export as environment variables
export DB_USERNAME=$(get_secret "db-username")
export DB_PASSWORD=$(get_secret "db-password")
export LDAP_USER=$(get_secret "ldap-user")
export LDAP_PASSWORD=$(get_secret "ldap-password")

# Verify all secrets were retrieved
if [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ] || [ -z "$LDAP_USER" ] || [ -z "$LDAP_PASSWORD" ]; then
    echo "One or more secrets could not be retrieved. Please check Key Vault permissions."
    exit 1
fi

# Start the Camunda application with secrets available as environment variables
exec /camunda/bin/catalina.sh run
