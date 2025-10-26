# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Autor: Lucir Vaz 
# Data: 2024-06-27
# Versão: 1.0
#
# Instruções iniciais
# Este Menu chamará os Scripts de preparação do emabiente de instalação das aplicações Docker

echo "Menu de Instalação de Aplicações Docker"
echo "1 - Instalar Docker"
echo "2 - Instalar Portainer e Traefik"
echo "3 - Instalar Archivemática"
echo "4 - Instalar AtoM"
echo "5 - Instalar Docker EntryPoint"
echo "6 - Sair"
read -p "Escolha uma opção (1-6): " opcao
case $opcao in
    1)
        echo "Iniciando a instalação do Docker Compose..."
        bash /opt/installDocker.sh
        ;;
    2)
        echo "Iniciando a instalação do Portainer e Traefik..."
        bash /opt/installPortainerTraefik.sh
        ;;
    3)
        echo "Inicianndo a instalação do Archivemática..."
        bash /opt/installArchivematica.sh
        ;;
    4)
        echo "Iniciando a instalação do AtoM..."
        bash /opt/installAtoM.sh
        ;;
    5)
        echo "Iniciando a configuração do Docker EntryPoint..."
        bash /opt/dockerEntrypoint.sh
        ;;
    6)
        echo "Saindo do menu de instalação."
        exit 0
        ;;
    *)
        echo "Opção inválida. Por favor, escolha uma opção entre 1 e 5."
        ;;
esac

echo "Instalação concluída."
