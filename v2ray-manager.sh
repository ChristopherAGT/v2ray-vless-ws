#!/bin/bash
# Hola

# Colores para mejor visualización
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

function construir_servicio() {
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  # Línea añadida
    echo -e "${YELLOW}⚙️ Construyendo un nuevo servicio...${RESET}"
    
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/build-service-v2ray.sh -O build-service-v2ray.sh
    if [[ $? -ne 0 || ! -s build-service-v2ray.sh ]]; then
        echo -e "${RED}❌ Error al descargar el script de construcción.${RESET}"
        return 1  # Termina la función si hubo un error al descargar el archivo
    fi
    
    bash build-service-v2ray.sh
    if [[ $? -ne 0 ]]; then  # Verifica si el script descargado falló
        echo -e "${RED}❌ Error al ejecutar el script de construcción.${RESET}"
        return 1  # Termina la función si hubo un error al ejecutar el script
    fi
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}✅ Servicio instalado correctamente.${RESET}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    read -n 1 -s -r -p "🔁 Presiona cualquier tecla para volver al menú..."
}

function remover_servicio() {
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  # Línea añadida
    echo -e "${RED}🧹 Removiendo un servicio...${RESET}"
    
    wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/remove-service-v2ray.sh -O remove-service-v2ray.sh
    if [[ $? -ne 0 || ! -s remove-service-v2ray.sh ]]; then
        echo -e "${RED}❌ Error al descargar el script de eliminación.${RESET}"
        return 1  # Termina la función si hubo un error al descargar el archivo
    fi
    
    bash remove-service-v2ray.sh
    if [[ $? -ne 0 ]]; then  # Verifica si el script descargado falló
        echo -e "${RED}❌ Error al ejecutar el script de eliminación.${RESET}"
        return 1  # Termina la función si hubo un error al ejecutar el script
    fi
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}✅ Servicio eliminado correctamente.${RESET}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    read -n 1 -s -r -p "🔁 Presiona cualquier tecla para volver al menú..."
}

function mostrar_menu() {
    while true; do
        clear
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${CYAN}    🚀 PANEL DE CONTROL V2RAY-VLESS${RESET}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${YELLOW}1️⃣  Construir Servicio${RESET}"
        echo -e "${YELLOW}2️⃣  Remover Servicio${RESET}"
        echo -e "${YELLOW}3️⃣  Salir${RESET}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -ne "${YELLOW}👉 Seleccione una opción [1-3]: ${RESET}"

        read -r opcion

        case $opcion in
            1) 
                construir_servicio
                if [[ $? -ne 0 ]]; then  # Si la opción 1 falló, no regresa al menú
                    echo -e "${RED}⚠️  Error en la construcción del servicio.${RESET}"
                    sleep 2
                fi
                ;;
            2) 
                remover_servicio
                if [[ $? -ne 0 ]]; then  # Si la opción 2 falló, no regresa al menú
                    echo -e "${RED}⚠️  Error al eliminar el servicio.${RESET}"
                    sleep 2
                fi
                ;;
            3)
                echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
                echo -e "${YELLOW}👋 Saliendo...${RESET}"
                echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
                echo -e "${BLUE}👾 Créditos a Leo Duarte${RESET}"
                sleep 1
                exit 0
                ;;
            *) 
                echo -e "${RED}⚠️  Opción inválida. Inténtalo de nuevo.${RESET}"
                sleep 2
                ;;
        esac
    done
}

# Iniciar menú
mostrar_menu
