#!/bin/bash

# Colores para mejor visualización
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
nc='\e[0m'

function construir_servicio() {
    echo -e "${blue}Instalando servicio...${nc}"
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/build-service-v2ray.sh -O build-service-v2ray.sh
    if [[ $? -ne 0 || ! -s build-service-v2ray.sh ]]; then
        echo -e "${red}Error al descargar el script de construcción.${nc}"
    else
        bash build-service-v2ray.sh
    fi
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${nc}"
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

function remover_servicio() {
    echo -e "${red}Eliminando servicio...${nc}"
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/remove-service-v2ray.sh -O remove-service-v2ray.sh
    if [[ $? -ne 0 || ! -s remove-service-v2ray.sh ]]; then
        echo -e "${red}Error al descargar el script de eliminación.${nc}"
    else
        bash remove-service-v2ray.sh
    fi
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${nc}"
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

function mostrar_menu() {
    while true; do
        clear
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${nc}"
        echo -e "${green}        PANEL DE CONTROL V2RAY-VLESS${nc}"
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${nc}"
        echo -e "${yellow}1) Construir Servicio${nc}"
        echo -e "${yellow}2) Remover Servicio${nc}"
        echo -e "${yellow}3) Salir${nc}"
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${nc}"
        echo -ne "${yellow}Seleccione una opción [1-3]: ${nc}"

        read -r opcion

        case $opcion in
            1) construir_servicio ;;
            2) remover_servicio ;;
            3)
                echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${nc}"
                echo -e "${yellow}Saliendo...${nc}"
                echo -e "${blue}👾 Créditos a Leo Duarte${nc}"
                sleep 1
                exit 0
                ;;
            *) echo -e "${red}Opción inválida. Inténtalo de nuevo.${nc}"; sleep 2 ;;
        esac
    done
}

# Iniciar menú
mostrar_menu
