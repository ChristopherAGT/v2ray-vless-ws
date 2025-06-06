#!/bin/bash

# Colores para mejor visualización
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
nc='\e[0m'

function construir_servicio() {
    echo -e "${blue}Instalando servicio...${nc}"
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/build-service-v2ray.sh -O build-service-v2ray.sh && bash build-service-v2ray.sh
}

function remover_servicio() {
    echo -e "${red}Eliminando servicio...${nc}"
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/remove-service-v2ray.sh -O remove-service-v2ray.sh && bash remove-service-v2ray.sh
}

function mostrar_menu() {
    while true; do
        clear
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${nc}"
        echo -e "${green}     PANEL DE CONTROL V2RAY-VLESS${nc}"
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${nc}"
        echo -e "${yellow}1) Construir Servicio${nc}"
        echo -e "${yellow}2) Remover Servicio${nc}"
        echo -e "${yellow}3) Salir${nc}"
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${nc}"
        echo -ne "${yellow}Seleccione una opción [1-3]: ${nc}"

        read -r opcion

        case $opcion in
            1) construir_servicio; break ;;
            2) remover_servicio; break ;;
            3) echo -e "${green}Saliendo...${nc}"; exit 0 ;;
            *) echo -e "${red}Opción inválida. Inténtalo de nuevo.${nc}"; sleep 2 ;;
        esac
    done
}

while true; do
    mostrar_menu
done
