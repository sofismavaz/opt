### Instalação do Docker
Para instalar o [Docker](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04), com sucesso será necessário  atender aos requisitos gerais do sistema.
> [!NOTE]
> Os aplicativos a serem instalados estão compatíveis com a versão Ubuntu 24.04 LTS.

Permissões de acesso para execução das ações do Docker
- [ ] getent group docker
- [ ] sudo usermod -a -G docker ${USER}
- [ ] newgrp docker

### Instação do Portainer
O [Portainer 2.33.0 LTS](https://docs.portainer.io/start/install-ce/server/docker/linux), trás todos os novos recursos das versões anteriores do STS, incluindo um novo visual, Helm, atualização do Edge e melhorias no mTLS, além de um novo recurso de alerta experimental.

Será necessário criar a conexão de rede para que a o serviço da imagem Docker possa trafegar os dados.
- [ ] docker network create traefik

A instalação dos módulos *Docker* são instalados no diretório das aplicações:   **/opt**
- [ ] mkdir -p portainer/data
- [ ] cd /portainer
- [ ] nano compose.yaml

Colar conteúdo a seguir ao arquivo compose.yaml

```
version: "3.9"

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
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
```

Levantar o serviço portainer.io
- [ ] docker compose up -d
- [ ] acessar o endereço: http://localhost:9000

A primeira vez que o serviço portainer.io é iniciado, a aplicação exige a criação de um usuário administrador, e nesta versão ficou definido que:
> usuário: admin
> senha: Eleições2025.

Uma vez disponível o serviço traefik, adicionar as linhas de labels ao compose.yaml do portainer

```
version: "3.9"

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
      traefik.http.routers.portainer.rule: "Host(`portainer.tre-ac.jus.br`)"
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
```

Reiniciar o serviço 
- [ ] docker compose up -d


### Instalação do Traefik

Com a ferramenta portainer.io, você pode adicionar uma stack traefik, usando o ==Web Editor== e inserindo as linhas de código a seguir. Essa ação cria o arquivo compose.yaml no diretório *opt/traefik*

Criar a árvore de diretórios: 
- [ ] mkdir -p opt/traefik/acme  
- [ ] mkdir -p opt/traefik/config  
- [ ] mkdir -p opt/traefik/dynamic  
- [ ] mkdir -p opt/traefik/letsencrypt  
- [ ] mkdir -p opt/traefik/logs

Criar arquivos:
- [ ] touch opt/traefik/acme/acme.json
- [ ] touch opt/traefik/dynamic/dynamic.yml
- [ ] touch opt/traefik/traefik.yml

```
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
```

Incluir as linhas de código a seguir ao arquivo traefik.yml: 
- [ ] nano opt/traefik/traefik.yml

```
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
    directory: "/etc/traefik/dynamic"
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
```

Alterar arquivo: 
- [ ] nano /opt/traefik/dynamic/dynamic.yml

```
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
      email: "suporte@tre-ac.jus.br"
      storage: "/acme/acme.json"   # persista em volume
      httpChallenge:
        entryPoint: web            # desafio pela porta 80
```

### Instalação Archivemática

Usar o [Manual Archivemática](https://github.com/artefactual/archivematica/blob/qa/1.x/hack/README.md)

O [Archivematica](https://www.archivematica.org/pt-br/) é um aplicativo de código aberto baseado na Web e em padrões que permite à sua instituição preservar o acesso de longo prazo a conteúdo digital confiável, autêntico e seguro.

Baixar o código da plataforma git
- [ ] git clone https://github.com/artefactual/archivematica.git --recurse-submodules

Fazer a conferência de versão para garantir a compatibilidade
- [ ] cd archivematica
- [ ] git checkout v1.18.0
- [ ] git pull origin v1.18.0 

Caso não tenha feito o git clone com o parâmetro: --recurse-submodules é possível adequar a versão 
- [ ] git pull origin v1.18.0 --rebase 
- [ ] git submodule update --init --recursive

Para o [elasticsearch container](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-docker), é necessário ajustar um parâmetro de memória:
- [ ] sudo sysctl -w vm.max_map_count=262144

Para que o ajuste de memória seja reconhecido na inicialização, colocar conteúdo na última linha
- [ ] nano /etc/sysctl.conf
- [ ] vm.max_map_count=262144

Criar volumes na máquina:
- [ ] mkdir -p /mnt/rdcarq/transfer
- [ ] mkdir -p /mnt/rdcarq/transfer-sistema
- [ ] mkdir -p /mnt/rdcarq/repositorio
- [ ] mkdir -p /mnt/rdcarq/repositorio/aip
- [ ] mkdir -p /mnt/rdcarq/repositorio/dip
- [ ] mkdir -p /mnt/rdcarq/repositorio/backlog

acessar a pasta cd /opt/archivematica/hack e criar as imagens:
- [ ] docker compose build

Abrir o Web EditorCriar uma nova Stach: archivematica

```
services:
  mysql:
    image: "percona:8.0"
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
      - "cluster.routing.allocation.disk.threshold_enabled=${ELASTICSEARCH_DISK_THRESHOLD_ENABLED:-true}"
      - "discovery.type=single-node"
      - "xpack.security.enabled=false"
      - "xpack.security.transport.ssl.enabled=false"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
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
    image: "artefactual/gearmand:1.1.18-alpine"
    command: "--queue-type=builtin"
    user: "gearman"
    expose:
      - "4730"

  clamavd:
    image: "artefactual/clamav:latest"
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
      ARCHIVEMATICA_MCPSERVER_SEARCH_ENABLED: "${AM_SEARCH_ENABLED:-true}"
      ARCHIVEMATICA_MCPSERVER_MCPSERVER_PROMETHEUS_BIND_PORT: "7999"
      ARCHIVEMATICA_MCPSERVER_MCPSERVER_PROMETHEUS_BIND_ADDRESS: "0.0.0.0"
    volumes:
      #- "/opt/archivematica/:/src"
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
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_SEARCH_ENABLED: "${AM_SEARCH_ENABLED:-true}"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CAPTURE_CLIENT_SCRIPT_OUTPUT: "${AM_CAPTURE_CLIENT_SCRIPT_OUTPUT:-true}"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_SERVER: "clamavd:3310"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_MAX_FILE_SIZE: "42"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_MAX_SCAN_SIZE: "42"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_MAX_STREAM_LENGTH: "100"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_BACKEND: "clamdscanner" # Option: clamdscanner or clamscan;
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_PROMETHEUS_BIND_PORT: "7999"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_PROMETHEUS_BIND_ADDRESS: "0.0.0.0"
      ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_METADATA_XML_VALIDATION_ENABLED: "true"
      METADATA_XML_VALIDATION_SETTINGS_FILE: "/src/hack/submodules/archivematica-sampledata/xml-validation/xml_validation.py"
      XML_CATALOG_FILES: "/src/hack/submodules/archivematica-sampledata/xml-validation/catalog.xml"
    volumes:
      #- "/opt/archivematica/:/src"
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
      DJANGO_SETTINGS_MODULE: "settings.local"
      ARCHIVEMATICA_DASHBOARD_DASHBOARD_GEARMAN_SERVER: "gearmand:4730"
      ARCHIVEMATICA_DASHBOARD_DASHBOARD_ELASTICSEARCH_SERVER: "http://elasticsearch:9200"
      ARCHIVEMATICA_DASHBOARD_DASHBOARD_PROMETHEUS_ENABLED: "1"
      ARCHIVEMATICA_DASHBOARD_CLIENT_USER: "archivematica"
      ARCHIVEMATICA_DASHBOARD_CLIENT_PASSWORD: "demo"
      ARCHIVEMATICA_DASHBOARD_CLIENT_HOST: "mysql"
      ARCHIVEMATICA_DASHBOARD_CLIENT_DATABASE: "MCP"
      ARCHIVEMATICA_DASHBOARD_SEARCH_ENABLED: "${AM_SEARCH_ENABLED:-true}"
    volumes:
      #- "/opt/archivematica/:/src"
      - "archivematica_pipeline_data:/var/archivematica/sharedDirectory:rw"
    depends_on:
      elasticsearch:
        condition: service_healthy
        restart: true
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik"

      # HTTP -> redirect para HTTPS (middleware definido no dynamic.yml do Traefik)
      - "traefik.http.routers.dashboard-http.rule=Host(`archivematica.tre-ac.jus.br`)"
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
      SS_GUNICORN_RELOAD: "true"
      SS_GUNICORN_RELOAD_ENGINE: "auto"
      DJANGO_SETTINGS_MODULE: "storage_service.settings.local"
      SS_DB_URL: "mysql://archivematica:demo@mysql/SS"
      SS_GNUPG_HOME_PATH: "/var/archivematica/storage_service/.gnupg"
      SS_PROMETHEUS_ENABLED: "true"
    volumes:
      #- "/opt/archivematica/hack/submodules/archivematica-storage-service/:/src/"
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
      - "traefik.http.routers.storage-http.rule=Host(`storage.dev.pyta.com.br`)"
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
```

Acessar o container do Mysql e criar o banco `MCP` e `SS`
- [ ] mysql -u root -p”12345”
- [ ] create database MCP;
- [ ] create database SS;
      CREATE USER 'archivematica'@'%' IDENTIFIED BY 'demo';
      GRANT ALL PRIVILEGES ON `MCP`.* TO 'archivematica'@'%';
      GRANT ALL PRIVILEGES ON `SS`.*  TO 'archivematica'@'%';

Criar banco de dados do painel Dashboard
Acessar o conteiner do dashboard
acessar o diretório do dashboard
- [ ] cd /src/src/archivematica/dashboard

comando:
- [ ] ./manage.py migrate 
Criar dados banco de dados do Storage Service
criar conteiner provisório

Levantar o serviço archivemática

```
docker run -it --rm \
  --network archivematica_default \
  -e FORWARDED_ALLOW_IPS="*" \
  -e SS_GUNICORN_ACCESSLOG="/dev/null" \
  -e SS_GUNICORN_RELOAD="true" \
  -e SS_GUNICORN_RELOAD_ENGINE="auto" \
  -e DJANGO_SETTINGS_MODULE="storage_service.settings.local" \
  -e SS_DB_URL="mysql://archivematica:demo@mysql/SS" \
  -e SS_GNUPG_HOME_PATH="/var/archivematica/storage_service/.gnupg" \
  -e SS_PROMETHEUS_ENABLED="true" \
  --entrypoint sh \
  am-archivematica-storage-service
```

	
criar dados de banco de dados SS
comando:
- [ ] ./manage.py migrate

Criar usuário do Storage Service
- [ ] cd /src/src/archivematica/storage_service
- [ ] ./manage.py createsuperuser


