# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Autor: Lucir Vaz 
# Data: 2024-11-04
# Versão: 1.5
#
# Instruções iniciais
# Este script deverá ser executado após a instalação e configuração da aplicação Docker
# Criará a estrutura de pastas e configuração de arquivos necessária para o uso do Portainer e Traefik.

# Recebe pasta de destino da instalação como argumento
pastaLog=$1

if [ -z "$pastaLog" ]; then
    pastaLog="${HOME}/tmp"
    mkdir -p $pastaLog
fi

touch $pastaLog/logInstallPortTraefik.txt

# Definir variáveis de destino para instalação e processamento
pastaInstalacao="/opt"
pastaInstallTraefik="/opt/traefik"
pastaInstallPortainer="/opt/portainer"
pastaProcessamento="/mnt/rdcarq"

# Criar pastas Portainer
sudo mkdir -p $pastaInstallPortainer/data 2>$pastaLog/logInstallPortTraefik.txt
echo "Pasta portainer e data criados." 2>$pastaLog/logInstallPortTraefik.txt

# Criar diretórios principais
sudo mkdir -p $pastaInstallTraefik/{acme,config,dynamic,letsencrypt,logs} 2>$pastaLog/logInstallPortTraefik.txt
sudo mkdir -p $pastaInstallPortainer/data 2>$pastaLog/logInstallPortTraefik.txt
echo "Diretórios da estrutura de tráfego rede." 2>$pastaLog/logInstallPortTraefik.txt

# Criar volumes de processamento dos pacotes AIP, DIP, Backlog e Transferência
sudo mkdir -p $pastaProcessamento/rdcarq/transfer $pastaProcessamento/transfer-sistema $pastaProcessamento/rdcarq/repositorio/{aip,dip,backlog} 2>$pastaLog/logInstallPortTraefik.txt
sudo mkdir -p $pastaProcessamento/integracao 2>$pastaLog/logInstallPortTraefik.txt
sudo mkdir -p $pastaInstalacao/rsync 2>$pastaLog/logInstallPortTraefik.txt
echo "Volumes de processamento criados." 2>$pastaLog/logInstallPortTraefik.txt

# Definir permissões
sudo chmod -R 755 $pastaInstallTraefik $pastaInstallPortainer $pastaProcessamento/rdcarq 2>$pastaLog/logInstallPortTraefik.txt
sudo chgrp -R docker $pastaInstallTraefik $pastaInstallPortainer $pastaProcessamento $pastaProcessamento/integracao $pastaInstalacao/atom $pastaInstalacao/rsync 2>$pastaLog/logInstallPortTraefik.txt
sudo chmod 600 $pastaInstallTraefik/traefik/acme/acme.json 2>$pastaLog/logInstallPortTraefik.txt
echo "Permissões de acesso e execução definidas." 2>$pastaLog/logInstallPortTraefik.txt

# Criar arquivos de configuração do Portainer
cat <<EOL > $pastaLog/composePortainer.yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    labels:
      traefik.enable: "true"
      traefik.docker.network: "traefik"
      traefik.http.routers.portainer.rule: "Host(\`portainer.tre-ac.jus.br\`)"
      traefik.http.routers.portainer.entrypoints: "web"          # HTTP (80)
      # NADA de tls.* aqui
      traefik.http.routers.portainer.service: "portainer"
      traefik.http.services.portainer.loadbalancer.server.port: "9000"
      # (opcional) middlewares só se você quiser; evite middleware de redirecionamento p/ HTTPS
    networks:
      - traefik
    ports:
      - "9000:9000"
    restart: unless-stopped
networks:
  traefik:
    external: true

volumes:
  portainer_data:
EOL
echo "Arquivo docker compose portainer criado." 2>$pastaLog/logInstallPortTraefik.txt

# Adicionar conteúdo ao arquivo traefik.yml
cat <<EOL > $pastaLog/traefik.yml
api:
  dashboard: true
  insecure: true
  debug: false
entryPoints:
  web:
    address: ":80"
    # redirect all HTTP to HTTPS
    #http:
     #redirections:
      #  entryPoint:
      #   to: websecure
      #    scheme: https
      #    permanent: true
  websecure:
    address: ":443"
