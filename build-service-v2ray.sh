#!/bin/bash

# 🛑 Detener el script si ocurre un error
set -e

# 🎨 Definición de colores
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

# 📦 Verificar que gcloud, git y docker estén instalados
for cmd in gcloud git docker; do
  if ! command -v $cmd &>/dev/null; then
    echo -e "${RED}❌ El comando '$cmd' no está instalado. Por favor instálalo antes de continuar.${RESET}"
    exit 1
  fi
done

# 🔐 Comprobando si se puede usar sudo sin contraseña
if ! sudo -n true 2>/dev/null; then
  echo -e "${YELLOW}⚠️ Es posible que se te solicite la contraseña de sudo más adelante.${RESET}"
fi

# 🔧 Comprobando configuración de Google Cloud CLI
echo -e "${CYAN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "🔧 COMPROBANDO CONFIGURACIÓN DE GOOGLE CLOUD CLI"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
echo -e "${CYAN}🔧 Comprobando configuración de Google Cloud CLI...${RESET}"

# 🔍 Verificar si el proyecto GCP está configurado
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

# ⚠️ Si no hay proyecto activo, iniciar configuración
if [[ -z "$PROJECT_ID" ]]; then
  echo -e "${YELLOW}"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo    "⚠️ INICIANDO CONFIGURACIÓN DE GCLOUD"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${RESET}"
  echo -e "${YELLOW}⚠️ No se detectó un proyecto configurado. Iniciando 'gcloud init'...${RESET}"
  gcloud init

  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
  if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}"
    echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo    "❌ ERROR AL OBTENER ID DEL PROYECTO"
    echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${RESET}"
    echo -e "${RED}❌ No se pudo obtener el ID del proyecto después de 'gcloud init'.${RESET}"
    exit 1
  fi
fi

# 🔢 Obtener el número del proyecto GCP (Project Number)
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)' 2>/dev/null)

if [[ -z "$PROJECT_NUMBER" ]]; then
  echo -e "${RED}"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo    "❌ ERROR AL OBTENER NÚMERO DEL PROYECTO"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${RESET}"
  echo -e "${RED}❌ No se pudo obtener el número del proyecto (projectNumber).${RESET}"
  exit 1
else
  echo -e "${GREEN}"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo    "🔢 NÚMERO DEL PROYECTO OBTENIDO"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${RESET}"
  echo -e "${GREEN}🔢 Número del proyecto: $PROJECT_NUMBER${RESET}"
fi

# ✅ Mostrar proyecto activo
echo -e "${GREEN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "✅ PROYECTO GCP CONFIGURADO"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
echo -e "${GREEN}✅ Proyecto GCP activo: $PROJECT_ID${RESET}"

# 🖊️ Solicitar nombre para la imagen Docker
echo -e "${BLUE}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "🖊️ INGRESO DE NOMBRE PARA LA IMAGEN DOCKER"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
read -p "🖊️ Ingrese un nombre para tu imagen (sin espacios): " CUSTOM_IMAGE_NAME

if [[ -z "$CUSTOM_IMAGE_NAME" ]]; then
  echo -e "${RED}"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo    "❌ NOMBRE DE IMAGEN VACÍO"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${RESET}"
  echo -e "${RED}❌ El nombre de la imagen no puede estar vacío.${RESET}"
  exit 1
fi

# 🌍 Mostrar regiones para selección
# (Tu lista completa de regiones y códigos permanece intacta)
# ...
# Aquí se encuentra tu lista de REGIONS y REGION_CODES sin cambios

# Mostrar las regiones
for i in "${!REGIONS[@]}"; do
  printf "%2d) %s\n" $((i+1)) "${REGIONS[$i]}"
done

read -p "Ingrese el número de la región deseada: " REGION_INDEX

