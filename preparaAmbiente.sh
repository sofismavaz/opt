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
padrao="/opt"

# pasta padrão onde os arquivos serão gravados caso não seja indicada outra
pastaLog="$HOME/archivematica"
if [ ! -d "$pastaLog" ]; then
    mkdir -p "$pastaLog"
fi

touch $logPreparaAmbiente=$pastaLog/logPreparaAmbiente.txt

clear
echo ""
echo " ------------------------------------------------ -"
echo ""
echo "Bem-vindo ao Menu de Instalação da Plataforma RDC-Arq usando Docker!"
echo "Por favor, escolha a pasta onde os scripts serão baixados (pressione Enter para usar a pasta ${padrao}):"
echo ""
echo " ------------------------------------------------ -"
echo ""
read -p "Em que pasta você gostaria de baixar os Scripts de Instalação?  : "
pasta=$REPLY
echo ""
echo ""

if [ ! -z {$pasta} ]; then
    pasta="${padrao}"
else
    # verifica a existência da pasta de instalação
    read -p "Usar os scripts de preparação existentes, pressione Enter para verificar sua existência,...  " 
    opcao=$REPLY
    if [ ! -z ${opcao} ]; then
        # verifica se os scripts necessários estão presentes
        if [ ! -f /$pasta/installDocker.sh ]; then
            echo "Script installDocker.sh não encontrado em $pastaLog. Por favor, verifique." 2>$logPreparaAmbiente
            exit 1
        fi
        if [ ! -f /$pasta/preparaSODocker.sh ]; then
            echo "Script preparaSODocker.sh não encontrado em $pastaLog. Por favor, verifique." 2>$logPreparaAmbiente
            exit 1
        fi
        if [ ! -f /$pasta/installPortainerTraefik.sh ]; then
            echo "Script installPortainerTraefik.sh não encontrado em $pastaLog. Por favor, verifique." 2>$logPreparaAmbiente
            exit 1
        fi
        if [ ! -f /$pasta/installArchivematica.sh ]; then
            echo "Script installArchivematica.sh não encontrado em $pastaLog. Por favor, verifique." 2>$logPreparaAmbiente
            exit 1
        fi
        if [ ! -f /$pasta/installAtoM.sh ]; then
            echo "Script installAtoM.sh não encontrado em $pastaLog. Por favor, verifique." 2>$logPreparaAmbiente
            exit 1
        fi
        if [ ! -f /$pasta/dockerEntrypoint.sh ]; then
            echo "Script dockerEntrypoint.sh não encontrado em $pastaLog. Por favor, verifique."
            exit 1
        fi
    fi
fi

# Criar a pasta quando não existir
# mkdir -p "$pasta" || { echo "Falha ao criar a pasta ${pasta}. Verifique as permissões."; exit 1; }

# Clonar o repositório contendo os scripts de instalação na pasta indicada
echo "Usando a pasta indicada para baixar os scripts."
git clone https://github.com/sofismavaz/opt.git $pastaLog

        echo "Iniciando a instalação do Docker Compose..."
        bash $pastaLog/installDocker.sh  "${pastaLog}" 2>$logPreparaAmbiente

        echo "Preparando ambiente de uso do Docker Compose..."
        bash $pastaLog/preparaSODocker.sh "${pastaLog}" 2>$logPreparaAmbiente

echo ""
echo ""
echo "O ambiente está preparado para a instalação dos aplicativos Archivematica e AtoM"
echo "Entrar em uma nova sessão, com o comando - newgrp docker - e processar a instalação com o grupo Docker"
echo "O Script menuInstall.sh executa os passos de configuração e instalação dos aplicativos."
echo ""
echo ""
