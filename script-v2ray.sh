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

echo "✅ Proyecto GCP activo: $PROJECT_ID"

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

# 📝 Reemplazar el valor del campo "id" en config.json
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

# 🚀 Desplegar el servicio en Cloud Run usando la región seleccionada
echo "🌐 Desplegando el servicio en Cloud Run en $REGION..."
SERVICE_OUTPUT=$(gcloud run deploy "$CUSTOM_IMAGE_NAME" \
  --image "$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --format="value(status.url)")

# Crear archivo informacion.txt con los datos esenciales
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

echo ""
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 INFORMACIÓN ESENCIAL"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗂️ Proyecto GCP       : $PROJECT_ID"
echo "📛 Nombre de la Imagen : $CUSTOM_IMAGE_NAME"
echo "🆔 UUID Generado       : $NEW_ID"
echo "📍 Región Desplegada   : $REGION"
echo "🌐 Dominio Google      : $SERVICE_OUTPUT"
echo "📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ ¡Despliegue completado con éxito!"

# --- Gestión de bucket privado para almacenamiento temporal ---

BUCKET_NAME="$PROJECT_ID-informacion"

# Crear bucket privado (ignorar error si ya existe)
if ! gsutil ls -b gs://$BUCKET_NAME &> /dev/null; then
  echo "📦 Creando bucket privado $BUCKET_NAME en $REGION..."
  gsutil mb -l "$REGION" gs://$BUCKET_NAME/
else
  echo "📦 Bucket $BUCKET_NAME ya existe."
fi

# Subir archivo informacion.txt al bucket privado
echo "📤 Subiendo informacion.txt a gs://$BUCKET_NAME/"
gsutil cp informacion.txt gs://$BUCKET_NAME/

echo ""
echo "🔗 Archivo subido a bucket privado."
echo "💡 Para descargar el archivo ejecuta este comando en otra terminal:"
echo "    gsutil cp gs://$BUCKET_NAME/informacion.txt ./"
echo ""

# Esperar confirmación de descarga antes de eliminar
read -p "¿Confirmas que descargaste el archivo? (s/n): " RESPUESTA

if [[ "$RESPUESTA" == "s" || "$RESPUESTA" == "S" ]]; then
  echo "🗑️ Eliminando archivo y bucket privado..."

  # Eliminar archivo
  gsutil rm gs://$BUCKET_NAME/informacion.txt

  # Eliminar bucket (debe estar vacío)
  gsutil rb gs://$BUCKET_NAME/

  echo "✅ Archivo y bucket eliminados."
else
  echo "⚠️ No se eliminaron los recursos. Recuerda eliminarlos manualmente si no los necesitas."
fi
