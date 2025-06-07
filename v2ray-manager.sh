#!/bin/bash
#Hola

# Colores para mejor visualización
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

function construir_servicio() {
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  # Línea añadida
    echo -e "${yellow}⚙️ Construyendo un nuevo servicio...${RESET}"
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/build-service-v2ray.sh -O build-service-v2ray.sh
    if [[ $? -ne 0 || ! -s build-service-v2ray.sh ]]; then
        echo -e "${red}❌ Error al descargar el script de construcción.${RESET}"
    else
        bash build-service-v2ray.sh
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${green}✅ Servicio instalado correctamente.${RESET}"
    fi
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    read -n 1 -s -r -p "🔁 Presiona cualquier tecla para volver al menú..."
}

function remover_servicio() {
    echo -e "${red}🧹 Removiendo servicio construido...${RESET}"
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/remove-service-v2ray.sh -O remove-service-v2ray.sh
    if [[ $? -ne 0 || ! -s remove-service-v2ray.sh ]]; then
        echo -e "${red}❌ Error al descargar el script de eliminación.${RESET}"
    else
        bash remove-service-v2ray.sh
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${green}✅ Servicio eliminado correctamente.${RESET}"
    fi
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    read -n 1 -s -r -p "🔁 Presiona cualquier tecla para volver al menú..."
}

function mostrar_menu() {
    while true; do
        clear
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${cyan}    🚀 PANEL DE CONTROL V2RAY-VLESS${RESET}"
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${yellow}1️⃣  Construir Servicio${RESET}"
        echo -e "${yellow}2️⃣  Remover Servicio${RESET}"
        echo -e "${yellow}3️⃣  Salir${RESET}"
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -ne "${yellow}👉 Seleccione una opción [1-3]: ${RESET}"

        read -r opcion

        case $opcion in
            1) construir_servicio ;;
            2) remover_servicio ;;
            3)
                echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
                echo -e "${yellow}👋 Saliendo...${RESET}"
                echo -e "${blue}👾 Créditos a Leo Duarte${RESET}"
                sleep 1
                exit 0
                ;;
            *) echo -e "${red}⚠️  Opción inválida. Inténtalo de nuevo.${RESET}"; sleep 2 ;;
        esac
    done
}

# Iniciar menú
mostrar_menu
