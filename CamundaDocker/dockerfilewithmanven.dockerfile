# Start from a base Camunda Docker image with Tomcat
FROM camunda/camunda-bpm-platform:tomcat-7.22.0

# Set the proxy environment variables for HTTP and HTTPS
ENV http_proxy=http://<your-proxy-server>:<proxy-port>
ENV https_proxy=http://<your-proxy-server>:<proxy-port>
ENV no_proxy="localhost,127.0.0.1,.mycompany.com"

# Set apt proxy if you are installing packages via apt-get
RUN echo "Acquire::http::Proxy \"http://<your-proxy-server>:<proxy-port>\";" >> /etc/apt/apt.conf.d/00proxy \
    && echo "Acquire::https::Proxy \"http://<your-proxy-server>:<proxy-port>\";" >> /etc/apt/apt.conf.d/00proxy


# Install Git, Maven, curl, and jq for building WAR files and fetching secrets
USER root
RUN apt-get update && \
    apt-get install -y git maven curl jq && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory and clone the repository
WORKDIR /tmp/ssc2
RUN git clone https://github.com/your-organization/ssc2-repo.git .

# Build all modules in the repository
RUN mvn clean package

# Copy each WAR file into the Camunda Tomcat webapps directory
# Adjust paths based on actual module names
RUN cp /tmp/ssc2/ssc1/target/ssc1.war /camunda/webapps/ 
RUN cp /tmp/ssc2/ssc2/target/ssc2.war /camunda/webapps/ 
RUN cp /tmp/ssc2/ssc3/target/ssc3.war /camunda/webapps/

# Clean up by removing the source code and Maven/Git installations
RUN rm -rf /tmp/ssc1 /tmp/ssc2 \
    && apt-get remove -y git maven \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Copy the secret retrieval script into the container
# Create a directory to hold the scripts and copy the retrieval script
RUN mkdir -p /camunda/scripts
COPY ./scripts/retrieve_secrets.sh /camunda/scripts/retrieve_secrets.sh

# Set environment variables for Azure Key Vault
//ENV AZURE_CLIENT_ID=<your-client-id>
//ENV AZURE_CLIENT_SECRET=<your-client-secret>
//ENV AZURE_TENANT_ID=<your-tenant-id>
//ENV KEY_VAULT_NAME=<your-key-vault-name>

# Make the secret retrieval script executable
RUN chmod +x /camunda/retrieve_secrets.sh

# Use an entrypoint to retrieve secrets, then start Camunda
ENTRYPOINT ["/bin/bash", "-c", "/camunda/retrieve_secrets.sh && /camunda/bin/catalina.sh run"]
