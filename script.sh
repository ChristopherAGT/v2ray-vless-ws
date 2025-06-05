#!/bin/bash

# Detener el script si hay un error
set -e

# Obtener el ID del proyecto actual de GCP
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
  echo "❌ No se pudo obtener el ID del proyecto. Asegúrate de haber ejecutado 'gcloud init'."
  exit 1
fi

echo "✅ Proyecto activo: $PROJECT_ID"

# Clonar el repositorio
echo "🔄 Clonando el repositorio..."
git clone https://github.com/ChristopherAGT/gcp-v2ray.git

# Ingresar al directorio
cd gcp-v2ray || { echo "❌ No se pudo acceder al directorio del repositorio."; exit 1; }

# Construir la imagen de Docker
echo "🐳 Construyendo la imagen Docker..."
docker build -t gcr.io/$PROJECT_ID/vless-ws .

# Subir la imagen al Container Registry
echo "⏫ Subiendo la imagen al Container Registry..."
docker push gcr.io/$PROJECT_ID/vless-ws

# Desplegar el servicio en Cloud Run
echo "🚀 Desplegando en Cloud Run..."
gcloud run deploy vless-ws \
  --image gcr.io/$PROJECT_ID/vless-ws \
  --platform managed \
  --region us-east1 \
  --allow-unauthenticated \
  --port 8080

echo "✅ Despliegue completo."
