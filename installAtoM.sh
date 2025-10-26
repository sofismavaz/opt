# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Autor: Lucir Vaz 
# Data: 2024-06-27
# Versão: 1.0
#
# Instruções iniciais
# Este script instalará o AtoM (Access to Memory) utilizando Docker
# Limpar o arquivo de log anterior
> logInstallAtoM.txt

# Baixar o código do AtoM diretamente da plataforma gitHub
### Instalação do AtoM DOCKER COMPOSE
git clone -b qa/2.x https://github.com/artefactual/atom.git /opt/atom
cd /opt/atom
git checkout v2.10.0
git pull origin v2.10.0

# Criar conteineres
cd /opt/atom/docker
docker compose -f docker-compose.dev.yml up -d

# Inicializar banco de dados
docker compose exec atom php -d memory_limit=-1 symfony tools:purge --demo

# Compilar os temas
docker compose exec atom npm install
docker compose exec atom npm run build

# Reiniciar o atom_worker
docker compose restart atom_worker

#Testar
#http://localhost:63001 ou http://10.168.122.6:63001

echo "Instalação do AtoM concluída." >> logInstallAtoM.txt
# Fim do Script