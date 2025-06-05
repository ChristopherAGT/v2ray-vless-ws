#!/bin/bash

# ==========================
# 🎯 Script de Despliegue GCP Automático
# ==========================
# Este script:
#  - Verifica y configura el proyecto de GCP
#  - Clona el repo de V2Ray
#  - Genera un UUID aleatorio
#  - Construye y sube una imagen Docker
#  - Despliega en Cloud Run
#  - Guarda y sube la info a Cloud Storage
# ==========================

set -e  # 🛑 Detiene el script si ocurre un error

# 🎨 Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Sin color

# 🔧 Inicialización
echo -e "${BLUE}🔧 Inicializando Google Cloud CLI...${NC}"
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
  echo -e "${YELLOW}⚠️ No se detectó un proyecto configurado. Iniciando 'gcloud init'...${NC}"
  gcloud init
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
  if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}❌ No se pudo obtener el ID del proyecto.${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}✅ Proyecto GCP activo: $PROJECT_ID${NC}"

# 🖊️ Ingreso del nombre de la imagen
read -p "🖊️ Ingresa un nombre para tu imagen (sin espacios): " CUSTOM_IMAGE_NAME
if [[ -z "$CUSTOM_IMAGE_NAME" ]]; then
  echo -e "${RED}❌ El nombre no puede estar vacío.${NC}"
  exit 1
fi

# 🌍 Selección de Región
declare -a REGIONS=(...)
declare -a REGION_CODES=(...)

echo -e "${BLUE}🌍 Selecciona una región para desplegar:${NC}"
for i in "${!REGIONS[@]}"; do
  printf "%2d) %s\n" $((i+1)) "${REGIONS[$i]}"
done

read -p "Ingrese el número de la región deseada: " REGION_INDEX
REGION=${REGION_CODES[$((REGION_INDEX-1))]}

if [[ -z "$REGION" ]]; then
  echo -e "${RED}❌ Selección inválida. Abortando.${NC}"
  exit 1
fi
echo -e "${GREEN}📍 Región seleccionada: $REGION${NC}"

# ♻️ Clonación del repositorio
REPO_DIR="gcp-v2ray"
[[ -d "$REPO_DIR" ]] && echo -e "${YELLOW}♻️ Eliminando repositorio anterior...${NC}" && rm -rf "$REPO_DIR"
echo -e "${BLUE}📥 Clonando repositorio...${NC}"
git clone https://github.com/ChristopherAGT/gcp-v2ray.git
cd gcp-v2ray || { echo -e "${RED}❌ No se pudo acceder al directorio.${NC}"; exit 1; }

# 🆔 Generar UUID
command -v uuidgen &> /dev/null || { echo -e "${YELLOW}📦 Instalando uuidgen...${NC}"; sudo apt update && sudo apt install -y uuid-runtime; }
NEW_ID=$(uuidgen)
echo -e "${BLUE}🛠️ Reemplazando ID en config.json...${NC}"
sed -i "s/\"id\":\s*\"[^\"]*\"/\"id\": \"$NEW_ID\"/" config.json

# 📝 Edición manual
echo -e "${YELLOW}📝 Revisa y guarda config.json en nano...${NC}"
nano config.json

# 🐳 Docker Build & Push
IMAGE_NAME="gcr.io/$PROJECT_ID/$CUSTOM_IMAGE_NAME"
echo -e "${BLUE}🔨 Construyendo imagen Docker: $IMAGE_NAME${NC}"
docker build -t $IMAGE_NAME .

echo -e "${BLUE}📤 Subiendo imagen al Container Registry...${NC}"
docker push $IMAGE_NAME

# 🚀 Despliegue en Cloud Run
echo -e "${BLUE}🌐 Desplegando en Cloud Run...${NC}"
SERVICE_OUTPUT=$(gcloud run deploy "$CUSTOM_IMAGE_NAME" \
  --image "$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --format="value(status.url)")

# 📄 Crear archivo de información
INFO_FILE="informacion.txt"
cat > $INFO_FILE <<EOF
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 INFORMACIÓN ESENCIAL
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗂️ Proyecto GCP       : $PROJECT_ID
📛 Nombre de la Imagen : $CUSTOM_IMAGE_NAME
🆔 UUID Generado       : $NEW_ID
📍 Región Desplegada   : $REGION
🌐 Dominio Google      : $SERVICE_OUTPUT
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

# 📤 Mostrar info
echo -e "${GREEN}"
cat $INFO_FILE
echo -e "${NC}"

# ☁️ Gestión del bucket
BUCKET_NAME="$PROJECT_ID-informacion"
if ! gsutil ls -b gs://$BUCKET_NAME &> /dev/null; then
  echo -e "${BLUE}📦 Creando bucket $BUCKET_NAME...${NC}"
  gsutil mb -l "$REGION" gs://$BUCKET_NAME/
else
  echo -e "${YELLOW}📦 Bucket ya existe.${NC}"
fi

echo -e "${BLUE}📤 Subiendo información al bucket...${NC}"
gsutil cp $INFO_FILE gs://$BUCKET_NAME/

# 🗑️ Confirmación antes de eliminar
echo -e "${YELLOW}💡 Para descargar el archivo usa:${NC}"
echo -e "${BLUE}    gsutil cp gs://$BUCKET_NAME/$INFO_FILE ./ ${NC}"
read -p "¿Confirmas que descargaste el archivo? (s/n): " RESPUESTA

if [[ "$RESPUESTA" =~ ^[sS]$ ]]; then
  echo -e "${BLUE}🗑️ Eliminando archivo y bucket...${NC}"
  gsutil rm gs://$BUCKET_NAME/$INFO_FILE
  gsutil rb gs://$BUCKET_NAME/
  echo -e "${GREEN}✅ Recursos eliminados correctamente.${NC}"
else
  echo -e "${YELLOW}⚠️ Recuerda eliminar el archivo y bucket manualmente si ya no los necesitas.${NC}"
fi
