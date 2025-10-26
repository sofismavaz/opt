# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Autor: Lucir Vaz 
# Data: 2024-06-27
# Versão: 1.0
#
# Instruções iniciais
# Este script deverá ser o primeiro a ser executado para preparação do ambiente Docker
# Instalará o Docker e Docker Compose na máquina.

# Limpar o arquivo de log anterior
> logInstallDocker.txt

# Preparação do sistema para instalação do Docker
sudo apt remove docker docker-engine docker.io containerd runc
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Adicionar repositório do Docker
echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list >> logInstallDocker.txt 2>&1
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >> logInstallDocker.txt 2>&1
echo "Docker e Docker Compose instalados." >> logInstallDocker.txt
# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER >> logInstallDocker.txt 2>&1
echo "Usuário adicionado ao grupo docker." >> logInstallDocker.txt

# Verificar instalação
docker --version >> logInstallDocker.txt 2>&1
docker compose version >> logInstallDocker.txt 2>&1
echo "Verificação de instalação concluída." >> logInstallDocker.txt 2>&1
echo "Instalação do Docker e Docker Compose concluída com sucesso." >> logInstallDocker.txt


