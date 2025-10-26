# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Autor: Lucir Vaz 
# Data: 2024-06-27
# Versão: 1.0
#
# Instruções iniciais
# Este script deverá ser executado após a instalação e configuração do archivematica com Docker

# Limpar o arquivo de log anterior
> logInstallArchivematica.txt
# Criar pastas Archivematica
# mkdir -p /opt/archivematica/{db,storage-service,transfer-source,transfer-destination,workflow-service} >> logInstallArchivematica.txt 2>&1
# echo "Pastas do Archivematica criadas." >> logInstallArchivematica.txt

# Baixar o código do archivemática diretamente da plataforma gitHub
git clone https://github.com/artefactual/archivematica.git --recurse-submodules /opt/archivematica >> logInstallArchivematica.txt 2>&1
echo "Código do Archivematica baixado." >> logInstallArchivematica.txt

# Fazer a conferência de versão para garantir a compatibilidade
cd /opt/archivematica
git checkout v1.18.0
git pull origin v1.18.0 

# Caso não tenha feito o git clone com o parâmetro: --recurse-submodules é possível adequar a versão 
git pull origin v1.18.0 --rebase 
git submodule update --init --recursive

# Criação dos volumes
cd /opt/archivematica/hack
make create-volumes
make build

# Subir os containeres
docker compose up -d

# Instalação das bases de dados
sudo make bootstrap
make restart-am-services
echo "Instalação do Archivematica concluída." >> logInstallArchivematica.txt

# Fim do Script