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

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER >> logInstallDocker.txt
echo "Usuário adicionado ao grupo docker." >> logInstallDocker.txt

# Mudar grupo principal do usuário para docker
sudo usermod -g docker $USER >> logInstallDocker.txt
newgrp docker
echo "Grupo principal do usuário alterado para docker." >> logInstallDocker.txt
sudo systemctl enable docker
sudo systemctl status docker
echo "Serviço Docker habilitado para iniciar com o sistema." >> logInstallDocker.txt

# Verificar instalação
docker --version >> logInstallDocker.txt
docker compose version >> logInstallDocker.txt
echo "Verificação de instalação concluída." >> logInstallDocker.txt
echo "Instalação do Docker e Docker Compose concluída com sucesso." >> logInstallDocker.txt

# Fim do Script