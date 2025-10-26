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

# Ajuste de memória para o ElasticSearch
sudo sysctl -w vm.max_map_count=262144 >> logInstallArchivematica.txt 2>&1
echo "Parâmetro de memória do ElasticSearch ajustado." >> logInstallArchivematica.txt

# Adicionar ao sysctl.conf para manter a configuração após reinício
sudo echo "vm.max_map_count=262144" >> /etc/sysctl.conf 2>> logInstallArchivematica.txt
echo "Parâmetro de memória do ElasticSearch adicionado ao sysctl.conf." >> logInstallArchivematica.txt

# Baixar o código do archivemática diretamente da plataforma gitHub
git clone https://github.com/artefactual/archivematica.git --recurse-submodules /opt/archivematica >> logInstallArchivematica.txt 2>&1
echo "Código do Archivematica baixado." >> logInstallArchivematica.txt

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER >> logInstallArchivematica.txt 2>&1
echo "Usuário adicionado ao grupo docker." >> logInstallArchivematica.txt

# Definir permissões
chmod -R 755 /opt/archivematica >> logInstallArchivematica.txt 2>> logInstallArchivematica.txt
chgrp -R docker /opt/archivematica >> logInstallArchivematica.txt 2>> logInstallArchivematica.txt
echo "Permissões de acesso e execução definidas." >> logInstallArchivematica.txt

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
echo "Volumes do Archivematica criados." >> logInstallArchivematica.txt

