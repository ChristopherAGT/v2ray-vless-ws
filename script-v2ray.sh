#!/bin/bash

# ===============================
# 🎨 Colores para salida en terminal
# ===============================
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
RESET="\033[0m"

# ===============================
# 🛑 Activar modo estricto para detener el script ante cualquier error
# ===============================
set -e

# ===============================
# 📚 Funciones con descripciones detalladas
# ===============================

# Función para mostrar títulos de secciones con color y emojis
function print_header() {
  echo -e "\n${CYAN}=============================="
  echo -e "🔧 $1"
  echo -e "==============================${RESET}"
}

# Función para mostrar mensaje de error y salir del script
function error_exit() {
  echo -e "${RED}❌ ERROR: $1${RESET}"
  exit 1
}

# Función para validar y obtener el proyecto GCP activo
function check_gcloud_project() {
  print_header "Verificando proyecto activo en Google Cloud"

  # Obtener el ID del proyecto configurado en gcloud
  local project_id
  project_id=$(gcloud config get-value project 2>/dev/null)

  # Si no hay proyecto configurado, iniciar la configuración interactiva de gcloud
  if [[ -z "$project_id" ]]; then
    echo -e "${YELLOW}⚠️ No se detectó un proyecto configurado. Ejecutando 'gcloud init' para configurarlo...${RESET}"
    gcloud init

    # Intentar obtener nuevamente el proyecto tras la configuración
    project_id=$(gcloud config get-value project 2>/dev/null)

    # Si sigue vacío, terminar el script con error
    if [[ -z "$project_id" ]]; then
      error_exit "No se pudo obtener el ID del proyecto después de 'gcloud init'."
    fi
  fi

  echo -e "${GREEN}✅ Proyecto activo: $project_id${RESET}"
  echo "$project_id"
}

# Función para solicitar al usuario un nombre válido para la imagen Docker
function get_image_name() {
  echo -e "${BLUE}🖊️ Por favor, ingresa un nombre personalizado para la imagen Docker (sin espacios).${RESET}"
  read -p "Nombre de la imagen: " image_name

  # Validar que el nombre no esté vacío
  if [[ -z "$image_name" ]]; then
    error_exit "El nombre de la imagen no puede estar vacío."
  fi

  echo "$image_name"
}

