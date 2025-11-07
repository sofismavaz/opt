# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Autor: Lucir Vaz 
# Data: 2024-06-27
# Versão: 1.0
#
# Instruções iniciais
# Este prepara o emabiente de instalação das aplicações Docker
#
# pasta padrão onde os arquivos serão gravados caso não seja indicada outra
pastaLog="${HOME}/archivematica"
logPreparaAmbiente="${pastaLog}/logPreparaAmbiente.txt"
touch $logPreparaAmbiente

echo ""
echo " ------------------------------------------------ -"
echo ""
echo "Bem-vindo ao Menu de Instalação da Plataforma RDC-Arq usando Docker!"
echo "Por favor, escolha a pasta onde os scripts serão baixados (pressione Enter para usar a pasta ${pastaLog}):"
echo ""
echo " ------------------------------------------------ -"
echo ""
read -p "Em que pasta você gostaria de baixar os Scripts de Instalação?  : "
pasta=$REPLY
echo ""
echo ""
echo "Usando a pasta indicada para baixar os scripts."
echo "Iniciando a instalação do Docker Compose..."
echo ""
echo ""
bash ./installDocker.sh  2>$logPreparaAmbiente
echo "Preparando ambiente de uso do Docker Compose..."
bash ./preparaSODocker.sh "${pastaLog}" 2>$logPreparaAmbiente
echo ""
echo ""
echo "O ambiente está preparado para a instalação dos aplicativos Archivematica e AtoM"
echo "Entrar em uma nova sessão, com o comando - newgrp docker - e processar a instalação com o grupo Docker"
echo "O Script menuInstall.sh executa os passos de configuração e instalação dos aplicativos."
echo ""
echo ""
