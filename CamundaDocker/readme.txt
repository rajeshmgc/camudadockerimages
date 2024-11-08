Build and Run the Docker Image

docker build -t camunda-with-keyvault-config .
Run the container with the required environment variables:

Subscrition 1
docker run -d -p 8080:8080 \
  -e AZURE_CLIENT_ID="your-client-id" \
  -e AZURE_CLIENT_SECRET="your-client-secret" \
  -e AZURE_TENANT_ID="your-tenant-id" \
  -e AZURE_SUBSCRIPTION_ID="subscription-id-1" \
  -e KEY_VAULT_NAME="keyvault-name-1" \
  camunda-with-keyvault-config

Subscrition 2
docker run -d -p 8080:8080 \
  -e AZURE_CLIENT_ID="your-client-id" \
  -e AZURE_CLIENT_SECRET="your-client-secret" \
  -e AZURE_TENANT_ID="your-tenant-id" \
  -e AZURE_SUBSCRIPTION_ID="subscription-id-1" \
  -e KEY_VAULT_NAME="keyvault-name-1" \
  camunda-with-keyvault-config



To configure Camunda in a Dockerized environment to use a custom hostname and SSL certificate (e.g., https://rpa.camunda.environment.com), you’ll need to set up HTTPS on Tomcat, which is Camunda’s application server. Here’s how to make these adjustments:

1. Obtain the SSL Certificate and Key
First, ensure you have:

An SSL certificate (cert.pem).
A private key file (privkey.pem).
If you’re using a certificate chain (often required for SSL), you may also have an intermediate.pem.

2. Convert SSL Certificate to PKCS12 Format (Required by Tomcat)
Tomcat typically requires certificates in PKCS12 format, so you may need to combine your certificate and key into a single .p12 file.

Run the following command to convert:

bash
Copy code
openssl pkcs12 -export -in cert.pem -inkey privkey.pem -out camunda-cert.p12 -name tomcat -CAfile intermediate.pem -caname root
This command will prompt you to create an export password for the .p12 file. 
Remember this password, as it will be needed in the configuration.

3. Configure Tomcat to Use SSL in server.xml
Edit the server.xml file, which is typically located in /camunda/conf/server.xml. You’ll add a <Connector> element to enable HTTPS with the custom domain and certificate.

Copy server.xml to your Docker context (if not already accessible).

Add the following Connector configuration for HTTPS:

xml
Copy code
<Connector port="443" protocol="org.apache.coyote.http11.Http11NioProtocol"
           maxThreads="150" SSLEnabled="true">
    <SSLHostConfig>
        <Certificate certificateKeystoreFile="/camunda/conf/camunda-cert.p12"
                     certificateKeystorePassword="your_export_password"
                     type="PKCS12" />
    </SSLHostConfig>
</Connector>
Replace "your_export_password" with the actual password you set when creating the .p12 file.
Remove or comment out any HTTP <Connector> blocks that use port 8080 if you want to serve only HTTPS traffic.

4. Update the Dockerfile to Copy the Certificate and Modify server.xml
Here’s the Dockerfile with modifications to:

Copy camunda-cert.p12 to the appropriate directory.
Copy the custom server.xml file with the HTTPS configuration




In Docker, you can specify a non-root user using the USER directive. By default, Docker containers often start as the root user for simplicity, but many official images (like Camunda’s) include a non-root user for security reasons. Here’s how to identify or specify a non-root user in a Docker image:

1. Check the Dockerfile of the Base Image
If you’re using a pre-built base image (e.g., camunda/camunda-bpm-platform:run-latest), you can often find the default non-root user by checking the Dockerfile for that image. Most official images document the default user setup.
In the case of Camunda’s Docker images, Camunda is set up to run as a non-root user by default. The Dockerfile for Camunda includes USER camunda as a non-root user.
2. Inspect the Running Container’s User
If the container is already running, you can check which user it’s running as:
bash
Copy code
docker exec -it <container_id> whoami
This command will return the username of the currently active user inside the container.
3. Switch to Non-Root User in Your Dockerfile
If your base image is configured to run as root and you want to switch to a non-root user, you can add a USER directive in your Dockerfile.
For example:
dockerfile
Copy code
# Create a new user (if not already created)
RUN useradd -m camunda

# Switch to the non-root user
USER camunda
4. List Users in the Container
You can list all users by running:
bash
Copy code
docker exec -it <container_id> cat /etc/passwd
This command will show all users and their UID/GID information. Look for a user like camunda or another non-root user (typically with UID/GID other than 0, which is reserved for root).
5. Verify the User's UID/GID
To check if the user is non-root, look at the UID (User ID) and GID (Group ID). The root user always has UID 0, so any user with a different UID is non-root.
You can check the UID and GID by running:
bash
Copy code
docker exec -it <container_id> id camunda
Example in the Dockerfile
In the case of the Camunda Dockerfile we used earlier, we switch to USER camunda after installing Git and Maven to ensure that the application doesn’t run as root:

dockerfile
Copy code
# Switch back to the default non-root user
USER camunda
This line ensures the remaining commands and the Camunda application itself will run as camunda, a non-root user, in the final container.
