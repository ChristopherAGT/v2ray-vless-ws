#!/bin/bash

# 🛑 Detener el script si ocurre un error
set -e

echo "🔧 Inicializando Google Cloud CLI..."

# Verificar si el proyecto está configurado
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

# Si no hay proyecto, ejecutar gcloud init
if [[ -z "$PROJECT_ID" ]]; then
  echo "⚠️ No se detectó un proyecto configurado. Iniciando 'gcloud init'..."
  gcloud init

  # Volver a obtener el ID del proyecto después de init
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

  if [[ -z "$PROJECT_ID" ]]; then
    echo "❌ No se pudo obtener el ID del proyecto después de 'gcloud init'."
    exit 1
  fi
fi

echo "✅ Proyecto activo: $PROJECT_ID"

# 👉 Solicitar al usuario un nombre personalizado para la imagen
read -p "🖊️ Ingresa un nombre para tu imagen (sin espacios): " CUSTOM_IMAGE_NAME

# Validar nombre no vacío
if [[ -z "$CUSTOM_IMAGE_NAME" ]]; then
  echo "❌ El nombre de la imagen no puede estar vacío."
  exit 1
fi

# 📍 Lista de regiones disponibles
declare -a REGIONS=(
  "us-central1 (Iowa)"
  "us-east1 (South Carolina)"
  "us-east4 (N. Virginia)"
  "us-west1 (Oregon)"
  "us-west2 (Los Angeles)"
  "us-west3 (Salt Lake City)"
  "us-west4 (Las Vegas)"
  "europe-west1 (Belgium)"
  "europe-west2 (London)"
  "europe-west3 (Frankfurt)"
  "europe-west4 (Netherlands)"
  "europe-west6 (Zurich)"
  "europe-west8 (Milan)"
  "europe-west9 (Paris)"
  "europe-southwest1 (Madrid)"
  "asia-east1 (Taiwan)"
  "asia-east2 (Hong Kong)"
  "asia-northeast1 (Tokyo)"
  "asia-northeast2 (Osaka)"
  "asia-northeast3 (Seoul)"
  "asia-south1 (Mumbai)"
  "asia-south2 (Delhi)"
  "asia-southeast1 (Singapore)"
  "asia-southeast2 (Jakarta)"
  "australia-southeast1 (Sydney)"
  "australia-southeast2 (Melbourne)"
  "me-central1 (Doha)"
  "me-west1 (Tel Aviv)"
  "africa-south1 (Johannesburgo)"
)

declare -a REGION_CODES=(
  "us-central1"
  "us-east1"
  "us-east4"
  "us-west1"
  "us-west2"
  "us-west3"
  "us-west4"
  "europe-west1"
  "europe-west2"
  "europe-west3"
  "europe-west4"
  "europe-west6"
  "europe-west8"
  "europe-west9"
  "europe-southwest1"
  "asia-east1"
  "asia-east2"
  "asia-northeast1"
  "asia-northeast2"
  "asia-northeast3"
  "asia-south1"
  "asia-south2"
  "asia-southeast1"
  "asia-southeast2"
  "australia-southeast1"
  "australia-southeast2"
  "me-central1"
  "me-west1"
  "africa-south1"
)

echo "🌍 Selecciona una región para desplegar:"
for i in "${!REGIONS[@]}"; do
  printf "%2d) %s\n" $((i+1)) "${REGIONS[$i]}"
done

read -p "Ingrese el número de la región deseada: " REGION_INDEX
REGION=${REGION_CODES[$((REGION_INDEX-1))]}

if [[ -z "$REGION" ]]; then
  echo "❌ Selección inválida. Abortando."
  exit 1
fi

echo "📍 Región seleccionada: $REGION"

# 🔄 Verificar y limpiar repositorio existente
REPO_DIR="gcp-v2ray"
if [[ -d "$REPO_DIR" ]]; then
  echo "♻️ Eliminando repositorio existente '$REPO_DIR'..."
  rm -rf "$REPO_DIR"
fi

# 📥 Clonar el repositorio
echo "📥 Clonando el repositorio..."
git clone https://github.com/ChristopherAGT/gcp-v2ray.git

# 📁 Ingresar al directorio
cd gcp-v2ray || { echo "❌ No se pudo acceder al directorio del repositorio."; exit 1; }

# 🔄 Verificar si uuidgen está disponible
if ! command -v uuidgen &> /dev/null; then
  echo "📦 Instalando uuidgen..."
  sudo apt update && sudo apt install -y uuid-runtime
fi

# 🔄 Generar nuevo ID aleatorio
NEW_ID=$(uuidgen)

# 🛠️ Reemplazar el ID en config.json
echo "🛠️ Reemplazando el ID en config.json..."
sed -i "s/\"id\":\s*\"[^\"]*\"/\"id\": \"$NEW_ID\"/" config.json

# 📝 Abrir config.json en nano para revisión manual
echo "📝 Abriendo config.json en nano. Guarda y cierra el archivo para continuar..."
nano config.json

# 🐳 Construir la imagen de Docker
IMAGE_NAME="gcr.io/$PROJECT_ID/$CUSTOM_IMAGE_NAME"
echo "🔨 Construyendo la imagen Docker con nombre: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

# ⏫ Subir la imagen al Container Registry
echo "📤 Subiendo la imagen al Container Registry..."
docker push $IMAGE_NAME

# 🚀 Desplegar el servicio en Cloud Run
echo "🌐 Desplegando el servicio en Cloud Run en $REGION..."
DEPLOY_OUTPUT=$(mktemp)
SERVICE_URL=$(gcloud run deploy "$CUSTOM_IMAGE_NAME" \
  --image "$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 | tee "$DEPLOY_OUTPUT")

# Extraer también el dominio final desde el output
SECOND_DOMAIN=$(grep -Eo 'https://[a-zA-Z0-9.-]+\.a\.run\.app' "$DEPLOY_OUTPUT" | tail -n 1)

# 🧾 Mostrar información esencial
echo ""
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 INFORMACIÓN ESENCIAL"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏷️ Proyecto GCP       : $PROJECT_ID"
echo "📛 Nombre de la Imagen : $CUSTOM_IMAGE_NAME"
echo "🆔 UUID Generado       : $NEW_ID"
echo "📍 Región Desplegada   : $REGION"
echo "🌐 Dominio 1 (Deploy)  : $SERVICE_URL"
echo "🌐 Dominio 2 (Service) : $SECOND_DOMAIN"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ ¡Despliegue completado con éxito!"
