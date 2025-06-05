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
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
  if [[ -z "$PROJECT_ID" ]]; then
    echo "❌ No se pudo obtener el ID del proyecto después de 'gcloud init'."
    exit 1
  fi
fi

echo "✅ Proyecto activo: $PROJECT_ID"

# 🔄 Clonar el repositorio
echo "📥 Clonando el repositorio..."
git clone https://github.com/ChristopherAGT/gcp-v2ray.git

cd gcp-v2ray || { echo "❌ No se pudo acceder al directorio del repositorio."; exit 1; }

# 🔄 Verificar si uuidgen está disponible
if ! command -v uuidgen &> /dev/null; then
  echo "📦 Instalando uuidgen..."
  sudo apt update && sudo apt install -y uuid-runtime
fi

# 🔄 Generar UUID
NEW_ID=$(uuidgen)

# 🛠️ Reemplazar UUID en config.json
echo "🛠️ Reemplazando el ID en config.json..."
sed -i "s/\"id\":\s*\"[^\"]*\"/\"id\": \"$NEW_ID\"/" config.json

# ✍️ Revisión manual
echo "📝 Abriendo config.json en nano. Guarda y cierra el archivo para continuar..."
nano config.json

# 🐳 Build y Push
IMAGE_NAME="gcr.io/$PROJECT_ID/vless-ws"
echo "🔨 Construyendo la imagen Docker..."
docker build -t $IMAGE_NAME .

echo "📤 Subiendo la imagen al Container Registry..."
docker push $IMAGE_NAME

# 🌐 Desplegar y capturar salida completa
echo "🌐 Desplegando el servicio en Cloud Run..."
DEPLOY_OUTPUT=$(gcloud run deploy vless-ws \
  --image $IMAGE_NAME \
  --platform managed \
  --region us-east1 \
  --allow-unauthenticated \
  --port 8080)

# 🧩 Extraer ambas URLs
DOMINIO_1=$(echo "$DEPLOY_OUTPUT" | grep -oP 'https://[^\s]+' | sed -n 1p)
DOMINIO_2=$(echo "$DEPLOY_OUTPUT" | grep -oP 'https://[^\s]+' | sed -n 2p)

# 📦 Mostrar todo al final
echo ""
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 INFORMACIÓN ESENCIAL"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📛 Nombre de la Imagen : $IMAGE_NAME"
echo "🆔 UUID Generado       : $NEW_ID"
echo "🌐 Dominio Google 1    : $DOMINIO_1"
echo "🌐 Dominio Google 2    : $DOMINIO_2"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ ¡Despliegue completado con éxito!"
