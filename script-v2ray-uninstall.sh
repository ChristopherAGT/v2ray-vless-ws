#!/bin/bash

# ───────────────────────────────────────────────
# Script de limpieza para servicios Cloud Run
# Autor: Christopher - Guatemalteco 🇬🇹
# Descripción: Elimina un servicio Cloud Run, su imagen asociada en Container Registry, y archivos locales.
# ───────────────────────────────────────────────

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

# Función para imprimir error y salir
function handle_error {
  echo -e "${RED}❌ ERROR:${NC} $1"
  exit 1
}

# Regiones a inspeccionar
regions=(
  us-central1 us-east1 us-east4 us-west1
  europe-west1 europe-west4
  asia-northeast1 asia-southeast1
)

declare -a service_array

echo -e "${CYAN}🔍 Buscando servicios Cloud Run en todas las regiones...${NC}"

for region in "${regions[@]}"; do
  services=$(gcloud run services list --platform=managed --region="$region" --format="value(metadata.name)")
  if [[ -n "$services" ]]; then
    while IFS= read -r svc; do
      [[ -n "$svc" ]] && service_array+=("$svc::$region")
    done <<< "$services"
  fi
done

if [[ ${#service_array[@]} -eq 0 ]]; then
  handle_error "No se encontraron servicios Cloud Run en las regiones definidas."
fi

echo -e "\n${GREEN}🟢 Servicios disponibles:${NC}"
for i in "${!service_array[@]}"; do
  svc_name="${service_array[$i]%%::*}"
  svc_region="${service_array[$i]##*::}"
  echo "$((i+1)). Servicio: $svc_name, Región: $svc_region"
done

read -rp $'\nSelecciona el número del servicio que quieres eliminar: ' service_index
if ! [[ "$service_index" =~ ^[0-9]+$ ]] || [ "$service_index" -lt 1 ] || [ "$service_index" -gt "${#service_array[@]}" ]; then
  handle_error "Selección inválida."
fi

selected="${service_array[$((service_index-1))]}"
service_name="${selected%%::*}"
region="${selected##*::}"

echo -e "\n${CYAN}🔎 Detalles del servicio seleccionado:${NC}"
echo "Nombre : $service_name"
echo "Región : $region"

echo -e "\n${CYAN}🔍 Buscando imágenes relacionadas en Container Registry...${NC}"
images=$(gcloud container images list --format="value(NAME)" | grep "/$service_name$" || true)

if [[ -z "$images" ]]; then
  echo -e "${YELLOW}⚠️ No se encontraron imágenes relacionadas. Mostrando todas...${NC}"
  images=$(gcloud container images list --format="value(NAME)")
  [[ -z "$images" ]] && handle_error "No hay imágenes disponibles."
fi

IFS=$'\n' read -rd '' -a image_array <<< "$images"

echo -e "\n${GREEN}🟢 Imágenes disponibles:${NC}"
for i in "${!image_array[@]}"; do
  echo "$((i+1)). ${image_array[$i]}"
done

read -rp $'\nSelecciona el número de la imagen que quieres eliminar: ' image_index
if ! [[ "$image_index" =~ ^[0-9]+$ ]] || [ "$image_index" -lt 1 ] || [ "$image_index" -gt "${#image_array[@]}" ]; then
  handle_error "Selección inválida."
fi

selected_image="${image_array[$((image_index-1))]}"
project_and_image="${selected_image#gcr.io/}"
project_name="${project_and_image%%/*}"
image_name="${project_and_image#*/}"

echo -e "\n${GREEN}✅ Imagen seleccionada:${NC}"
echo "Proyecto : $project_name"
echo "Imagen   : $image_name"

# Obtener digest SHA256 para evitar warnings
digest=$(gcloud container images list-tags "gcr.io/$project_name/$image_name" --format='get(digest)' --limit=1 --filter='tags:*' | head -n 1)

if [[ -z "$digest" ]]; then
  # Si no hay digest, fallback a latest tag (menos recomendado)
  digest="latest"
fi

if [[ "$digest" == "latest" ]]; then
  image_ref="gcr.io/$project_name/$image_name:latest"
else
  image_ref="gcr.io/$project_name/$image_name@$digest"
fi

read -rp $'\n¿Deseas eliminar el servicio, la imagen y los archivos locales relacionados? (s/n): ' confirm
if [[ ! "$confirm" =~ ^[sS]$ ]]; then
  echo -e "${YELLOW}❌ Operación cancelada por el usuario.${NC}"
  exit 0
fi

echo -e "\n${CYAN}🗑️ Eliminando servicio Cloud Run...${NC}"
if ! gcloud run services delete "$service_name" --platform=managed --region="$region" --quiet; then
  echo -e "${YELLOW}⚠️ El servicio pudo no existir o hubo un problema al eliminar.${NC}"
else
  echo -e "${GREEN}Servicio eliminado correctamente.${NC}"
fi

echo -e "\n${CYAN}🗑️ Eliminando imagen del contenedor...${NC}"
echo "🔗 Eliminando: $image_ref"
if ! gcloud container images delete "$image_ref" --quiet; then
  echo -e "${YELLOW}⚠️ Imagen no encontrada o ya eliminada.${NC}"
else
  echo -e "${GREEN}Imagen eliminada correctamente.${NC}"
fi

echo -e "\n${CYAN}🧹 Eliminando archivos locales relacionados...${NC}"
files_to_delete=(
  "./script-v2ray.sh"
  "./script-v2ray-uninstall.sh"
)

for file in "${files_to_delete[@]}"; do
  if [ -f "$file" ]; then
    echo "🗑️ Eliminando $file"
    rm -f "$file"
  else
    echo "ℹ️ Archivo $file no encontrado."
  fi
done

echo -e "\n${GREEN}✅ Proceso de desinstalación completado con éxito.${NC}"
