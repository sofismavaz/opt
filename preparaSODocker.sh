# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Autor: Lucir Vaz 
# Data: 2024-11-04
# Versão: 1.5
#
# Instruções iniciais
# Este script configura as variáveis de ambiente do ambiente operacional

# Recebe pasta de destino da instalação como argumento
pastaLog=$1
if [ -z "$pastaLog" ]; then
    pastaLog="${HOME}/archivematica"
    mkdir -p $pastaLog
fi
touch $pastaLog/logPreparaSODocker.txt

# verifica se o grupo docker foi criado
if [ ! getent group docker ]; then
    # Criar grupo docker se não existir
    sudo groupadd docker 2>$pastaLog/logPreparaSODocker.txt
    echo "Grupo docker criado." 2>$pastaLog/logPreparaSODocker.txt
else
    echo "Grupo docker já existe." 2>$pastaLog/logPreparaSODocker.txt
fi

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER 2>$pastaLog/logPreparaSODocker.txt
echo "Usuário adicionado ao grupo docker." 2>$pastaLog/logPreparaSODocker.txt

# Mudar grupo principal do usuário para docker
sudo usermod -g docker $USER 2>$pastaLog/logPreparaSODocker.txt
echo "Grupo principal do usuário alterado para docker." 2>$pastaLog/logPreparaSODocker.txt

# Habilitar o serviço Docker para iniciar com o sistema
sudo systemctl enable docker
sudo systemctl status docker
echo "Serviço Docker habilitado para iniciar com o sistema." 2>$pastaLog/logPreparaSODocker.txt

# Verificar instalação
docker --version
docker compose version
echo "Verificação de instalação concluída." 2>$pastaLog/logPreparaSODocker.txt
echo "Instalação do Docker e Docker Compose concluída com sucesso." 2>$pastaLog/logPreparaSODocker.txt

return 0
# Fim do Script