# Criar arquivo docker-compose.yaml do Archivematica
cd /opt/archivematica/hack
cat <<EOL > compose.yaml 2>> logInstallArchivematica.txt
services:
  mysql:
    image: "percona/percona-server:8.0.43-34"
    command: "--character-set-server=utf8mb4 --collation-server=utf8mb4_0900_ai_ci"
    environment:
      MYSQL_ROOT_PASSWORD: "12345"
      # These are used in the settings.testmysql modules
      MYSQL_USER: "archivematica"
      MYSQL_PASSWORD: "demo"
    volumes:
      - "./etc/mysql/tuning.cnf:/etc/my.cnf.d/tuning.cnf:ro"
      - "mysql_data:/var/lib/mysql"
    expose:
      - "3306"
    cap_add:
      - "SYS_NICE"
    networks:
      - default

  elasticsearch:
    image: "docker.elastic.co/elasticsearch/elasticsearch:8.19.3"
    environment:
      - "cluster.name=am-cluster"
      - "node.name=am-node"
      - "network.host=0.0.0.0"
      - "bootstrap.memory_lock=true"
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - "cluster.routing.allocation.disk.threshold_enabled=${\ELASTICSEARCH_DISK_THRESHOLD_ENABLED\:\-\true}"  # em caso de cópia, retirar os '\'
      - "discovery.type=single-node"
      - "xpack.security.enabled=false"
      - "xpack.security.transport.ssl.enabled=false"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test: [
        "CMD-SHELL",
        "curl -fsSL http://localhost:9200/_cat/health?h=status | grep -q -E 'green|yellow'",
      ]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 15s
    volumes:
      - "elasticsearch_data:/usr/share/elasticsearch/data"
    expose:
      - "9200"
    networks:
      - default
      
  gearmand:
    image: "artefactual/gearmand:1.1.22-alpine"
    command: "--queue-type=builtin"
    user: "gearman"
    expose:
      - "4730"
    networks:
      - default

  clamavd:
    image: "clamav/clamav-debian:1.4.3-57"
    environment:
      CLAMAV_MAX_FILE_SIZE: "42"
      CLAMAV_MAX_SCAN_SIZE: "42"
      CLAMAV_MAX_STREAM_LENGTH: "100"
    expose:
      - "3310"
    volumes:
      - "archivematica_pipeline_data:/var/archivematica/sharedDirectory:ro"
    networks:
      - default

  archivematica-mcp-server:
    image: am-archivematica-mcp-server:latest
    pull_policy: never
    environment:
      DJANGO_SECRET_KEY: "12345"
      DJANGO_SETTINGS_MODULE: "archivematica.MCPServer.settings.common"
      ARCHIVEMATICA_MCPSERVER_CLIENT_USER: "archivematica"
      ARCHIVEMATICA_MCPSERVER_CLIENT_PASSWORD: "demo"
      ARCHIVEMATICA_MCPSERVER_CLIENT_HOST: "mysql"
      ARCHIVEMATICA_MCPSERVER_CLIENT_DATABASE: "MCP"
      ARCHIVEMATICA_MCPSERVER_MCPSERVER_MCPARCHIVEMATICASERVER: "gearmand:4730"
      ARCHIVEMATICA_MCPSERVER_SEARCH_ENABLED: "${\AM_SEARCH_ENABLED\:\-\true}" # em caso de cópia, retirar os '\'
      ARCHIVEMATICA_MCPSERVER_MCPSERVER_PROMETHEUS_BIND_PORT: "7999"
      ARCHIVEMATICA_MCPSERVER_MCPSERVER_PROMETHEUS_BIND_ADDRESS: "0.0.0.0"
    volumes:
      - "archivematica_pipeline_data:/var/archivematica/sharedDirectory:rw"
    links:
      - "mysql"
      - "gearmand"
    networks:
      - default

  archivematica-mcp-client:
    image: am-archivematica-mcp-client:latest
    pull_policy: never
    environment:
      DJANGO_SECRET_KEY: "12345"
      DJANGO_SETTINGS_MODULE: "archivematica.MCPClient.settings.common"           
      ARCHIVEMATICA_MCPCLIENT_CLIENT_USER: "archivematica"
      ARCHIVEMATICA_MCPCLIENT_CLIENT_PASSWORD: "demo"
      ARCHIVEMATICA_MCPCLIENT_CLIENT_HOST: "mysql"
      ARCHIVEMATICA_MCPCLIENT_CLIENT_DATABASE: "MCP"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_ELASTICSEARCHSERVER: "http://elasticsearch:9200"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_MCPARCHIVEMATICASERVER: "gearmand:4730"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_SEARCH_ENABLED: "${\AM_SEARCH_ENABLED\:\-\true}"  # em caso de cópia, retirar os '\'
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CAPTURE_CLIENT_SCRIPT_OUTPUT: "${\AM_CAPTURE_CLIENT_SCRIPT_OUTPUT\:\-\true}"  # em caso de cópia, retirar os '\'
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_SERVER: "clamavd:3310"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_MAX_FILE_SIZE: "42"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_MAX_SCAN_SIZE: "42"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_MAX_STREAM_LENGTH: "100"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_BACKEND: "clamdscanner" # Option: clamdscanner or clamscan;
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_PROMETHEUS_BIND_PORT: "7999"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_PROMETHEUS_BIND_ADDRESS: "0.0.0.0"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_METADATA_XML_VALIDATION_ENABLED: "true"
      #METADATA_XML_VALIDATION_SETTINGS_FILE: "/src/hack/submodules/archivematica-sampledata/xml-validation/xml_validation.py"
    volumes:
      - "/opt/archivematica/chaves:/home/archivematica/.ssh/"
      - "archivematica_pipeline_data:/var/archivematica/sharedDirectory:rw"
    links:
      - "clamavd"
      - "mysql"
      - "gearmand"
      - "elasticsearch"
      - "archivematica-storage-service"
    networks:
      - default
      - integracao

  archivematica-dashboard:
    image: am-archivematica-dashboard:latest
    pull_policy: never
    environment:
      FORWARDED_ALLOW_IPS: "*"
      AM_GUNICORN_ACCESSLOG: "/dev/null"
      AM_GUNICORN_RELOAD: "true"
      AM_GUNICORN_RELOAD_ENGINE: "auto"
      DJANGO_SETTINGS_MODULE: "archivematica.dashboard.settings.local"
      ARCHIVEMATICA_DASHBOARD_DASHBOARD_GEARMAN_SERVER: "gearmand:4730"
      ARCHIVEMATICA_DASHBOARD_DASHBOARD_ELASTICSEARCH_SERVER: "http://elasticsearch:9200"
      ARCHIVEMATICA_DASHBOARD_DASHBOARD_PROMETHEUS_ENABLED: "1"
      ARCHIVEMATICA_DASHBOARD_CLIENT_USER: "archivematica"
      ARCHIVEMATICA_DASHBOARD_CLIENT_PASSWORD: "demo"
      ARCHIVEMATICA_DASHBOARD_CLIENT_HOST: "mysql"
      ARCHIVEMATICA_DASHBOARD_CLIENT_DATABASE: "MCP"
      ARCHIVEMATICA_DASHBOARD_SEARCH_ENABLED: "${\AM_SEARCH_ENABLED:\-\true}"  # em caso de cópia, retirar os '\'
      ARCHIVEMATICA_DASHBOARD_DASHBOARD_SESSION_COOKIE_SECURE: "false"
      ARCHIVEMATICA_DASHBOARD_DASHBOARD_CSRF_COOKIE_SECURE: "false"
    volumes:
      - "archivematica_pipeline_data:/var/archivematica/sharedDirectory:rw"
    depends_on:
      elasticsearch:
        condition: service_healthy
        restart: true
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik"

      # HTTP -> redirect para HTTPS (middleware definido no dynamic.yml do Traefik)
      - "traefik.http.routers.dashboard-http.rule=Host(\`archivematica.tre-ac.com.br\`)"  # em caso de cópia, retirar os '\'
      - "traefik.http.routers.dashboard-http.entrypoints=websecure"
      - "traefik.http.routers.dashboard-http.tls=true"

      #- "traefik.http.routers.pentaho-http.tls.certresolver=letsencrypt"
      #- "traefik.http.routers.pentaho.service=pentaho"
      - "traefik.http.services.dashboard.loadbalancer.server.port=8000"
      - "traefik.http.routers.dashboard.middlewares=dashboard-sec"
      - "traefik.http.routers.dashboard.tls.options=secure@file"

      # Segurança
      - "traefik.http.middlewares.dashboard-sec.headers.stsSeconds=63072000"
      - "traefik.http.middlewares.dashboard-sec.headers.stsIncludeSubdomains=true"
      - "traefik.http.middlewares.dashboard-sec.headers.stsPreload=true"
    links:
      - "mysql"
      - "gearmand"
      - "elasticsearch"
      - "archivematica-storage-service"
    networks:
      - default
      - traefik

  # git clone https://github.com/artefactual/archivematica.git --branch qa/1.x --recurse-submodules
  # atualizar após o git clone executado: 
  # git submodule update --init --recursive     # Inicializar submódulos que porventura não existam (primeira vez)
  # git submodule update --recursive            # Mover os submódulos para os commits exatos referenciados
  archivematica-storage-service:
    image: am-archivematica-storage-service:latest
    pull_policy: never
    environment:
      FORWARDED_ALLOW_IPS: "*"
      SS_GUNICORN_ACCESSLOG: "/dev/null"
      SS_GUNICORN_RELOAD: "${\SS_GUNICORN_RELOAD\:\-\false}"   # em caso de cópia, retirar os '\'
      DJANGO_SETTINGS_MODULE: "archivematica.storage_service.storage_service.settings.local"
      #SS_GUNICORN_RELOAD_ENGINE: "auto"
      SS_DB_URL: "mysql://archivematica:demo@mysql/SS"
      SS_PROMETHEUS_ENABLED: "true"
      #SS_GNUPG_HOME_PATH: "/var/archivematica/storage_service/.gnupg"
      SESSION_COOKIE_SECURE: "false"
      CSRF_COOKIE_SECURE: "false"
    volumes:
      - "/opt/archivematica/hack/submodules/archivematica-sampledata/:/home/archivematica/archivematica-sampledata/:ro"
      - "archivematica_pipeline_data:/var/archivematica/sharedDirectory:rw"
      - "archivematica_storage_service_staging_data:/var/archivematica/storage_service:rw"
      # COMPARTILHAR: partição destinada para a movimentação manual - documentação autenticada
      - "/mnt/rdcarq/transfer/:/transfer:rw"
      # NÃO COMPARTILHAR: partição destinada para a interoperabilidade entre sistema
      # - cadeia de custódia - documentos autênticos
      - "/mnt/rdcarq/transfer-sistema/:/transfer-sistema:rw"
      - "/mnt/rdcarq/repositorio/:/rdcarq:rw"
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik"

      # HTTP -> redirect para HTTPS (middleware definido no dynamic.yml do Traefik)
      - "traefik.http.routers.storage-http.rule=Host(\`storage.tre-ac.com.br\`)" # em caso de cópia, retirar os '\'
      - "traefik.http.routers.storage-http.entrypoints=websecure"
      - "traefik.http.routers.storage-http.tls=true"

      #- "traefik.http.routers.pentaho-http.tls.certresolver=letsencrypt"
      #- "traefik.http.routers.pentaho.service=pentaho"
      - "traefik.http.services.storage.loadbalancer.server.port=8000"

      # Segurança
      - "traefik.http.middlewares.storage-sec.headers.stsSeconds=63072000"
      - "traefik.http.middlewares.storage-sec.headers.stsIncludeSubdomains=true"
      - "traefik.http.middlewares.storage-sec.headers.stsPreload=true"
      - "traefik.http.routers.storage.middlewares=storage-sec"
      - "traefik.http.routers.storage.tls.options=secure@file"
    links:
      - "mysql"
    networks:
      - default
      - traefik

# definição dos networks e volumes
networks:
  default:
  traefik:
    external:
      name: traefik
  integracao:
    external:
      name: integracao

volumes:
  # Internal named volumes.
  # These are not accessible outside of the docker host and are maintained by
  # Docker.
  mysql_data:
  elasticsearch_data:
  archivematica_storage_service_staging_data:

  # External named volumes.
  # These are intended to be accessible beyond the docker host (e.g. via NFS).
  # They use bind mounts to mount a specific "local" directory on the docker
  # host - the expectation being that these directories are actually mounted
  # filesystems from elsewhere.
  archivematica_pipeline_data:
    name: "am-pipeline-data"
    external: true
EOL

echo "Makefile do Archivematica criado." >> logInstallArchivematica.txt

# Subir os containeres
docker compose up -d

# Instalação das bases de dados
sudo make bootstrap
make restart-am-services
make initialize-search-index
make compile-translations
echo "Instalação do Archivematica concluída." >> logInstallArchivematica.txt

# Fim do Script