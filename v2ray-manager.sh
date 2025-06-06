#!/bin/bash

# Colores para mejor visualización
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
nc='\e[0m'

function construir_servicio() {
    echo -e "${blue}Instalando servicio...${nc}"
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/script-v2ray.sh -O script-v2ray.sh && bash script-v2ray.sh
}

function editar_json() {
    echo -e "${yellow}Editando archivo JSON...${nc}"
    nano /etc/v2ray/config.json
    echo -e "${green}Edición finalizada.${nc}"
}

function remover_servicio() {
    echo -e "${red}Eliminando servicio...${nc}"
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/script-v2ray-uninstall.sh -O script-v2ray-uninstall.sh && bash script-v2ray-uninstall.sh
}

function mostrar_menu() {
    clear
    echo -e "${green}======================================"
    echo -e "     PANEL DE CONTROL V2RAY-VLESS"
    echo -e "======================================${nc}"
    echo -e "${yellow}1) Construir Servicio"
    echo -e "2) Editar JSON"
    echo -e "3) Remover Servicio"
    echo -e "4) Salir${nc}"
    echo
    read -rp "Selecciona una opción [1-4]: " opcion

    case $opcion in
        1) construir_servicio ;;
        2) editar_json ;;
        3) remover_servicio ;;
        4) echo -e "${green}Saliendo...${nc}"; exit 0 ;;
        *) echo -e "${red}Opción inválida.${nc}"; sleep 1 ;;
    esac
}

# Bucle para mantener el menú activo hasta que se seleccione salir
while true; do
    mostrar_menu
done
