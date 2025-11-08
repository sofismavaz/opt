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

# O 'yq merge' irá mesclar os arquivos. 
# Por padrão, ele sobrescreve chaves do primeiro arquivo com as do segundo.
# Vamos usar o 'compose_arch.yml' como o principal (base) e o 'compose.yml' para adicionar o que falta.
# No entanto, a mesclagem direta de *todos* os serviços pode resultar em conflitos.

# A estratégia mais limpa é:
# 1. Usar o 'compose.yml' (com todas as definições de build) como base.
# 2. Aplicar as alterações específicas do 'compose_arch.yml' (imagens pré-construídas, redes, labels traefik).

# Estratégia: Usar compose_arch.yml como base (pois tem redes e labels de produção)
# e adicionar/sobrescrever partes do compose.yml.
# No entanto, vamos reverter a ordem para a lógica do exemplo:
# Use compose_arch.yml (configurações de produção/customizadas) e sobreponha com compose.yml
# para garantir que as definições de volumes, networks e services sejam consistentes.

# Usaremos compose_arch.yml como BASE e faremos o MERGE com compose.yml para ADICIONAR
# volumes e serviços que estão faltando no compose_arch.yml (como o 'nginx').

# Mesclar o compose_arch.yml (que tem as redes e labels traefik)
# com o compose.yml (que tem o serviço 'nginx' e volumes adicionais).
# A ferramenta 'yq' faz uma mesclagem profunda em listas e mapas, o que é ideal.
# O segundo arquivo na linha de comando ('compose.yml') sobrescreve o primeiro ('compose_arch.yml') 
# em caso de chaves duplicadas.
# yq eval-all '. as $item ireduce ({}; . * $item)' ${composeArch} ${composeOriginal} > "$TEMP_FILE"