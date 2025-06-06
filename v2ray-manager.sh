#!/bin/bash

# Colores para mejor visualización
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
nc='\e[0m'

# Ruta base donde buscar archivos config.json
CONFIG_BASE="/etc/v2ray-instances"

function construir_servicio() {
    echo -e "${blue}Instalando servicio...${nc}"
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/build-service-v2ray.sh -O build-service-v2ray.sh && bash build-service-v2ray.sh
}

function editar_json() {
    echo -e "${yellow}Buscando archivos config.json en $CONFIG_BASE...${nc}"
    
    if [ ! -d "$CONFIG_BASE" ]; then
        echo -e "${red}No se encontró la ruta $CONFIG_BASE. ¿Has creado múltiples instancias?${nc}"
        sleep 2
        return
    fi

    mapfile -t configs < <(find "$CONFIG_BASE" -type f -name "config.json")

    if [ ${#configs[@]} -eq 0 ]; then
        echo -e "${red}No se encontraron archivos config.json.${nc}"
        sleep 2
        return
    fi

    echo -e "${blue}Instancias disponibles:${nc}"
    for i in "${!configs[@]}"; do
        name=$(basename "$(dirname "${configs[$i]}")")
        echo -e "$((i+1))) $name → ${configs[$i]}"
    done

    echo
    read -rp "Selecciona una instancia para editar su config.json [1-${#configs[@]}]: " selection

    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#configs[@]} ]; then
        selected_file="${configs[$((selection-1))]}"
        echo -e "${yellow}Abriendo $selected_file...${nc}"
        nano "$selected_file"
        echo -e "${green}Edición finalizada.${nc}"
    else
        echo -e "${red}Selección inválida.${nc}"
        sleep 1
    fi
}

function remover_servicio() {
    echo -e "${red}Eliminando servicio...${nc}"
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/remove-service-v2ray.sh -O remove-service-v2ray.sh && bash remove-service-v2ray.sh
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
