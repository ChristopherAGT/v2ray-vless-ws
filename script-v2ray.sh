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

# 🔄 Generar nuevo ID aleatorio
NEW_ID=$(uuidgen)

# 📝 Reemplazar el valor del campo "id" en config.json
echo "🛠️ Reemplazando el ID en config.json..."
sed -i "s/\"id\":\s*\"[^\"]*\"/\"id\": \"$NEW_ID\"/" config.json

# 📝 Abrir config.json en nano para revisión manual
echo "📝 Abriendo config.json en nano. Guarda y cierra el archivo para continuar..."
nano config.json

# 🐳 Construir la imagen de Docker
IMAGE_NAME="gcr.io/$PROJECT_ID/vless-ws"
echo "🔨 Construyendo la imagen Docker..."
docker build -t $IMAGE_NAME .

# ⏫ Subir la imagen al Container Registry
echo "📤 Subiendo la imagen al Container Registry..."
docker push $IMAGE_NAME

# 🚀 Desplegar el servicio en Cloud Run
echo "🌐 Desplegando el servicio en Cloud Run..."
SERVICE_OUTPUT=$(gcloud run deploy vless-ws \
  --image $IMAGE_NAME \
  --platform managed \
  --region us-east1 \
  --allow-unauthenticated \
  --port 8080 \
  --format="value(status.url)")

# 🧾 Mostrar información esencial
echo ""
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 INFORMACIÓN ESENCIAL"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📛 Nombre de la Imagen : $IMAGE_NAME"
echo "🆔 UUID Generado       : $NEW_ID"
echo "🌐 Dominio Google      : $SERVICE_OUTPUT"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ ¡Despliegue completado con éxito!"
