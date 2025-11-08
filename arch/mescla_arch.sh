#!/bin/bash
# mescla_arch.sh - Script para mesclar compose.yml e compose_arch.yml em um único arquivo Docker Compose.
# Busca-seadicionar os padrões e configuração de ambiente à nova versão do archivemativa
# Script construído pela IA Gemini
# Lucir Vaz
# data: 07/11/20026

# Recebe pasta de destino da instalação como argumento
pastaLog=$1
if [ -z "$pastaLog" ]; then
    pastaLog="${HOME}/archivematica"
fi

# composeRedeLocal=$(yq e '.services.nginx.networks.rede_local' compose.yml 2>/dev/null)
pastaInstallArch="/opt/archivematica"
composeOriginal="${pastaInstallArch}/hack/docker-compose.yml"
composeRedeLocal="${pastaLog}/arch/interfaceRede.yml"
composeArch="${pastaLog}/compose.yml"

# 1. Verificar a existência das ferramentas necessárias e dos arquivos.
if ! command -v yq &> /dev/null
then
    echo "A ferramenta 'yq' é necessária (para processar YAML e está sendo instalada."
    sudo snap install yq
fi

# avalia a existência dos arquivos
if [[ ! -f "$composeOriginal" || ! -f "$composeArch" ]]
then
    echo "Erro: Os arquivos 'compose.yml' e/ou 'compose_arch.yml' não foram encontrados no diretório atual." >&2
    exit 1
fi

# comando para inserir a interfaceRedeTraefik.yml ao arquivo docker-compose.yml e criar o arquivo compose_final.yml
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' ${composeOriginal} "${composeRedeLocal}" > "${composeArch}"

# copiar arquivo compose para levantar serviço archivematica
cp "${composeArch}" "${pastaInstallArch}/hack/compose.yml"

echo "✅ Mesclagem concluída! O novo arquivo Docker Compose está em: ${composeArch}"
echo "Nota: Verifique o ${composeArch} para garantir que as configurações desejadas (ex: links vs networks) foram priorizadas corretamente."

exit 0