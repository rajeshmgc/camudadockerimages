#!/bin/bash

# Fail the script on any error
set -e

# Check required environment variables
if [[ -z "$VAULT_URL" || -z "$VAULT_ROLE_ID" || -z "$VAULT_SECRET_ID" ]]; then
  echo "Error: VAULT_URL, VAULT_ROLE_ID, and VAULT_SECRET_ID must be set."
  exit 1
fi

# Authenticate with Vault using AppRole and get a token
VAULT_TOKEN=$(curl -s --request POST \
  --data "{\"role_id\": \"$VAULT_ROLE_ID\", \"secret_id\": \"$VAULT_SECRET_ID\"}" \
  "$VAULT_URL/v1/auth/approle/login" | jq -r .auth.client_token)

if [[ -z "$VAULT_TOKEN" ]]; then
  echo "Error: Failed to obtain Vault token"
  exit 1
fi

# Function to retrieve and export secrets from Vault
retrieve_secret() {
  local secret_path="$1"
  local key="$2"
  
  # Use the token to retrieve the secret
  secret_value=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_URL/v1/$secret_path" | jq -r ".data.data[\"$key\"]")

  if [[ -z "$secret_value" ]]; then
    echo "Error: Could not retrieve secret for key $key at path $secret_path"
    exit 1
  fi

  # Export the secret as an environment variable
  export "$key"="$secret_value"
}

# Retrieve DB credentials from Vault
retrieve_secret "$VAULT_DB_PATH" "DB_USERNAME"
retrieve_secret "$VAULT_DB_PATH" "DB_PASSWORD"
retrieve_secret "$VAULT_DB_PATH" "DB_URL"

# Retrieve LDAP credentials from Vault
retrieve_secret "$VAULT_LDAP_PATH" "LDAP_USERNAME"
retrieve_secret "$VAULT_LDAP_PATH" "LDAP_PASSWORD"
retrieve_secret "$VAULT_LDAP_PATH" "LDAP_URL"

# Optional: Print confirmation of loaded secrets
echo "Secrets successfully retrieved and exported."