# Función para mostrar y permitir seleccionar la región de despliegue
function select_region() {
  print_header "Selección de región para el despliegue"

  # Lista descriptiva para mostrar al usuario (nombre + ubicación)
  local regions=(
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

  # Lista paralela con solo los códigos válidos para uso interno
  local codes=(
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

  # Mostrar opciones numeradas para fácil selección
  for i in "${!regions[@]}"; do
    printf "%2d) %s\n" $((i+1)) "${regions[$i]}"
  done

  # Solicitar número al usuario
  read -p "Ingrese el número correspondiente a la región deseada: " region_index

  # Obtener el código de región basado en la selección del usuario
  selected_region="${codes[$((region_index-1))]}"

  # Validar selección
  if [[ -z "$selected_region" ]]; then
    error_exit "Selección inválida de región."
  fi

  echo -e "${GREEN}📍 Región seleccionada: $selected_region${RESET}"
  echo "$selected_region"
}

# Función para preparar el repositorio (clonar o eliminar si existe)
function prepare_repository() {
  print_header "Preparando repositorio local"

  local repo_dir="gcp-v2ray"

  # Si existe carpeta del repo, eliminar para clonar desde cero
  if [[ -d "$repo_dir" ]]; then
    echo -e "${YELLOW}♻️ Repositorio '$repo_dir' encontrado. Eliminando para limpieza...${RESET}"
    rm -rf "$repo_dir"
  fi

  # Clonar el repositorio oficial
  echo -e "${CYAN}📥 Clonando repositorio desde GitHub...${RESET}"
  git clone https://github.com/ChristopherAGT/gcp-v2ray.git

  # Cambiar al directorio clonado, salir con error si falla
  cd "$repo_dir" || error_exit "No se pudo acceder al directorio del repositorio."
}

# Función para verificar instalación de uuidgen (herramienta para UUIDs)
function ensure_uuidgen() {
  print_header "Verificando herramienta uuidgen"

  # Instalar uuidgen si no está disponible (depende de uuid-runtime)
  if ! command -v uuidgen &> /dev/null; then
    echo -e "${YELLOW}📦 uuidgen no encontrado. Instalando paquete uuid-runtime...${RESET}"
    sudo apt update && sudo apt install -y uuid-runtime
  else
    echo -e "${GREEN}✅ uuidgen ya está instalado.${RESET}"
  fi
}

# Función para generar un UUID y actualizar el archivo config.json
function update_config_uuid() {
  print_header "Generando nuevo UUID y actualizando config.json"

  # Generar un UUID nuevo y único
  local new_id
  new_id=$(uuidgen)

  # Reemplazar el campo "id" en config.json con el UUID generado
  sed -i "s/\"id\":\s*\"[^\"]*\"/\"id\": \"$new_id\"/" config.json

  echo -e "${BLUE}📝 Abriendo config.json para que puedas revisar manualmente.${RESET}"
  echo -e "💡 Por favor, guarda y cierra el editor nano para continuar."
  nano config.json

  echo "$new_id"
}

# Función para construir y subir la imagen Docker al Container Registry
function build_and_push_image() {
  print_header "Construcción y subida de imagen Docker"

  local project_id="$1"
  local image_name="$2"

  local full_image_name="gcr.io/$project_id/$image_name"

  echo -e "${CYAN}🔨 Construyendo imagen Docker: $full_image_name${RESET}"
  docker build -t "$full_image_name" .

  echo -e "${CYAN}📤 Subiendo imagen al Container Registry...${RESET}"
  docker push "$full_image_name"

  echo "$full_image_name"
}

# Función para desplegar la imagen Docker en Cloud Run en la región elegida
function deploy_cloud_run() {
  print_header "Desplegando servicio en Cloud Run"

  local service_name="$1"
  local image="$2"
  local region="$3"

  # Desplegar servicio y obtener URL pública
  local url
  url=$(gcloud run deploy "$service_name" \
    --image "$image" \
    --platform managed \
    --region "$region" \
    --allow-unauthenticated \
    --port 8080 \
    --format="value(status.url)")

  echo -e "${GREEN}🌐 Servicio desplegado exitosamente en: $url${RESET}"
  echo "$url"
}

# Función para crear un archivo con información esencial del despliegue
function create_info_file() {
  print_header "Generando archivo 'informacion.txt' con detalles del despliegue"

  local project_id="$1"
  local image_name="$2"
  local uuid="$3"
  local region="$4"
  local url="$5"

  cat > informacion.txt <<EOF
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 INFORMACIÓN ESENCIAL
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗂️ Proyecto GCP       : $project_id
📛 Nombre de la Imagen : $image_name
🆔 UUID Generado       : $uuid
📍 Región Desplegada   : $region
🌐 Dominio Google      : $url
📦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

  # Mostrar el contenido para confirmación visual
  cat informacion.txt
}

# Función para gestionar un bucket privado en Cloud Storage para almacenamiento temporal
function manage_bucket() {
  print_header "Gestión de bucket privado para almacenamiento temporal"

  local project_id="$1"
  local region="$2"

  # Nombre del bucket basado en el proyecto
  local bucket_name="${project_id}-informacion"

  # Crear bucket si no existe (ignore errores si ya está)
  if ! gsutil ls -b gs://"$bucket_name" &> /dev/null; then
    echo -e "${CYAN}📦 Creando bucket privado $bucket_name en la región $region...${RESET}"
    gsutil mb -l "$region" gs://"$bucket_name"/
  else
    echo -e "${YELLOW}📦 Bucket $bucket_name ya existe.${RESET}"
  fi

  # Subir archivo de información al bucket
  echo -e "${CYAN}📤 Subiendo 'informacion.txt' al bucket privado...${RESET}"
  gsutil cp informacion.txt gs://"$bucket_name"/

  echo -e "${YELLOW}💡 Para descargar el archivo en otra terminal, ejecuta este comando:"
  echo "    gsutil cp gs://$bucket_name/informacion.txt ./"
  echo ""

  # Confirmar descarga antes de eliminar recursos
  read -p "¿Confirmas que descargaste el archivo? (s/n): " resp

  if [[ "$resp" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}🗑️ Eliminando archivo y bucket privado...${RESET}"
    gsutil rm gs://"$bucket_name"/informacion.txt
    gsutil rb gs://"$bucket_name"/
    echo -
