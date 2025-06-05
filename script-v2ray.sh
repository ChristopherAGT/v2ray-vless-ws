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

# 🔄 Clonar el repositorio
echo "📥 Clonando el repositorio..."
git clone https://github.com/ChristopherAGT/gcp-v2ray.git

# 📁 Ingresar al directorio
cd gcp-v2ray || { echo "❌ No se pudo acceder al directorio del repositorio."; exit 1; }

# 🐳 Construir la imagen de Docker
echo "🔨 Construyendo la imagen Docker..."
docker build -t gcr.io/$PROJECT_ID/vless-ws .

# ⏫ Subir la imagen al Container Registry
echo "📤 Subiendo la imagen al Container Registry..."
docker push gcr.io/$PROJECT_ID/vless-ws

# 🚀 Desplegar el servicio en Cloud Run
echo "🌐 Desplegando el servicio en Cloud Run..."
gcloud run deploy vless-ws \
  --image gcr.io/$PROJECT_ID/vless-ws \
  --platform managed \
  --region us-east1 \
  --allow-unauthenticated \
  --port 8080

echo "✅ ¡Despliegue completado con éxito!"
