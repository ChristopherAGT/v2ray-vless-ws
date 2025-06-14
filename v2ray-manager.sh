#!/bin/bash
# Hola

# ╔══════════════════════════════════════════════════════╗
# ║ 🎨 COLORES Y ESTILO                                  ║
# ╚══════════════════════════════════════════════════════╝
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

SEPARADOR="${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# ╔══════════════════════════════════════════════════════╗
# ║ 🧹 MANEJO DE ARCHIVOS TEMPORALES                     ║
# ╚══════════════════════════════════════════════════════╝
TEMP_FILES=("build-service-v2ray.sh" "remove-service-v2ray.sh")
trap 'rm -f "${TEMP_FILES[@]}"' EXIT

# ╔══════════════════════════════════════════════════════╗
# ║ ⏸️ FUNCIÓN DE PAUSA                                  ║
# ╚══════════════════════════════════════════════════════╝
pausa_menu() {
    echo
    echo -e "${BLUE}🔁 Presione cualquier tecla para volver al menú...${RESET}"
    read -n 1 -s
    echo
}

# ╔══════════════════════════════════════════════════════╗
# ║ 📥 DESCARGA SEGURA DE SCRIPTS                        ║
# ╚══════════════════════════════════════════════════════╝
descargar_limpio() {
    local url=$1
    local archivo=$2

    [[ -f $archivo ]] && rm -f "$archivo"

    wget -q "$url" -O "$archivo"
    if [[ $? -ne 0 || ! -s $archivo ]]; then
        echo -e "${RED}❌ Error al descargar el archivo '${archivo}'.${RESET}"
        return 1
    fi
    return 0
}

# ╔══════════════════════════════════════════════════════╗
# ║ ⚙️ CONSTRUIR SERVICIO                                ║
# ╚══════════════════════════════════════════════════════╝
construir_servicio() {
    echo -e "$SEPARADOR"
    echo -e "${YELLOW}⚙️ Construyendo un nuevo servicio...${RESET}"

    descargar_limpio "https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/build-service-v2ray.sh" "build-service-v2ray.sh"
    if [[ $? -ne 0 ]]; then
        pausa_menu
        return 1
    fi

    bash build-service-v2ray.sh
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Error al ejecutar el script de construcción.${RESET}"
        pausa_menu
        return 1
    fi

    echo -e "$SEPARADOR"
    echo -e "${GREEN}✅ Servicio instalado correctamente.${RESET}"
    echo -e "$SEPARADOR"
    pausa_menu
}

# ╔══════════════════════════════════════════════════════╗
# ║ 🧹 REMOVER SERVICIO                                  ║
# ╚══════════════════════════════════════════════════════╝
remover_servicio() {
    echo -e "$SEPARADOR"
    echo -e "${RED}🧹 Removiendo un servicio...${RESET}"

    descargar_limpio "https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/remove-service-v2ray.sh" "remove-service-v2ray.sh"
    if [[ $? -ne 0 ]]; then
        pausa_menu
        return 1
    fi

    bash remove-service-v2ray.sh
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Error al ejecutar el script de eliminación.${RESET}"
        pausa_menu
        return 1
    fi

    echo -e "$SEPARADOR"
    echo -e "${GREEN}✅ Servicio eliminado correctamente.${RESET}"
    echo -e "$SEPARADOR"
    pausa_menu
}

# ╔══════════════════════════════════════════════════════╗
# ║ 🧭 MENÚ PRINCIPAL                                    ║
# ╚══════════════════════════════════════════════════════╝
mostrar_menu() {
    while true; do
        clear
        echo -e "$SEPARADOR"
        echo -e "${CYAN}    🚀 PANEL DE CONTROL V2RAY-VLESS${RESET}"
        echo -e "$SEPARADOR"
        echo -e "${YELLOW}1️⃣  Construir Servicio${RESET}"
        echo -e "${YELLOW}2️⃣  Remover Servicio${RESET}"
        echo -e "${YELLOW}3️⃣  Salir${RESET}"
        echo -e "$SEPARADOR"
        echo -ne "${YELLOW}👉 Seleccione una opción [1-3]: ${RESET}"

        read -r opcion
        case $opcion in
            1) construir_servicio ;;
            2) remover_servicio ;;
            3)
                echo -e "$SEPARADOR"
                echo -e "${YELLOW}👋 Saliendo...${RESET}"
                echo -e "$SEPARADOR"
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

# ╔══════════════════════════════════════════════════════╗
# ║ 🚀 EJECUCIÓN DEL MENÚ                                ║
# ╚══════════════════════════════════════════════════════╝
mostrar_menu
