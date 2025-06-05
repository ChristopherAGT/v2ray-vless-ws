#!/bin/bash

# ============================================================
# 🚀 Script de Despliegue Automático en Google Cloud Platform
# Autor: Tú
# Descripción: Automatiza la configuración de entorno, construcción
#              de imagen Docker, despliegue en Cloud Run, y
#              almacenamiento temporal en Cloud Storage.
# ============================================================

# 🛑 Detener ejecución ante errores
set -e

# 🎨 Colores ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Sin color

echo -e "${CYAN}🔧 Inicializando Google Cloud CLI...${NC}"

# Verificar configuración de proyecto
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
  echo -e "${YELLOW}⚠️ No se detectó un proyecto. Ejecutando 'gcloud init'...${NC}"
  gcloud init
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
  if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}❌ No se pudo obtener el ID del proyecto.${NC}"
    exit 1
  fi
fi
echo -e "${GREEN}✅ Proyecto GCP activo: ${PROJECT_ID}${NC}"

# 👉 Solicitar nombre para la imagen
read -p "🖊️ Ingresa un nombre para tu imagen (sin espacios): " CUSTOM_IMAGE_NAME
if [[ -z "$CUSTOM_IMAGE_NAME" ]]; then
  echo -e "${RED}❌ El nombre de la imagen no puede estar vacío.${NC}"
  exit 1
fi

# 🌍 Selección de región
declare -a REGIONS=(... # <--- omitido por brevedad, igual que en tu original)
declare -a REGION_CODES=(... # <--- idem)

echo -e "${CYAN}🌍 Selecciona una región para desplegar:${NC}"
for i in "${!REGIONS[@]}"; do
  printf "%2d) %s\n" $((i+1)) "${REGIONS[$i]}"
done

read -p "📌 Ingrese el número de la región deseada: " REGION_INDEX
REGION=${REGION_CODES[$((REGION_INDEX-1))]}
if [[ -z "$REGION" ]]; then
  echo -e "${RED}❌ Selección inválida. Abortando.${NC}"
  exit 1
fi
echo -e "${GREEN}📍 Región seleccionada: $REGION${NC}"

# 🔄 Manejo de repositorio
REPO_DIR="gcp-v2ray"
if [[ -d "$REPO_DIR" ]]; then
  echo -e "${YELLOW}♻️ Eliminando repositorio existente '$REPO_DIR'...${NC}"
  rm -rf "$REPO_DIR"
fi

echo -e "${CYAN}📥 Clonando el repositorio...${NC}"
git clone https://github.com/ChristopherAGT/gcp-v2ray.git
cd gcp-v2ray || { echo -e "${RED}❌ Error accediendo al directorio.${NC}"; exit 1; }

# 🔧 UUID y configuración
if ! command -v uuidgen &> /dev/null; then
  echo -e "${YELLOW}📦 Instalando uuidgen...${NC}"
  sudo apt update && sudo apt install -y uuid-runtime
fi

NEW_ID=$(uuidgen)
echo -e "${CYAN}🛠️ Reemplazando UUID en config.json...${NC}"
sed -i "s/\"id\":\s*\"[^\"]*\"/\"id\": \"$NEW_ID\"/" config.json

echo -e "${BLUE}📝 Abriendo config.json en nano para revisión...${NC}"
nano config.json

# 🐳 Construcción de imagen Docker
IMAGE_NAME="gcr.io/$PROJECT_ID/$CUSTOM_IMAGE_NAME"
echo -e "${CYAN}🔨 Construyendo imagen Docker: $IMAGE_NAME${NC}"
docker build -t $IMAGE_NAME .

# ⏫ Subida a Container Registry
echo -e "${CYAN}📤 Subiendo imagen a Container Registry...${NC}"
docker push $IMAGE_NAME

# 🚀 Despliegue en Cloud Run
echo -e "${CYAN}🌐 Desplegando servicio en Cloud Run...${NC}"
SERVICE_OUTPUT=$(gcloud run deploy "$CUSTOM_IMAGE_NAME" \
  --image "$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --format="value(status.url)")

# 📄 Guardar información clave
cat > informacion.txt <<EOF
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 INFORMACIÓN ESENCIAL
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗂️ Proyecto GCP       : $PROJECT_ID
📛 Nombre de la Imagen : $CUSTOM_IMAGE_NAME
🆔 UUID Generado       : $NEW_ID
📍 Región Desplegada   : $REGION
🌐 Dominio Google      : $SERVICE_OUTPUT
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

# 📄 Mostrar resumen en pantalla
echo ""
cat informacion.txt
echo ""

# ☁️ Bucket privado para almacenamiento
BUCKET_NAME="$PROJECT_ID-informacion"
if ! gsutil ls -b gs://$BUCKET_NAME &> /dev/null; then
  echo -e "${CYAN}📦 Creando bucket privado: $BUCKET_NAME...${NC}"
  gsutil mb -l "$REGION" gs://$BUCKET_NAME/
else
  echo -e "${YELLOW}📦 Bucket $BUCKET_NAME ya existe.${NC}"
fi

echo -e "${CYAN}📤 Subiendo informacion.txt al bucket...${NC}"
gsutil cp informacion.txt gs://$BUCKET_NAME/

echo -e "${GREEN}🔗 Archivo subido exitosamente.${NC}"
echo -e "💡 Puedes descargarlo con:\n    ${BLUE}gsutil cp gs://$BUCKET_NAME/informacion.txt ./ ${NC}"
echo ""

# ✅ Limpieza final
read -p "¿Confirmas que descargaste el archivo? (s/n): " RESPUESTA
if [[ "$RESPUESTA" =~ ^[sS]$ ]]; then
  echo -e "${YELLOW}🗑️ Eliminando archivo y bucket...${NC}"
  gsutil rm gs://$BUCKET_NAME/informacion.txt
  gsutil rb gs://$BUCKET_NAME/
  echo -e "${GREEN}✅ Eliminación completada.${NC}"
else
  echo -e "${YELLOW}⚠️ No se eliminaron los recursos. Hazlo manualmente si lo deseas.${NC}"
fi
