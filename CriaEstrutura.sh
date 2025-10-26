# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Script para criar a estrutura de diretórios e arquivos iniciais da instalação do Portainer e Traefik
# Autor: Lucir Vaz 
# Data: 2024-06-27
# Versão: 1.0

# Instruções iniciais
# Este script deverá ser executado após a instalação e configuração da aplicação Docker
# Criará a estrutura de pastas e configuração de arquivos necessária para o uso do Portainer e Traefik.

# Limpar o arquivo de log anterior
> logInstalacao.txt

# Criar pastas Portainer
mkdir -p /opt/portainer/data >> logInstalacao.txt 2>&1
echo "Pasta portainer criados." >> logInstalacao.txt

# Criar arquivos de configuração do Portainer
touch /opt/portainer/compose.yaml >> logInstalacao.txt 2>&1
echo "Arquivo docker-compose.yaml criado." >> logInstalacao.txt

cat <<EOL > /opt/portainer/compose.yaml 2>> logInstalacao.txt
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
echo "Arquivo compose portainer criado." >> logInstalacao.txt

# Criar diretórios principais
#mkdir -p /opt/traefik/{acme,config,dynamic,letsencrypt,logs} > /dev/null 2>&1
mkdir -p /opt/traefik/{acme,config,dynamic,letsencrypt,logs} >> logInstalacao.txt 2>&1
echo "Diretórios da estrutura de tráfego rede." >> logInstalacao.txt

# Criar arquivo de configuração inicial
touch /opt/traefik/acme/acme.json /opt/traefik/dynamic/dynamic.yml /opt/traefik/traefik.yml /opt/traefik/compose.yaml >> logInstalacao.txt
echo "Arquivos de configuração inicial criados." >> logInstalacao.txt

# Adicionar conteúdo ao arquivo traefik.yml
cat <<EOL > /opt/traefik/traefik.yml 2>> logInstalacao.txt
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
echo "Conteúdo adicionado ao arquivo traefik.yml." >> logInstalacao.txt

# Adicionar conteúdo ao arquivo dynamic.yml
cat <<EOL > /opt/traefik/dynamic/dynamic.yml 2>> logInstalacao.txt
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
echo "Conteúdo adicionado ao arquivo dynamic.yml." >> logInstalacao.txt

# Criar o arquivo *compose.yaml* no diretório *traefik*
cat <<EOL > /opt/traefik/compose.yaml 2>> logInstalacao.txt
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
      - /opt/traefik/traefik.yml:/etc/traefik/traefik.yml:ro
      - /opt/traefik/dynamic:/etc/traefik/dynamic:ro
      - /opt/traefik/acme:/etc/traefik/acme
      - /opt/traefik/logs:/var/log/traefik
      - /etc/letsencrypt:/etc/letsencrypt:ro
networks:
  traefik:
    external: true
EOL

# Definir permissões
chmod -R 755 /opt/traefik /opt/portainer >> logInstalacao.txt 2>&1
chgrp -R docker /opt/traefik /opt/portainer >> logInstalacao.txt 2>&1
chmod 600 /opt/traefik/acme/acme.json >> logInstalacao.txt 2>&1
echo "Permissões de acesso e execução definidas." >> logInstalacao.txt

