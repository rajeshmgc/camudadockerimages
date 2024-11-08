docker build -t camunda-custom .


docker run -d \
    -e KEYVAULT_NAME="your-keyvault-name" \
    -e TENANT_ID="your-tenant-id" \
    -e CLIENT_ID="your-client-id" \
    -e CLIENT_SECRET="your-client-secret" \
    -e SUBSCRIPTION_ID="your-subscription-id" \
    camunda-custom \
    /camunda/retrieve_secret.sh "$KEYVAULT_NAME" "$TENANT_ID" "$CLIENT_ID" "$CLIENT_SECRET" "$SUBSCRIPTION_ID"