#serversTransport:
#  insecureSkipVerify: true
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: traefik
  file:
    directory: "etc/traefik/dynamic"
    watch: true

tls:
  options:
    default:
      minVersion: VersionTLS12
      maxVersion: VersionTLS13
      cipherSuites:
        - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
      curvePreferences:
        - CurveP521
        - CurveP384

log:
  level: INFO

accessLog:
  filePath: "/var/log/traefik/access.log"
  format: json
EOL
echo "Conteúdo adicionado ao arquivo traefik.yml." 2>$pastaLog/logInstallPortTraefik.txt

# Adicionar conteúdo ao arquivo dynamic.yml
cat <<EOL > $pastaLog/dynamic.yml
entryPoints:
  web:
    address: ":80"
    http:
      redirections:               # redireciona tudo p/ HTTPS (exceto ACME, Traefik cuida)
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"

certificatesResolvers:
  letsencrypt:
    acme:
      email: "serede@tre-ac.jus.br"
      storage: "./acme/acme.json"   # persista em volume
      httpChallenge:
        entryPoint: web            # desafio pela porta 80
EOL
echo "Conteúdo adicionado ao arquivo dynamic.yml." 2>$pastaLog/logInstallPortTraefik.txt

# Criar o arquivo *compose.yaml* no diretório *traefik*
cat <<EOL > $pastaLog/composeTraefik.yaml
services:
  traefik:
    image: traefik:v3.5
    container_name: traefik
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    networks:
      - traefik
    environment:
      - TRAEFIK_GLOBAL_SENDANONYMOUSUSAGE=true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${pastaInstallTraefik}/traefik.yml:/etc/traefik/traefik.yml:ro
      - ${pastaInstallTraefik}/dynamic:/etc/traefik/dynamic:ro
      - ${pastaInstallTraefik}/acme:/etc/traefik/acme
      - ${pastaInstallTraefik}/logs:/var/log/traefik
      - /etc/letsencrypt:/etc/letsencrypt:ro
networks:
  traefik:
    external: true
EOL

# Criar arquivo de configuração inicial
sudo touch $pastaInstallTraefik/acme/acme.json 2>$pastaLog/logInstallPortTraefik.txt
sudo mv $pastaLog/composePortainer.yaml $pastaInstallPortainer/compose.yaml
sudo mv $pastaLog/traefik.yml $pastaInstallTraefik/traefik.yml
sudo mv $pastaLog/dynamic.yml $pastaInstallTraefik/dynamic/dynamic.yml
sudo mv $pastaLog/composeTraefik.yaml $pastaInstallTraefik/compose.yaml

# Definir permissões dos arquivos criados
sudo chown -R root:docker $pastaInstallTraefik/acme/acme.json $pastaInstallPortainer/compose.yaml $pastaInstallTraefik/traefik.yml $pastaInstallTraefik/dynamic/dynamic.yml $pastaInstallTraefik/compose.yaml 2>$pastaLog/logInstallPortTraefik.txt
sudo chmod 600 $pastaInstallTraefik/acme/acme.json 2>$pastaLog/logInstallPortTraefik.txt

echo "Arquivos de configuração inicial criados." 2>$pastaLog/logInstallPortTraefik.txt

# Será necessário criar a conexão de rede para que a o serviço da imagem Docker possa trafegar os dados.
docker network create traefik 2>$pastaLog/logInstallPortTraefik.txt
echo "Rede Docker 'traefik' criada." 2>$pastaLog/logInstallPortTraefik.txt

# Levantar o serviço Traefik
docker compose -f $pastaInstallTraefik/compose.yaml up -d 2>$pastaLog/logInstallPortTraefik.txt
echo "Serviço Traefik iniciado." 2>$pastaLog/logInstallPortTraefik.txt  

# Levantar o serviço Portainer
docker compose -f $pastaInstallPortainer/compose.yaml up -d 2>$pastaLog/logInstallPortainer.txt
echo "Serviço Portainer iniciado." 2>$pastaLog/logInstallPortainer.txt
echo "Instalação do Portainer e Traefik concluída com sucesso." 2>$pastaLog/logInstallPortainer.txt

return 0