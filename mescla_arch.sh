#!/bin/bash
# mescla_arch.sh - Script para mesclar compose.yml e compose_arch.yml em um único arquivo Docker Compose.
# Busca-seadicionar os padrões e configuração de ambiente à nova versão do archivemativa
# Script construído pela IA Gemini
# Lucir Vaz
# data: 05/11/20026

# Recebe pasta de destino da instalação como argumento
pastaLog=$1
if [ -z "$pastaLog" ]; then
    pastaLog="${HOME}/archivematica"
    mkdir -p $pastaLog
fi

pastaInstallArch="/opt/archivematica"

# 1. Verificar a existência das ferramentas necessárias e dos arquivos.
if ! command -v yq &> /dev/null
then
    echo "Erro: A ferramenta 'yq' (para processar YAML) não foi encontrada." >&2
    echo "Instale-a (ex: sudo apt install yq ou brew install yq) e tente novamente." >&2
    exit 1
fi

# composeRedeLocal=$(yq e '.services.nginx.networks.rede_local' compose.yml 2>/dev/null)
#
composeRedeLocal="${pastaLog}/arch/composeRedeLocal.yml"
composeOriginal="${pastaInstallArch}/hack/compose.yml"
composeArch="${pastaLog}/compose_arch.yml"

if [[ ! -f "$composeOriginal" || ! -f "$composeArch" ]]
then
    echo "Erro: Os arquivos 'compose.yml' e/ou 'compose_arch.yml' não foram encontrados no diretório atual." >&2
    exit 1
fi

OUTPUT_FILE="docker-compose.yml"
TEMP_FILE="temp_merged.yml"

echo "Iniciando a mesclagem de ${composeOriginal} e ${composeArch}..."

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
yq eval-all '. as $item ireduce ({}; . * $item)' ${composeArch} ${composeOriginal} > "$TEMP_FILE"

# O comando yq acima é uma forma segura de mesclagem recursiva.
# Pós-processamento: Mudar o campo 'name' e garantir uma versão.
yq '.name = "am_merged" | .version = "3.8"' "$TEMP_FILE" > "$OUTPUT_FILE"

sudo mv "$composeOriginal" "$pastaLog/compose_original_backup.yml"
sudo mv "$OUTPUT_FILE" "$composeOriginal"

# Limpar arquivo temporário
rm "$TEMP_FILE"

echo "✅ Mesclagem concluída! O novo arquivo Docker Compose está em: $OUTPUT_FILE"
echo "Nota: Verifique o '$OUTPUT_FILE' para garantir que as configurações desejadas (ex: links vs networks) foram priorizadas corretamente."

exit 0