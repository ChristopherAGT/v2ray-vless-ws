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

  # Volver a obtener el proyecto tras la inicialización
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

# Validar que el nombre no esté vacío
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
  "us-central1 (Iowa)" "us-east1 (South Carolina)" "us-east4 (N. Virginia)" 
  "us-west1 (Oregon)" "us-west2 (Los Angeles)" "us-west3 (Salt Lake City)" 
  "us-west4 (Las Vegas)" "europe-west1 (Belgium)" "europe-west2 (London)" 
  "europe-west3 (Frankfurt)" "europe-west4 (Netherlands)" "europe-west6 (Zurich)" 
  "europe-west8 (Milan)" "europe-west9 (Paris)" "europe-southwest1 (Madrid)" 
  "asia-east1 (Taiwan)" "asia-east2 (Hong Kong)" "asia-northeast1 (Tokyo)" 
  "asia-northeast2 (Osaka)" "asia-northeast3 (Seoul)" "asia-south1 (Mumbai)" 
  "asia-south2 (Delhi)" "asia-southeast1 (Singapore)" "asia-southeast2 (Jakarta)" 
  "australia-southeast1 (Sydney)" "australia-southeast2 (Melbourne)" 
  "me-central1 (Doha)" "me-west1 (Tel Aviv)" "africa-south1 (Johannesburgo)"
)

declare -a REGION_CODES=(
  "us-central1" "us-east1" "us-east4" 
  "us-west1" "us-west2" "us-west3" 
  "us-west4" "europe-west1" "europe-west2" 
  "europe-west3" "europe-west4" "europe-west6" 
  "europe-west8" "europe-west9" "europe-southwest1" 
  "asia-east1" "asia-east2" "asia-northeast1" 
  "asia-northeast2" "asia-northeast3" "asia-south1" 
  "asia-south2" "asia-southeast1" "asia-southeast2" 
  "australia-southeast1" "australia-southeast2" 
  "me-central1" "me-west1" "africa-south1"
)

for i in "${!REGIONS[@]}"; do
  printf "%2d) %s\n" $((i+1)) "${REGIONS[$i]}"
done

read -p "Ingrese el número de la región deseada: " REGION_INDEX
REGION=${REGION_CODES[$((REGION_INDEX-1))]}

# Validar selección de región
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

# 📁 Entrar al directorio clonado
cd gcp-v2ray || { echo -e "${RED}❌ No se pudo acceder al directorio del repositorio.${RESET}"; exit 1; }

# 🧰 Verificar si uuidgen está instalado, instalar si no
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

# ✏️ Abrir config.json para edición manual
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

# 📄 Crear archivo con información esencial
echo -e "${BLUE}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "📄 CREANDO ARCHIVO DE INFORMACIÓN"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
cat > informacion.txt <<EOF
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 INFORMACIÓN ESENCIAL
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗂️ Proyecto GCP       : $PROJECT_ID
📛 Nombre de la Imagen : $CUSTOM_IMAGE_NAME
🆔 UUID Generado       : $NEW_ID
📍 Región Desplegada   : $REGION
🌐 Dominio Google      : $SERVICE_URL
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

# Mostrar información en pantalla
echo -e "\n${GREEN}📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 INFORMACIÓN ESENCIAL"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗂️ Proyecto GCP       : $PROJECT_ID"
echo "📛 Nombre de la Imagen : $CUSTOM_IMAGE_NAME"
echo "🆔 UUID Generado       : $NEW_ID"
echo "📍 Región Desplegada   : $REGION"
echo "🌐 Dominio Google      : $SERVICE_URL"
echo -e "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${RESET}"

echo -e "${GREEN}✅ ¡Despliegue completado con éxito!${RESET}"

# --- Gestión de bucket privado para almacenamiento temporal ---

BUCKET_NAME="$PROJECT_ID-informacion"

if ! gsutil ls -b gs://"$BUCKET_NAME" &> /dev/null; then
  echo -e "${CYAN}"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo    "📦 CREANDO BUCKET PRIVADO"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${RESET}"
  echo -e "${CYAN}📦 Creando bucket privado $BUCKET_NAME en $REGION...${RESET}"
  gsutil mb -l "$REGION" gs://"$BUCKET_NAME"/
else
  echo -e "${YELLOW}"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo    "📦 BUCKET YA EXISTE"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${RESET}"
  echo -e "${YELLOW}📦 Bucket $BUCKET_NAME ya existe.${RESET}"
fi

# 📤 Subir archivo informacion.txt al bucket privado
echo -e "${CYAN}"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo    "📤 SUBIENDO ARCHIVO AL BUCKET PRIVADO"
echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
gsutil cp informacion.txt gs://"$BUCKET_NAME"/

# 🔗 Confirmación de subida
echo -e "\n${CYAN}🔗 El archivo ha sido subido correctamente al bucket privado.${RESET}"
echo -e "${YELLOW}💡 Para descargar el archivo ejecuta este comando en otra terminal:${RESET}"
echo "    gsutil cp gs://$BUCKET_NAME/informacion.txt ./"
echo ""

read -p "¿Confirmas que descargaste el archivo? (s/n): " RESPUESTA

if [[ "$RESPUESTA" =~ ^[Ss]$ ]]; then
  echo -e "${YELLOW}"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo    "🗑️ ELIMINANDO ARCHIVO Y BUCKET"
  echo    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${RESET}"
  gsutil rm gs://"$BUCKET_NAME"/informacion.txt
  gsutil rb gs://"$BUCKET_NAME"/
  echo -e "${GREEN}✅ Archivo y bucket eliminados.${RESET}"
else
  echo -e "${YELLOW}⚠️ Recursos no eliminados. Asegúrate de borrarlos manualmente si ya no los necesitas.${RESET}"
fi
