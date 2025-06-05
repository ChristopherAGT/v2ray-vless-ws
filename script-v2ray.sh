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

echo -e "${CYAN}🔧 Inicializando Google Cloud CLI...${RESET}"

# 🔍 Verificar si el proyecto GCP está configurado
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

# ⚠️ Si no hay proyecto activo, iniciar configuración
if [[ -z "$PROJECT_ID" ]]; then
  echo -e "${YELLOW}⚠️ No se detectó un proyecto configurado. Iniciando 'gcloud init'...${RESET}"
  gcloud init

  # Volver a obtener el proyecto tras la inicialización
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
  
  if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}❌ No se pudo obtener el ID del proyecto después de 'gcloud init'.${RESET}"
    exit 1
  fi
fi

echo -e "${GREEN}✅ Proyecto GCP activo: $PROJECT_ID${RESET}"

# 🖊️ Solicitar nombre para la imagen Docker
read -p "🖊️ Ingresa un nombre para tu imagen (sin espacios): " CUSTOM_IMAGE_NAME

# Validar que el nombre no esté vacío
if [[ -z "$CUSTOM_IMAGE_NAME" ]]; then
  echo -e "${RED}❌ El nombre de la imagen no puede estar vacío.${RESET}"
  exit 1
fi

# 📍 Definir listas de regiones y sus códigos
declare -a REGIONS=(
  "us-central1 (Iowa)" "us-east1 (South Carolina)" "us-east4 (N. Virginia)" 
  "us-west1 (Oregon)" "us-west2 (Los Angeles)" "us-west3 (Salt Lake City)" 
  "us-west4 (Las Vegas)" "europe-west1 (Belgium)" "europe-west2 (London)" 
  "europe-west3 (Frankfurt)" "europe-west4 (Netherlands)" "europe-west6 (Zurich)" 
  "europe-west8 (Milan)" "europe-west9 (Paris)" "europe-southwest1 (Madrid)" 
  "asia-east1 (Taiwan)" "asia-east2 (Hong Kong)" "asia-northeast1 (Tokyo)" 
  "asia-northeast2 (Osaka)" "asia-northeast3 (Seoul)" "asia-south1 (Mumbai)" 
  "asia-south2 (Delhi)" "asia-southeast1 (Singapore)" "asia-southeast2 (Jakarta)" 
  "australia-southeast1 (Sydney)" "australia-southeast2 (Melbourne)" 
  "me-central1 (Doha)" "me-west1 (Tel Aviv)" "africa-south1 (Johannesburgo)"
)

declare -a REGION_CODES=(
  "us-central1" "us-east1" "us-east4" 
  "us-west1" "us-west2" "us-west3" 
  "us-west4" "europe-west1" "europe-west2" 
  "europe-west3" "europe-west4" "europe-west6" 
  "europe-west8" "europe-west9" "europe-southwest1" 
  "asia-east1" "asia-east2" "asia-northeast1" 
  "asia-northeast2" "asia-northeast3" "asia-south1" 
  "asia-south2" "asia-southeast1" "asia-southeast2" 
  "australia-southeast1" "australia-southeast2" 
  "me-central1" "me-west1" "africa-south1"
)

# 🌍 Mostrar regiones para selección
echo -e "${BLUE}🌍 Selecciona una región para desplegar:${RESET}"
for i in "${!REGIONS[@]}"; do
  printf "%2d) %s\n" $((i+1)) "${REGIONS[$i]}"
done

read -p "Ingrese el número de la región deseada: " REGION_INDEX
REGION=${REGION_CODES[$((REGION_INDEX-1))]}

# Validar selección de región
if [[ -z "$REGION" ]]; then
  echo -e "${RED}❌ Selección inválida. Abortando.${RESET}"
  exit 1
fi

echo -e "${GREEN}📍 Región seleccionada: $REGION${RESET}"