# Validar índice como número y dentro del rango
if ! [[ "$REGION_INDEX" =~ ^[0-9]+$ ]] || (( REGION_INDEX < 1 || REGION_INDEX > ${#REGION_CODES[@]} )); then
  echo -e "${RED}"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo    "❌ SELECCIÓN DE REGIÓN INVÁLIDA"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${RESET}"
  echo -e "${RED}❌ Selección inválida. Abortando.${RESET}"
  exit 1
fi

REGION=${REGION_CODES[$((REGION_INDEX-1))]}

# 📍 Mostrar región seleccionada
echo -e "${CYAN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "📍 REGIÓN SELECCIONADA"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
echo -e "${GREEN}📍 Región seleccionada: $REGION${RESET}"

# 🔄 Limpiar repositorio previo si existe
REPO_DIR="gcp-v2ray"
if [[ -d "$REPO_DIR" ]]; then
  echo -e "${YELLOW}"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo    "♻️ ELIMINANDO REPOSITORIO PREVIO"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${RESET}"
  echo -e "${YELLOW}♻️ Eliminando repositorio existente '$REPO_DIR'...${RESET}"
  rm -rf "$REPO_DIR"
fi

# 📥 Clonar repositorio desde GitHub
echo -e "${CYAN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "📥 CLONANDO REPOSITORIO"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
echo -e "${CYAN}📥 Clonando repositorio desde GitHub...${RESET}"
git clone https://github.com/ChristopherAGT/gcp-v2ray.git

cd gcp-v2ray || { echo -e "${RED}❌ No se pudo acceder al directorio del repositorio.${RESET}"; exit 1; }

# 🧰 Verificar si uuidgen está instalado
if ! command -v uuidgen &> /dev/null; then
  echo -e "${YELLOW}"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo    "📦 INSTALANDO uuidgen"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${RESET}"
  echo -e "${YELLOW}📦 Instalando uuidgen...${RESET}"
  sudo apt update && sudo apt install -y uuid-runtime
fi

# 🔐 Generar nuevo UUID
echo -e "${GREEN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "🔐 GENERANDO NUEVO UUID"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
NEW_ID=$(uuidgen)

# 🛠️ Actualizando UUID en config.json
echo -e "${GREEN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "🛠️ ACTUALIZANDO UUID EN CONFIG.JSON"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
sed -i "s/\"id\":\s*\"[^\"]*\"/\"id\": \"$NEW_ID\"/" config.json

# 🌐 Solicitar nuevo path para WebSocket
echo -e "${BLUE}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "🌐 CONFIGURACIÓN DEL PATH WEBSOCKET"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
read -p "🌐 Ingresa el nuevo path para WebSocket (ej: /Cloud-CDN): " WS_PATH

if [[ -z "$WS_PATH" ]]; then
  echo -e "${YELLOW}⚠️ No se ingresó ningún path. Usando valor por defecto: /Cloud-CDN${RESET}"
  WS_PATH="/Cloud-CDN"
fi

# 🛠️ Reemplazar el path en config.json
echo -e "${BLUE}🛠️ Actualizando path en config.json...${RESET}"
sed -i "s|\"path\":\s*\"[^\"]*\"|\"path\": \"$WS_PATH\"|" config.json

# ✏️ Edición manual de config.json
echo -e "${BLUE}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "📝 EDICIÓN MANUAL DE CONFIG.JSON"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
nano config.json

# 🐳 Construir imagen Docker
IMAGE_NAME="gcr.io/$PROJECT_ID/$CUSTOM_IMAGE_NAME"
echo -e "${CYAN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "🔨 CONSTRUYENDO IMAGEN DOCKER"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
docker build -t "$IMAGE_NAME" .

# ⏫ Subir imagen a Container Registry
echo -e "${CYAN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "📤 SUBIENDO IMAGEN A CONTAINER REGISTRY"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
docker push "$IMAGE_NAME"

# 🚀 Desplegar servicio en Cloud Run
echo -e "${CYAN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "🌐 DESPLEGANDO SERVICIO EN CLOUD RUN"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
SERVICE_URL=$(gcloud run deploy "$CUSTOM_IMAGE_NAME" \
  --image "$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --format="value(status.url)")

REGIONAL_DOMAIN="https://${CUSTOM_IMAGE_NAME}-${PROJECT_NUMBER}.${REGION}.run.app"

# ✅ Mostrar resumen final
echo -e "\n${BLUE}📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 INFORMACIÓN ESENCIAL"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗂️ ID del Proyecto GCP : $PROJECT_ID"
echo "🔢 Número de Proyecto  : $PROJECT_NUMBER"
echo "📛 Nombre de la Imagen : $CUSTOM_IMAGE_NAME"
echo "📍 Región Desplegada   : $REGION"
echo "🆔 UUID Generado       : $NEW_ID"
echo "🌐 Path WebSocket      : $WS_PATH"
echo "🌐 Dominio Clásico     : $SERVICE_URL"
echo "🌐 Dominio Regional    : $REGIONAL_DOMAIN"
echo -e "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${RESET}"

echo -e "${GREEN}✅ ¡Despliegue completado con éxito!${RESET}"
