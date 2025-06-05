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
echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "🔧 Comprobando configuración de Google Cloud CLI..."
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
  echo -e "${YELLOW}⚠️ No se detectó un proyecto configurado. Iniciando 'gcloud init'...${RESET}"
  gcloud init
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
  
  if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}❌ No se pudo obtener el ID del proyecto después de 'gcloud init'.${RESET}"
    exit 1
  fi
fi

echo -e "${GREEN}✅ Proyecto GCP activo: $PROJECT_ID${RESET}"

# 🖊️ Solicitar nombre para la imagen Docker
echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "🖊️ Ingreso del nombre de la imagen personalizada"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
read -p "🖊️ Ingresa un nombre para tu imagen (sin espacios): " CUSTOM_IMAGE_NAME

if [[ -z "$CUSTOM_IMAGE_NAME" ]]; then
  echo -e "${RED}❌ El nombre de la imagen no puede estar vacío.${RESET}"
  exit 1
fi

# 🌍 Mostrar regiones para selección
echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "🌍 Selección de la región de despliegue"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
declare -a REGIONS=( ... ) # lista completa omitida por brevedad
declare -a REGION_CODES=( ... )

for i in "${!REGIONS[@]}"; do
  printf "%2d) %s\n" $((i+1)) "${REGIONS[$i]}"
done

read -p "Ingrese el número de la región deseada: " REGION_INDEX
REGION=${REGION_CODES[$((REGION_INDEX-1))]}

if [[ -z "$REGION" ]]; then
  echo -e "${RED}❌ Selección inválida. Abortando.${RESET}"
  exit 1
fi

echo -e "${GREEN}📍 Región seleccionada: $REGION${RESET}"

# 📥 Clonar repositorio
echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "📥 Clonando repositorio desde GitHub"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

REPO_DIR="gcp-v2ray"
if [[ -d "$REPO_DIR" ]]; then
  echo -e "${YELLOW}♻️ Eliminando repositorio existente '$REPO_DIR'...${RESET}"
  rm -rf "$REPO_DIR"
fi

git clone https://github.com/ChristopherAGT/gcp-v2ray.git
cd gcp-v2ray || { echo -e "${RED}❌ No se pudo acceder al directorio del repositorio.${RESET}"; exit 1; }

# 🔐 Configuración de UUID
echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "🔐 Generando UUID y editando configuración"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

if ! command -v uuidgen &> /dev/null; then
  echo -e "${YELLOW}📦 Instalando uuidgen...${RESET}"
  sudo apt update && sudo apt install -y uuid-runtime
fi

NEW_ID=$(uuidgen)
sed -i "s/\"id\":\s*\"[^\"]*\"/\"id\": \"$NEW_ID\"/" config.json

echo -e "${BLUE}📝 Abriendo config.json en nano para edición manual...${RESET}"
nano config.json

# 🐳 Construir imagen Docker
echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "🐳 Construyendo imagen Docker"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

IMAGE_NAME="gcr.io/$PROJECT_ID/$CUSTOM_IMAGE_NAME"
docker build -t "$IMAGE_NAME" .

# ⏫ Subir imagen
echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "📤 Subiendo imagen al Container Registry"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
docker push "$IMAGE_NAME"

# 🚀 Desplegar en Cloud Run
echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "🚀 Desplegando servicio en Cloud Run"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
SERVICE_URL=$(gcloud run deploy "$CUSTOM_IMAGE_NAME" \
  --image "$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --format="value(status.url)")

# 📄 Crear archivo con información
echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "📄 Creando archivo informacion.txt"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

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

# Gestión de bucket
echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "☁️ Subiendo informacion.txt a bucket privado"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

BUCKET_NAME="$PROJECT_ID-informacion"

if ! gsutil ls -b gs://"$BUCKET_NAME" &> /dev/null; then
  echo -e "${CYAN}📦 Creando bucket privado $BUCKET_NAME en $REGION...${RESET}"
  gsutil mb -l "$REGION" gs://"$BUCKET_NAME"/
else
  echo -e "${YELLOW}📦 Bucket $BUCKET_NAME ya existe.${RESET}"
fi

gsutil cp informacion.txt gs://"$BUCKET_NAME"/

echo -e "\n${CYAN}🔗 El archivo ha sido subido correctamente al bucket privado.${RESET}"
echo -e "${YELLOW}💡 Para descargar el archivo ejecuta este comando en otra terminal:${RESET}"
echo "    gsutil cp gs://$BUCKET_NAME/informacion.txt ./"
echo ""

# Confirmación y limpieza
echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "🧹 Confirmación para eliminar bucket y archivo"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
read -p "¿Confirmas que descargaste el archivo? (s/n): " RESPUESTA

if [[ "$RESPUESTA" =~ ^[Ss]$ ]]; then
  echo -e "${YELLOW}🗑️ Eliminando archivo y bucket privado...${RESET}"
  gsutil rm gs://"$BUCKET_NAME"/informacion.txt
  gsutil rb gs://"$BUCKET_NAME"/
  echo -e "${GREEN}✅ Archivo y bucket eliminados.${RESET}"
else
  echo -e "${YELLOW}⚠️ Recursos no eliminados. Asegúrate de borrarlos manualmente si ya no los necesitas.${RESET}"
fi
