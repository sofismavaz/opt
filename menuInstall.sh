# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Autor: Lucir Vaz 
# Data: 2024-06-27
# Versão: 1.0
#
# Instruções iniciais
# Este Menu chamará os Scripts de preparação do emabiente de instalação das aplicações Docker
#
# pasta padrão onde os arquivos serão gravados caso não seja indicada outra
padrao="${HOME}/rdcarqInstall"

clear
echo "Bem-vindo ao Menu de Instalação da Plataforma RDC-Arq usando Docker!"
echo "Por favor, escolha a pasta onde os scripts serão baixados (pressione Enter para usar a pasta ${padrao}):"
read -p "Em que pasta você gostaria de baixar os Scripts de Instalação?  "
pasta=$REPLY

if [ ! -z {$pasta} ]; then
    echo "A pasta ${pasta} não existe,... criando agora..."
    pasta="${padrao}"
fi

# Criar a pasta quando não existir
# mkdir -p "$pasta" || { echo "Falha ao criar a pasta ${pasta}. Verifique as permissões."; exit 1; }

# Clonar o repositório contendo os scripts de instalação na pasta indicada
echo "Usando a pasta indicada para baixar os scripts."
git clone https://github.com/sofismavaz/opt.git $pasta

# verifica se os scripts necessários estão presentes
if [ ! -f /$pasta/installDocker.sh ]; then
    echo "Script installDocker.sh não encontrado em $pasta. Por favor, verifique." 2>${pasta}/logInstallDocker.txt
    exit 1
fi
if [ ! -f /$pasta/preparaSODocker.sh ]; then
    echo "Script preparaSODocker.sh não encontrado em $pasta. Por favor, verifique." 2>${pasta}/logInstallDocker.txt
    exit 1
fi
if [ ! -f /$pasta/installPortainerTraefik.sh ]; then
    echo "Script installPortainerTraefik.sh não encontrado em $pasta. Por favor, verifique." 2>${pasta}/logInstallDocker.txt
    exit 1
fi
if [ ! -f /$pasta/installArchivematica.sh ]; then
    echo "Script installArchivematica.sh não encontrado em $pasta. Por favor, verifique." 2>${pasta}/logInstallDocker.txt
    exit 1
fi
if [ ! -f /$pasta/installAtoM.sh ]; then
    echo "Script installAtoM.sh não encontrado em $pasta. Por favor, verifique." 2>${pasta}/logInstallDocker.txt
    exit 1
fi
if [ ! -f /$pasta/dockerEntrypoint.sh ]; then
    echo "Script dockerEntrypoint.sh não encontrado em $pasta. Por favor, verifique."
    exit 1
fi

while true; do
echo "----------------------------------------"
echo "Menu de Instalação de Aplicações Docker"
echo "0 - Instalar Docker"
echo "1 - Preparar o ambiente para uso do Docker"
echo "2 - Instalar Portainer e Traefik"
echo "3 - Instalar Archivemática"
echo "4 - Instalar AtoM"
echo "5 - Instalar Docker EntryPoint"
echo "6 - Sair"
read -p "Escolha uma opção (0-6): " opcao
case $opcao in
    0)
        echo "Iniciando a instalação do Docker Compose..."
        bash $pasta/installDocker.sh 2>${pasta}/logInstallDocker.txt
        ;;
    1)
        echo "Preparando ambiente de uso do Docker Compose..."
        bash $pasta/preparaSODocker.sh  2>${pasta}/logInstallDocker.txt
        ;;
    2)
        echo "Iniciando a instalação do Portainer e Traefik..."
        bash $pasta/installPortainerTraefik.sh 2>${pasta}/logInstallDocker.txt
        ;;
    3)
        echo "Inicianndo a instalação do Archivemática..."
        bash $pasta/installArchivematica.sh 2>${pasta}/logInstallDocker.txt
        ;;
    4)
        echo "Iniciando a instalação do AtoM..."
        bash $pasta/installAtoM.sh 2>${pasta}/logInstallDocker.txt
        ;;
    5)
        echo "Iniciando a configuração do Docker EntryPoint..."
        bash $pasta/dockerEntrypoint.sh 2>${pasta}/logInstallDocker.txt
        ;;
    6)
        echo "Saindo do menu de instalação."
        exit 0
        ;;
    *)
        echo "Opção inválida. Por favor, escolha uma opção entre 1 e 5."
        ;;
esac

done    

echo "Instalação concluída." >>${pasta}/logInstallDocker.txt
