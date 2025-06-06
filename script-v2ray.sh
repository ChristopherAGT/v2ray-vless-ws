#!/bin/bash

🛑 Detener el script si ocurre un error

set -e

🎨 Definición de colores

GREEN="\033[0;32m" RED="\033[0;31m" YELLOW="\033[1;33m" BLUE="\033[0;34m" CYAN="\033[0;36m" RESET="\033[0m"

🔧 Comprobando configuración de Google Cloud CLI

echo -e "${CYAN}" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo    "🔧 COMPROBANDO CONFIGURACIÓN DE GOOGLE CLOUD CLI" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo -e "${RESET}" echo -e "${CYAN}🔧 Comprobando configuración de Google Cloud CLI...${RESET}"

🔍 Verificar si el proyecto GCP está configurado

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

⚠️ Si no hay proyecto activo, iniciar configuración

if [[ -z "$PROJECT_ID" ]]; then echo -e "${YELLOW}" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo    "⚠️ INICIANDO CONFIGURACIÓN DE GCLOUD" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo -e "${RESET}" echo -e "${YELLOW}⚠️ No se detectó un proyecto configurado. Iniciando 'gcloud init'...${RESET}" gcloud init

PROJECT_ID=$(gcloud config get-value project 2>/dev/null) if [[ -z "$PROJECT_ID" ]]; then echo -e "${RED}" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo    "❌ ERROR AL OBTENER ID DEL PROYECTO" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo -e "${RESET}" echo -e "${RED}❌ No se pudo obtener el ID del proyecto después de 'gcloud init'.${RESET}" exit 1 fi fi

✅ Mostrar proyecto activo

echo -e "${GREEN}" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo    "✅ PROYECTO GCP CONFIGURADO" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo -e "${RESET}" echo -e "${GREEN}✅ Proyecto GCP activo: $PROJECT_ID${RESET}"

🖊️ Solicitar nombre para la imagen Docker

echo -e "${BLUE}" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo    "🖊️ INGRESO DE NOMBRE PARA LA IMAGEN DOCKER" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo -e "${RESET}" read -p "🖊️ Ingresa un nombre para tu imagen (sin espacios): " CUSTOM_IMAGE_NAME

if [[ -z "$CUSTOM_IMAGE_NAME" ]]; then echo -e "${RED}" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo    "❌ NOMBRE DE IMAGEN VACÍO" echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo -e "${RESET}" echo -e "${RED}❌ El nombre de la imagen no puede estar vacío.${RESET}" exit 1 fi

📍 Mostrar región seleccionada

(Aquí omito la parte de regiones para ahorrar espacio... mantenla si ya está bien en tu script)

🔄 Limpiar repositorio previo si existe

REPO_DIR="gcp-v2ray" if [[ -d "$REPO_DIR" ]]; then echo -e "${YELLOW}♻️ Eliminando repositorio existente '$REPO_DIR'...${RESET}" rm -rf "$REPO_DIR" fi

📥 Clonar repositorio desde GitHub

echo -e "${CYAN}📥 Clonando repositorio desde GitHub...${RESET}" git clone https://github.com/ChristopherAGT/gcp-v2ray.git cd gcp-v2ray || { echo -e "${RED}❌ No se pudo acceder al directorio del repositorio.${RESET}"; exit 1; }

🧰 Verificar si uuidgen está instalado

if ! command -v uuidgen &> /dev/null; then echo -e "${YELLOW}📦 Instalando uuidgen...${RESET}" sudo apt update && sudo apt install -y uuid-runtime fi

🔐 Generar nuevo UUID

echo -e "${CYAN}🔐 Generando nuevo UUID...${RESET}" NEW_ID=$(uuidgen)

🛠️ Actualizando UUID en config.json

echo -e "${CYAN}🛠️ Actualizando UUID en config.json...${RESET}" sed -i "s/"id":\s*"[^"]*"/"id": "$NEW_ID"/" config.json

🌐 Solicitar nuevo path para WebSocket

echo -e "${BLUE}🌐 Configuración del path WebSocket${RESET}" read -p "🌐 Ingresa el nuevo path para WebSocket (ej: /Cloud-CDN): " WS_PATH

if [[ -z "$WS_PATH" ]]; then echo -e "${YELLOW}⚠️ No se ingresó ningún path. Usando valor por defecto: /Cloud-CDN${RESET}" WS_PATH="/Cloud-CDN" fi

🛠️ Reemplazar el path en config.json

echo -e "${CYAN}🛠️ Actualizando path en config.json...${RESET}" sed -i "s|"path":\s*"[^"]*"|"path": "$WS_PATH"|" config.json

✏️ Edición manual de config.json

nano config.json

🐳 Construir imagen Docker

IMAGE_NAME="gcr.io/$PROJECT_ID/$CUSTOM_IMAGE_NAME" echo -e "${CYAN}🔨 Construyendo imagen Docker...${RESET}" docker build -t "$IMAGE_NAME" .

⏫ Subir imagen a Container Registry

echo -e "${CYAN}📤 Subiendo imagen a Container Registry...${RESET}" docker push "$IMAGE_NAME"

🚀 Desplegar servicio en Cloud Run

echo -e "${CYAN}🌐 Desplegando servicio en Cloud Run...${RESET}" SERVICE_URL=$(gcloud run deploy "$CUSTOM_IMAGE_NAME" 
--image "$IMAGE_NAME" 
--platform managed 
--region "$REGION" 
--allow-unauthenticated 
--port 8080 
--format="value(status.url)")

✅ Mostrar resumen final

echo -e "\n${GREEN}📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo "🔍 INFORMACIÓN ESENCIAL" echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" echo "🗂️ Proyecto GCP        : $PROJECT_ID" echo "📛 Nombre de la Imagen : $CUSTOM_IMAGE_NAME" echo "🆔 UUID Generado       : $NEW_ID" echo "📍 Región Desplegada   : $REGION" echo "🌐 Dominio Google      : $SERVICE_URL" echo -e "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${RESET}"

echo -e "${GREEN}✅ ¡Despliegue completado con éxito!${RESET}"

