#!/bin/bash

# 🛑 Detener el script si ocurre un error
set -e

# 🎨 Definición de colores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
RESET="\033[0m"

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
read -p "🖊️ Ingresa un nombre para tu imagen (sin espacios): " CUSTOM_IMAGE_NAME

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
echo -e "${BLUE}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "🌍 SELECCIÓN DE REGIÓN DE DESPLIEGUE"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
declare -a REGIONS=(
  "🇺🇸 us-central1 (Iowa)"
  "🇺🇸 us-east1 (Carolina del Sur)"
  "🇺🇸 us-east4 (Virginia del Norte)"
  "🇺🇸 us-west1 (Oregón)"
  "🇺🇸 us-west2 (Los Ángeles)"
  "🇺🇸 us-west3 (Salt Lake City)"
  "🇺🇸 us-west4 (Las Vegas)"
  "🇨🇦 northamerica-northeast1 (Montreal)"
  "🇨🇦 northamerica-northeast2 (Toronto)"
  "🇧🇷 southamerica-east1 (São Paulo)"
  "🇪🇺 europe-north1 (Finlandia)"
  "🇪🇺 europe-west1 (Bélgica)"
  "🇪🇺 europe-west2 (Londres)"
  "🇪🇺 europe-west3 (Frankfurt)"
  "🇪🇺 europe-west4 (Países Bajos)"
  "🇪🇺 europe-west6 (Zúrich)"
  "🇦🇺 australia-southeast1 (Sídney)"
  "🇦🇺 australia-southeast2 (Melbourne)"
  "🇯🇵 asia-northeast1 (Tokio)"
  "🇯🇵 asia-northeast2 (Osaka)"
  "🇯🇵 asia-northeast3 (Tokio)"
  "🇰🇷 asia-northeast4 (Seúl)"
  "🇸🇬 asia-southeast1 (Singapur)"
  "🇮🇩 asia-southeast2 (Yakarta)"
  "🇮🇳 asia-south1 (Mumbai)"
  "🇮🇳 asia-south2 (Delhi)"
  "🇭🇰 asia-east2 (Hong Kong)"
  "🇹🇼 asia-east1 (Taiwán)"
  "🇨🇱 southamerica-west1 (Santiago)"
  "🇲🇽 northamerica-northeast3 (Querétaro)"
)
declare -a REGION_CODES=(
  "us-central1"
  "us-east1"
  "us-east4"
  "us-west1"
  "us-west2"
  "us-west3"
  "us-west4"
  "northamerica-northeast1"
  "northamerica-northeast2"
  "southamerica-east1"
  "europe-north1"
  "europe-west1"
  "europe-west2"
  "europe-west3"
  "europe-west4"
  "europe-west6"
  "australia-southeast1"
  "australia-southeast2"
  "asia-northeast1"
  "asia-northeast2"
  "asia-northeast3"
  "asia-northeast4"
  "asia-southeast1"
  "asia-southeast2"
  "asia-south1"
  "asia-south2"
  "asia-east2"
  "asia-east1"
  "southamerica-west1"
  "northamerica-northeast3"
)

for i in "${!REGIONS[@]}"; do
  printf "%2d) %s\n" $((i+1)) "${REGIONS[$i]}"
done

read -p "Ingrese el número de la región deseada: " REGION_INDEX
REGION=${REGION_CODES[$((REGION_INDEX-1))]}

if [[ -z "$REGION" ]]; then
  echo -e "${RED}"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo    "❌ SELECCIÓN DE REGIÓN INVÁLIDA"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${RESET}"
  echo -e "${RED}❌ Selección inválida. Abortando.${RESET}"
  exit 1
fi

# 📍 Mostrar región seleccionada
echo -e "${GREEN}"
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
echo -e "${CYAN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "🔐 GENERANDO NUEVO UUID"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
NEW_ID=$(uuidgen)

# 🛠️ Actualizando UUID en config.json
echo -e "${CYAN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "🛠️ ACTUALIZANDO UUID EN CONFIG.JSON"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
sed -i "s/\"id\":\s*\"[^\"]*\"/\"id\": \"$NEW_ID\"/" config.json

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

# ✅ Mostrar resumen final
echo -e "\n${GREEN}📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 INFORMACIÓN ESENCIAL"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗂️ Proyecto GCP        : $PROJECT_ID"
echo "📛 Nombre de la Imagen : $CUSTOM_IMAGE_NAME"
echo "🆔 UUID Generado       : $NEW_ID"
echo "📍 Región Desplegada   : $REGION"
echo "🌐 Dominio Google      : $SERVICE_URL"
echo -e "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${RESET}"

echo -e "${GREEN}✅ ¡Despliegue completado con éxito!${RESET}"
