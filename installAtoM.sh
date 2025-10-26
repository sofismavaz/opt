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

echo "Código do AtoM baixado." >> logInstallAtoM.txt
cat <<EOL > /opt/atom/docker/compose.yaml 2>> logInstallAtoM.txt
services:
  atom:
    image: docker-atom
    pull_policy: never
    environment:
      ATOM_COVERAGE: "${\ATOM_COVERAGE\:\-\false}"  # em caso de cópia, retirar os '\'
      
      # AtoM and AtoM worker
      ATOM_DEVELOPMENT_MODE: "on"
      ATOM_ELASTICSEARCH_HOST: "elasticsearch"
      ATOM_MEMCACHED_HOST: "memcached"
      ATOM_GEARMAND_HOST: "gearmand"
      ATOM_MYSQL_DSN: "mysql:host=percona;port=3306;dbname=atom;charset=utf8mb4"
      ATOM_MYSQL_USERNAME: "atom"
      ATOM_MYSQL_PASSWORD: "atom_12345"
      NODE_ENV: "development"
    volumes:
      - "composer_deps:/atom/src/vendor/composer"
      - "npm_deps:/atom/src/node_modules"
      - "/opt/atom:/atom/src:rw"
      - "/opt/atom/docker/etc/php/xdebug.ini:/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini:ro"
      - "/mnt/atom/uploads:/usr/share/nginx/atom/uploads"
      - "/mnt/atom/downloads:/usr/share/nginx/atom/downloads"
      - "/mnt/atom/config:/usr/share/nginx/atom/config"
      - "/mnt/atom/plugins/:/usr/share/nginx/atom/plugins/"
    networks:
      - default
  atom_worker:
    image: docker-atom_worker
    pull_policy: never
    command: worker
    environment:
      ATOM_COVERAGE: "${\ATOM_COVERAGE\:\-\false}"  # em caso de cópia, retirar os '\'
      
      # AtoM and AtoM worker
      ATOM_DEVELOPMENT_MODE: "on"
      ATOM_ELASTICSEARCH_HOST: "elasticsearch"
      ATOM_MEMCACHED_HOST: "memcached"
      ATOM_GEARMAND_HOST: "gearmand"
      ATOM_MYSQL_DSN: "mysql:host=percona;port=3306;dbname=atom;charset=utf8mb4"
      ATOM_MYSQL_USERNAME: "atom"
      ATOM_MYSQL_PASSWORD: "atom_12345"
      NODE_ENV: "development"
    depends_on:
      - gearmand
      - percona
    restart: on-failure:5
    volumes:
      - "composer_deps:/atom/src/vendor/composer"
      - "npm_deps:/atom/src/node_modules"
      - "/opt/atom:/atom/src:rw"
      - "/mnt/atom/uploads:/usr/share/nginx/atom/uploads"
      - "/mnt/atom/downloads:/usr/share/nginx/atom/downloads"
      - "/mnt/atom/config:/usr/share/nginx/atom/config"
      - "/mnt/atom/plugins/:/usr/share/nginx/atom/plugins/"
      - "/mnt/integracao:/data"
    networks:
      - default
  nginx:
    image: nginx:latest
    volumes:
      - composer_deps:/atom/src/vendor/composer
      - npm_deps:/atom/src/node_modules
      - /opt/atom:/atom/src:ro
      - /opt/atom/docker/etc/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik"

      # HTTP -> redirect para HTTPS (middleware definido no dynamic.yml do Traefik)
      - "traefik.http.routers.atom-http.rule=Host(\`atom.tre-ac.com.br\`)"  # em caso de cópia, retirar os '\'
      - "traefik.http.routers.atom-http.entrypoints=websecure"
      - "traefik.http.routers.atom-http.tls=true"

      - "traefik.http.services.atom.loadbalancer.server.port=80"
      - "traefik.http.routers.atom.middlewares=atom-sec"
      - "traefik.http.routers.atom.tls.options=secure@file"
      # Segurança
      - "traefik.http.middlewares.atom-sec.headers.stsSeconds=63072000"
      - "traefik.http.middlewares.atom-sec.headers.stsIncludeSubdomains=true"
      - "traefik.http.middlewares.atom-sec.headers.stsPreload=true"
      
    networks:
      - default
      - traefik

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch-oss:7.10.2
    environment:
      # Elasticsearch
      bootstrap.memory_lock: "true"
      cluster.routing.allocation.disk.threshold_enabled: "false"
      discovery.type: single-node
      ES_JAVA_OPTS: "-Xms640m -Xmx640m"
      bootstrap.system_call_filter : "false"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    expose:
      - "9200"
    networks:
      - default
  :
    image: percona:8.0
    environment:
      # MySQL
      MYSQL_ROOT_PASSWORD: "my-secret-pw"
      MYSQL_DATABASE: "atom"
      MYSQL_USER: "atom"
      MYSQL_PASSWORD: "atom_12345"
    volumes:
      - percona_data:/var/lib/mysql:rw
      - /opt/atom/docker/etc/mysql/mysqld.cnf:/etc/my.cnf.d/mysqld.cnf:ro
    expose:
      - "3306"
    networks:
      - default

  memcached:
    image: memcached
    command: -p 11211 -m 128 -u memcache
    expose:
      - "11211"
    networks:
      - default

  gearmand:
    image: artefactual/gearmand
    expose:
      - "4730"
    networks:
      - default

  rsync_server:
    image: rsync:latest
    container_name: rsync_server
    pull_policy: never
    restart: unless-stopped
    #ports:
    #  - "2222:22"
    volumes:
      - ssh-host-keys:/ssh_host_keys
      - /mnt/integracao:/data
    environment:
      - SSH_AUTH_KEY_1=xxxxxxxxx
    networks:
      - default
      - integracao

volumes:
  elasticsearch_data:
  percona_data:
  composer_deps:
  npm_deps:
  ssh-host-keys:

# definição dos networks e volumes
networks:
  default:
  traefik:
    external:
      name: traefik
  integracao:
    external:
      name: integracao
EOL

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