# 🔄 Limpiar repositorio previo si existe
REPO_DIR="gcp-v2ray"
if [[ -d "$REPO_DIR" ]]; then
  echo -e "${YELLOW}♻️ Eliminando repositorio existente '$REPO_DIR'...${RESET}"
  rm -rf "$REPO_DIR"
fi

# 📥 Clonar repositorio fresco
echo -e "${CYAN}📥 Clonando el repositorio...${RESET}"
git clone https://github.com/ChristopherAGT/gcp-v2ray.git

# 📁 Entrar al directorio
cd gcp-v2ray || { echo -e "${RED}❌ No se pudo acceder al directorio del repositorio.${RESET}"; exit 1; }

# 🧰 Verificar si uuidgen está instalado, instalar si no
if ! command -v uuidgen &> /dev/null; then
  echo -e "${YELLOW}📦 Instalando uuidgen...${RESET}"
  sudo apt update && sudo apt install -y uuid-runtime
fi

# 🔐 Generar nuevo UUID
NEW_ID=$(uuidgen)

# 🛠️ Reemplazar ID en config.json
echo -e "${CYAN}🛠️ Reemplazando el ID en config.json...${RESET}"
sed -i "s/\"id\":\s*\"[^\"]*\"/\"id\": \"$NEW_ID\"/" config.json

# ✏️ Abrir para edición manual si el usuario desea
echo -e "${BLUE}📝 Abriendo config.json en nano. Guarda y cierra para continuar...${RESET}"
nano config.json

# 🐳 Construir imagen Docker
IMAGE_NAME="gcr.io/$PROJECT_ID/$CUSTOM_IMAGE_NAME"
echo -e "${CYAN}🔨 Construyendo la imagen Docker: $IMAGE_NAME${RESET}"
docker build -t "$IMAGE_NAME" .

# ⏫ Subir imagen a Container Registry
echo -e "${CYAN}📤 Subiendo la imagen al Container Registry...${RESET}"
docker push "$IMAGE_NAME"

# 🚀 Desplegar servicio en Cloud Run
echo -e "${CYAN}🌐 Desplegando el servicio en Cloud Run en $REGION...${RESET}"
SERVICE_URL=$(gcloud run deploy "$CUSTOM_IMAGE_NAME" \
  --image "$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --format="value(status.url)")

# 📄 Crear archivo con información esencial
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

# --- Gestión de bucket privado para almacenamiento temporal ---

BUCKET_NAME="$PROJECT_ID-informacion"

# Crear bucket si no existe
if ! gsutil ls -b gs://"$BUCKET_NAME" &> /dev/null; then
  echo -e "${CYAN}📦 Creando bucket privado $BUCKET_NAME en $REGION...${RESET}"
  gsutil mb -l "$REGION" gs://"$BUCKET_NAME"/
else
  echo -e "${YELLOW}📦 Bucket $BUCKET_NAME ya existe.${RESET}"
fi

# Subir archivo informacion.txt
echo -e "${CYAN}📤 Subiendo informacion.txt a gs://$BUCKET_NAME/${RESET}"
gsutil cp informacion.txt gs://"$BUCKET_NAME"/

echo -e "\n${CYAN}🔗 Archivo subido a bucket privado."
echo -e "${YELLOW}💡 Para descargar el archivo ejecuta este comando en otra terminal:${RESET}"
echo "    gsutil cp gs://$BUCKET_NAME/informacion.txt ./"
echo ""

# Confirmación para eliminar recursos temporales
read -p "¿Confirmas que descargaste el archivo? (s/n): " RESPUESTA

if [[ "$RESPUESTA" =~ ^[Ss]$ ]]; then
  echo -e "${YELLOW}🗑️ Eliminando archivo y bucket privado...${RESET}"
  gsutil rm gs://"$BUCKET_NAME"/informacion.txt
  gsutil rb gs://"$BUCKET_NAME"/
  echo -e "${GREEN}✅ Archivo y bucket eliminados.${RESET}"
else
  echo -e "${YELLOW}⚠️ No se eliminaron los recursos. Recuerda eliminarlos manualmente si no los necesitas.${RESET}"
fi
