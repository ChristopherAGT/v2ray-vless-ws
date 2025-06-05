#!/bin/bash
set -e

echo "🔧 Inicializando Google Cloud CLI..."
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
  echo "⚠️ No se detectó un proyecto configurado. Iniciando 'gcloud init'..."
  gcloud init
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
  if [[ -z "$PROJECT_ID" ]]; then
    echo "❌ No se pudo obtener el ID del proyecto después de 'gcloud init'."
    exit 1
  fi
fi

echo "✅ Proyecto activo: $PROJECT_ID"

echo "📥 Clonando el repositorio..."
git clone https://github.com/ChristopherAGT/gcp-v2ray.git
cd gcp-v2ray || { echo "❌ No se pudo acceder al directorio del repositorio."; exit 1; }

if ! command -v uuidgen &> /dev/null; then
  echo "📦 Instalando uuidgen..."
  sudo apt update && sudo apt install -y uuid-runtime
fi

NEW_ID=$(uuidgen)

echo "🛠️ Reemplazando el ID en config.json..."
sed -i "s/\"id\":\s*\"[^\"]*\"/\"id\": \"$NEW_ID\"/" config.json

echo "📝 Abriendo config.json en nano. Guarda y cierra el archivo para continuar..."
nano config.json

IMAGE_NAME="gcr.io/$PROJECT_ID/vless-ws"
echo "🔨 Construyendo la imagen Docker..."
docker build -t $IMAGE_NAME .

echo "📤 Subiendo la imagen al Container Registry..."
docker push $IMAGE_NAME

echo "🌐 Desplegando el servicio en Cloud Run..."
DEPLOY_OUTPUT=$(gcloud run deploy vless-ws \
  --image $IMAGE_NAME \
  --platform managed \
  --region us-east1 \
  --allow-unauthenticated \
  --port 8080)

# Extraer la línea con el Service URL (primera URL oficial que imprime gcloud)
SERVICE_URL=$(echo "$DEPLOY_OUTPUT" | grep -Eo 'https://[a-zA-Z0-9.-]+\.run\.app' | head -n 1)

# Extra adicional: si hay otra URL distinta, capturarla también
SECOND_URL=$(echo "$DEPLOY_OUTPUT" | grep -Eo 'https://[a-zA-Z0-9.-]+\.run\.app' | sed -n 2p)

echo ""
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 INFORMACIÓN ESENCIAL"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📛 Nombre de la Imagen : $IMAGE_NAME"
echo "🆔 UUID Generado       : $NEW_ID"
echo "🌐 Dominio Google 1    : ${SERVICE_URL:-No detectado}"
echo "🌐 Dominio Google 2    : ${SECOND_URL:-No detectado}"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ ¡Despliegue completado con éxito!"
