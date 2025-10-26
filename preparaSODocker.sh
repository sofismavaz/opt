# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Autor: Lucir Vaz 
# Data: 2024-06-27
# Versão: 1.0
#
# Instruções iniciais
# Este script configura as variáveis de ambiente do ambiente operacional

# verifica se o grupo docker foi criado
if ! getent group docker > /dev/null 2>&1; then
    # Criar grupo docker se não existir
    sudo groupadd docker >> logInstallDocker.txt
    echo "Grupo docker criado." >> logInstallDocker.txt
else
    echo "Grupo docker já existe." >> logInstallDocker.txt
fi

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER >> logInstallDocker.txt
echo "Usuário adicionado ao grupo docker." >> logInstallDocker.txt

# Mudar grupo principal do usuário para docker
sudo usermod -g docker $USER >> logInstallDocker.txt
newgrp docker
echo "Grupo principal do usuário alterado para docker." >> logInstallDocker.txt

# Habilitar o serviço Docker para iniciar com o sistema
sudo systemctl enable docker
sudo systemctl status docker
echo "Serviço Docker habilitado para iniciar com o sistema." >> logInstallDocker.txt

# Verificar instalação
docker --version
docker compose version
echo "Verificação de instalação concluída." >> logInstallDocker.txt
echo "Instalação do Docker e Docker Compose concluída com sucesso." >> logInstallDocker.txt

return 0
# Fim do Script