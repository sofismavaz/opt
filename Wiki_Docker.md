### Install Docker
o install Docker Engine on Ubuntu 22.04 using apt, follow these steps: Update the apt package index.
Código
￼
    sudo apt update
Install necessary packages to allow apt to use a repository over HTTPS:
Código
￼
    sudo apt install -y ca-certificates curl gnupg
Add Docker's official GPG key.
Código
￼
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
Add the Docker repository to apt sources:
Código
￼
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
Update the apt package index again to include the Docker repository: 
Código
￼
    sudo apt update
Install Docker Engine, CLI, Containerd, Docker Buildx, and Docker Compose: 
Código
￼
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
Verify the installation by running the hello-world image:
Código
￼
    sudo docker run hello-world
(Optional) Manage Docker as a non-root user:
To run Docker commands without sudo, add your user to the docker group:
Código
￼
    sudo usermod -aG docker $USER
Then, log out and log back in for the changes to take effect. You can verify this by running docker run hello-world without sudo.