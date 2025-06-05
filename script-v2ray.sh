#!/bin/bash

🚨 Detener el script ante cualquier error

set -e

-------------------------------

🎯 Verificar configuración inicial

-------------------------------

echo -e "\n🔍 Comprobando configuración de Google Cloud CLI..." PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then echo "⚠️  No se detectó un proyecto configurado. Ejecutando 'gcloud init'..." gcloud init PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then echo "❌ No se pudo obtener el ID del proyecto tras 'gcloud init'. Abortando." exit 1 fi fi

echo "✅ Proyecto GCP activo: $PROJECT_ID"

-------------------------------

📛 Nombre personalizado para la imagen

-------------------------------

echo read -p "🖊️  Ingresa un nombre para tu imagen (sin espacios): " CUSTOM_IMAGE_NAME

if [[ -z "$CUSTOM_IMAGE_NAME" ]]; then echo "❌ El nombre de la imagen no puede estar vacío." exit 1 fi

-------------------------------

🌍 Selección de región

-------------------------------

declare -a REGIONS=( "us-central1 (Iowa)" "us-east1 (South Carolina)" "us-east4 (N. Virginia)" "us-west1 (Oregon)" "us-west2 (Los Angeles)" "us-west3 (Salt Lake City)" "us-west4 (Las Vegas)" "europe-west1 (Belgium)" "europe-west2 (London)" "europe-west3 (Frankfurt)" "europe-west4 (Netherlands)" "europe-west6 (Zurich)" "europe-west8 (Milan)" "europe-west9 (Paris)" "europe-southwest1 (Madrid)" "asia-east1 (Taiwan)" "asia-east2 (Hong Kong)" "asia-northeast1 (Tokyo)" "asia-northeast2 (Osaka)" "asia-northeast3 (Seoul)" "asia-south1 (Mumbai)" "asia-south2 (Delhi)" "asia-southeast1 (Singapore)" "asia-southeast2 (Jakarta)" "australia-southeast1 (Sydney)" "australia-southeast2 (Melbourne)" "me-central1 (Doha)" "me-west1 (Tel Aviv)" "africa-south1 (Johannesburgo)" )

declare -a REGION_CODES=( "us-central1" "us-east1" "us-east4" "us-west1" "us-west2" "us-west3" "us-west4" "europe-west1" "europe-west2" "europe-west3" "europe-west4" "europe-west6" "europe-west8" "europe-west9" "europe-southwest1" "asia-east1" "asia-east2" "asia-northeast1" "asia-northeast2" "asia-northeast3" "asia-south1" "asia-south2" "asia-southeast1" "asia-southeast2" "australia-southeast1" "australia-southeast2" "me-central1" "me-west1" "africa-south1" )

echo -e "\n🌐 Selecciona una región para desplegar:" for i in "${!REGIONS[@]}"; do printf "%2d) %s\n" $((i+1)) "${REGIONS[$i]}" sleep 0.05 done

read -p "Ingrese el número de la región deseada: " REGION_INDEX REGION=${REGION_CODES[$((REGION_INDEX-1))]}

if [[ -z "$REGION" ]]; then echo "❌ Selección inválida. Abortando." exit 1 fi

echo "📍 Región seleccionada: $REGION"

-------------------------------

🧼 Preparar entorno

-------------------------------

REPO_DIR="gcp-v2ray" if [[ -d "$REPO_DIR" ]]; then echo "♻️  Eliminando repositorio existente '$REPO_DIR'..." rm -rf "$REPO_DIR" fi

echo "📥 Clonando el repositorio..." git clone https://github.com/ChristopherAGT/gcp-v2ray.git cd "$REPO_DIR" || { echo "❌ No se pudo acceder al directorio del repositorio."; exit 1; }

-------------------------------

🔑 Generar nuevo UUID

-------------------------------

if ! command -v uuidgen &> /dev/null; then echo "📦 Instalando uuidgen..." sudo apt update && sudo apt install -y uuid-runtime fi

NEW_ID=$(uuidgen) echo "🔐 UUID generado: $NEW_ID"

echo "🛠️  Reemplazando ID en config.json..." sed -i "s/"id":\s*"[^"]*"/"id": "$NEW_ID"/" config.json

echo "📝 Abriendo config.json en nano para revisión..." nano config.json

-------------------------------

🐳 Construir y subir imagen Docker

-------------------------------

IMAGE_NAME="gcr.io/$PROJECT_ID/$CUSTOM_IMAGE_NAME" echo "🔨 Construyendo imagen Docker: $IMAGE_NAME" docker build -t "$IMAGE_NAME" .

echo "📤 Subiendo imagen al Container Registry..." docker push "$IMAGE_NAME"

-------------------------------

🚀 Desplegar en Cloud Run

-------------------------------

echo "🚀 Desplegando servicio en Cloud Run en región: $REGION..." SERVICE_OUTPUT=$(gcloud run deploy "$CUSTOM_IMAGE_NAME" 
--image "$IMAGE_NAME" 
--platform managed 
--region "$REGION" 
--allow-unauthenticated 
--port 8080 
--format="value(status.url)")

-------------------------------

🧾 Crear archivo de información

-------------------------------

cat > informacion.txt <<EOF 📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 🔍 INFORMACIÓN ESENCIAL 📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 🗂️ Proyecto GCP       : $PROJECT_ID 📛 Nombre de la Imagen : $CUSTOM_IMAGE_NAME 🆔 UUID Generado       : $NEW_ID 📍 Región Desplegada   : $REGION 🌐 Dominio Google      : $SERVICE_OUTPUT 📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ EOF

cat informacion.txt

echo "✅ ¡Despliegue completado con éxito!"

-------------------------------

☁️ Subir informacion.txt a Cloud Storage

-------------------------------

BUCKET_NAME="$PROJECT_ID-informacion"

if ! gsutil ls -b gs://$BUCKET_NAME &> /dev/null; then echo "📦 Creando bucket privado $BUCKET_NAME en $REGION..." gsutil mb -l "$REGION" gs://$BUCKET_NAME/ else echo "📦 Bucket $BUCKET_NAME ya existe." fi

echo "📤 Subiendo informacion.txt al bucket..." gsutil cp informacion.txt gs://$BUCKET_NAME/

echo -e "\n💡 Para descargar posteriormente usa:" echo "    gsutil cp gs://$BUCKET_NAME/informacion.txt ./"

read -p "¿Confirmas que descargaste el archivo? (s/n): " RESPUESTA if [[ "$RESPUESTA" =~ ^[sS]$ ]]; then echo "🗑️  Eliminando archivo y bucket..." gsutil rm gs://$BUCKET_NAME/informacion.txt gsutil rb gs://$BUCKET_NAME/ echo "✅ Recursos eliminados." else echo "⚠️  No se eliminaron los recursos. Recuerda hacerlo manualmente si no los necesitas." fi

