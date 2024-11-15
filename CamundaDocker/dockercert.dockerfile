# Use the official Camunda BPM Platform image as the base
FROM camunda/camunda-bpm-platform:latest

# Install Azure CLI (required for accessing Key Vault)
RUN apt-get update && \
    apt-get install -y curl apt-transport-https && \
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    rm -rf /var/lib/apt/lists/*

# Copy bpm-platform.xml with placeholders
COPY bpm-platform.xml /camunda/conf/bpm-platform.xml

# Copy the SSL certificate (camunda-cert.p12) and server.xml
COPY camunda-cert.p12 /camunda/conf/camunda-cert.p12
COPY server.xml /camunda/conf/server.xml

# Copy the entrypoint script
COPY retrieve-azure-secrets.sh /usr/local/bin/retrieve-azure-secrets.sh
RUN chmod +x /usr/local/bin/retrieve-azure-secrets.sh

# Set the custom entrypoint script
ENTRYPOINT ["/usr/local/bin/retrieve-azure-secrets.sh"]
