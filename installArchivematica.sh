# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Autor: Lucir Vaz 
# Data: 2024-11-04
# Versão: 1.5
#
# Instruções iniciais
# Este script deverá ser executado após a instalação e configuração do archivematica com Docker

# Recebe pasta de destino da instalação como argumento
pastaLog=$1
if [ -z "$pastaLog" ]; then
    pastaLog="${HOME}/archivematica"
    mkdir -p $pastaLog
fi

# Definir variáveis de destino de processamento
pastaInstalacao="/opt"
pastaProcessamento="/mnt/rdcarq"
pastaInstallArchivematica="/opt/archivematica"

# Cria pasta destino archivematica
sudo mkdir -p $pastaInstallArchivematica 2>>$pastaLog/logInstallArchivematica.txt
echo "Pasta de instalação do Archivematica criada." 2>>$pastaLog/logInstallArchivematica.txt

# muda permissão da pasta de instalação
GROUP_DOCKER=$(getent group docker | cut -d: -f3)
if [ -z "$GROUP_DOCKER" ]; then
#    echo "Grupo 'docker' não encontrado. Certifique-se de que o Docker está instalado corretamente." >&2
    echo "Grupo 'docker' não encontrado. Certifique-se de que o Docker está instalado corretamente."  2>>$pastaLog/logInstallArchivematica.txt
    exit 1
fi
sudo chown $USER:$GROUP_DOCKER $pastaInstallArchivematica 2>>$pastaLog/logInstallArchivematica.txt
echo "Permissão da pasta de instalação do Archivematica ajustada." 2>>$pastaLog/logInstallArchivematica.txt

# Ajuste de memória para o ElasticSearch
VM.MAX_MAP_COUNT=$(sysctl -n vm.max_map_count)
if [ "${VM.MAX_MAP_COUNT}" -lt 262144 ]; then
    echo "Ajustando vm.max_map_count de ${VM.MAX_MAP_COUNT} para 262144..." 2>>$pastaLog/logInstallArchivematica.txt
    sudo sysctl -w vm.max_map_count=262144 2>>$pastaLog/logInstallArchivematica.txt
    echo "Parâmetro de memória do ElasticSearch ajustado." 2>>$pastaLog/logInstallArchivematica.txt

    # Adicionar ao sysctl.conf para manter a configuração após reinício
    echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf 2>>$pastaLog/logInstallArchivematica.txt
    echo "Parâmetro de memória do ElasticSearch adicionado ao sysctl.conf." 2>>$pastaLog/logInstallArchivematica.txt
fi
# Clonar o repositório do Archivematica
# Baixar o código do archivemática diretamente da plataforma gitHub
git clone https://github.com/artefactual/archivematica.git --recurse-submodules $pastaInstallArchivematica 2>>$pastaLog/logInstallArchivematica.txt
echo "Código do Archivematica baixado." 2>>$pastaLog/logInstallArchivematica.txt

echo "Ajuste dos parâmetros de instalação do Archivematica..." 2>>$pastaLog/logInstallArchivematica.txt
bash $pastaLog/arch/mescla_arch.sh "${pastaLog}" 2>>$pastaLog/logInstallArchivematica.txt
echo "Arquivos Docker Compose mesclados." 2>>$pastaLog/logInstallArchivematica.txt

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER 2>$pastaLog/logInstallArchivematica.txt
echo "Usuário adicionado ao grupo docker." 2>>$pastaLog/logInstallArchivematica.txt

# Definir permissões
chmod -R 755 $pastaInstallArchivematica 2>>$pastaLog/logInstallArchivematica.txt
chgrp -R docker $pastaInstallArchivematica 2>>$pastaLog/logInstallArchivematica.txt
echo "Permissões de acesso e execução definidas." 2>>$pastaLog/logInstallArchivematica.txt

# Fazer a conferência de versão para garantir a compatibilidade
cd $pastaInstallArchivematica
git checkout v1.18.0
git pull origin v1.18.0 

# Caso não tenha feito o git clone com o parâmetro: --recurse-submodules é possível adequar a versão 
git pull origin v1.18.0 --rebase 
git submodule update --init --recursive

# Criação dos volumes
cd $pastaInstallArchivematica/hack
make create-volumes
docker build
echo "Volumes do Archivematica criados." 2>>$pastaLog/logInstallArchivematica.txt

# Criar arquivo docker-compose.yaml do Archivematica
cd $pastaInstallArchivematica/hack
docker compose up -d
echo "Arquivo docker-compose.yml do Archivematica criado." 2>$pastaLog/logInstallArchivematica.txt

# Subir os containeres
docker-compose -f $pastaInstallArchivematica/hack/docker-compose.yml up -d

# Instalação das bases de dados
sudo make bootstrap
make restart-am-services
make initialize-search-index
make compile-translations
echo "Instalação do Archivematica concluída." 2>>$pastaLog/logInstallArchivematica.txt

return 0
# Fim do Script