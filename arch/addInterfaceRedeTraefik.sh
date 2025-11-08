~/bashrc

# docker adicionar interface rede traefik a imagem nginx
docker network connect traefik nginx_container

# comandos docker para criar rede e rodar container nginx
docker network create traefik
docker run -d --name nginx_container --network traefik nginx
# Fim do arquivo ~/bashrc

# inserir a interface de rede traefik no arquivo compose.yml
networks:
  traefik:
    external: true
# Fim do arquivo compose.yml

# comando bashrc para inserir a interface de rede traefik no compose.yml
echo -e "\nnetworks:\n  traefik:\n    external: true" >> compose.yml
# Fim do arquivo ~/bashrc

# unir os arquivos docker-compose.yml e interfaceRede.yml em um único arquivo compose_final.yml usando o yq
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' interfaceRede.yml docker-compose.yml > compose_final.yml
# Fim do arquivo ~/bashrc

# identificar se o comando yq está instalado
if ! command -v yq &> /dev/null
then
    echo "yq não está instalado. Por favor, instale o yq para continuar."
    exit 1
fi
# Fim do arquivo ~/bashrc

# instalar o yq via snap se não estiver instalado
if ! command -v yq &> /dev/null
then
    sudo snap install yq
fi
