#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Authenticate with Azure Key Vault using Service Principal or Managed Identity
if [ -n "$AZURE_CLIENT_ID" ] && [ -n "$AZURE_CLIENT_SECRET" ] && [ -n "$AZURE_TENANT_ID" ]; then
    # Login with Service Principal
    az login --service-principal \
             --username "$AZURE_CLIENT_ID" \
             --password "$AZURE_CLIENT_SECRET" \
             --tenant "$AZURE_TENANT_ID"
elif [ -n "$MSI_ENDPOINT" ]; then
    # Login with Managed Identity (for Azure VMs/Containers)
    az login --identity
else
    echo "No authentication method provided. Please set either Service Principal credentials or enable Managed Identity."
    exit 1
fi

# Set the subscription context if AZURE_SUBSCRIPTION_ID is provided
if [ -n "$AZURE_SUBSCRIPTION_ID" ]; then
    az account set --subscription "$AZURE_SUBSCRIPTION_ID"
fi

# Retrieve credentials and other configuration values from Azure Key Vault
DB_USERNAME=$(az keyvault secret show --name "db-username" --vault-name "$KEY_VAULT_NAME" --query "value" -o tsv)
DB_PASSWORD=$(az keyvault secret show --name "db-password" --vault-name "$KEY_VAULT_NAME" --query "value" -o tsv)
DB_URL=$(az keyvault secret show --name "db-url" --vault-name "$KEY_VAULT_NAME" --query "value" -o tsv)
DB_DRIVER=$(az keyvault secret show --name "db-driver" --vault-name "$KEY_VAULT_NAME" --query "value" -o tsv)

LDAP_USERNAME=$(az keyvault secret show --name "ldap-username" --vault-name "$KEY_VAULT_NAME" --query "value" -o tsv)
LDAP_PASSWORD=$(az keyvault secret show --name "ldap-password" --vault-name "$KEY_VAULT_NAME" --query "value" -o tsv)
LDAP_URL=$(az keyvault secret show --name "ldap-url" --vault-name "$KEY_VAULT_NAME" --query "value" -o tsv)
LDAP_BASEDN=$(az keyvault secret show --name "ldap-basedn" --vault-name "$KEY_VAULT_NAME" --query "value" -o tsv)

# Inject secrets and configuration values into bpm-platform.xml using sed
sed -i "s/\${DB_URL_PLACEHOLDER}/$DB_URL/" /camunda/conf/bpm-platform.xml
sed -i "s/\${DB_DRIVER_PLACEHOLDER}/$DB_DRIVER/" /camunda/conf/bpm-platform.xml
sed -i "s/\${DB_USER_PLACEHOLDER}/$DB_USERNAME/" /camunda/conf/bpm-platform.xml
sed -i "s/\${DB_PASS_PLACEHOLDER}/$DB_PASSWORD/" /camunda/conf/bpm-platform.xml
sed -i "s/\${LDAP_URL_PLACEHOLDER}/$LDAP_URL/" /camunda/conf/bpm-platform.xml
sed -i "s/\${LDAP_USER_PLACEHOLDER}/$LDAP_USERNAME/" /camunda/conf/bpm-platform.xml
sed -i "s/\${LDAP_PASS_PLACEHOLDER}/$LDAP_PASSWORD/" /camunda/conf/bpm-platform.xml
sed -i "s/\${LDAP_BASEDN_PLACEHOLDER}/$LDAP_BASEDN/" /camunda/conf/bpm-platform.xml

# Certficate Export
#export CAMUNDA_BASE_URL="https://rpa.camunda.environment.com"

# Export the secrets as environment variables
#export DB_USERNAME
#export DB_PASSWORD
#export LDAP_USER
#export LDAP_PASSWORD


# Start Camunda
exec catalina.sh run

