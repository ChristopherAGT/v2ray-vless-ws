#!/bin/bash

# ───────────────────────────────────────────────
# 🧹 Script de limpieza para servicios Cloud Run
# Autor: Christopher - Guatemalteco 🇬🇹
# Descripción:
#   Elimina un servicio Cloud Run seleccionado, su imagen asociada en Container Registry,
#   y archivos locales relacionados.
# ───────────────────────────────────────────────

# -------------------------------
# Configuración de colores y emojis
# -------------------------------
RED='\033[0;31m'      # Rojo para errores
GREEN='\033[0;32m'    # Verde para éxito
YELLOW='\033[1;33m'   # Amarillo para advertencias/avisos
CYAN='\033[0;36m'     # Cian para información/neutro
NC='\033[0m'          # Sin color (reset)

# -------------------------------
# Funciones auxiliares
# -------------------------------

# Muestra mensaje de error y termina la ejecución
function handle_error {
  echo -e "${RED}❌ ERROR:${NC} $1"
  exit 1
}

# Muestra un encabezado de sección con color y emoji
function print_section {
  echo -e "\n${CYAN}─────────────────────────────${NC}"
  echo -e "${CYAN}🔹 $1${NC}"
  echo -e "${CYAN}─────────────────────────────${NC}\n"
}

# -------------------------------
# Variables globales
# -------------------------------

# Regiones donde buscar servicios Cloud Run
regions=(
  us-central1 us-east1 us-east4 us-west1
  europe-west1 europe-west4
  asia-northeast1 asia-southeast1
)

declare -a service_array

# -------------------------------
# Inicio del script
# -------------------------------

print_section "Buscando servicios Cloud Run en todas las regiones"

for region in "${regions[@]}"; do
  services=$(gcloud run services list --platform=managed --region="$region" --format="value(metadata.name)")
  if [[ -n "$services" ]]; then
    while IFS= read -r svc; do
      [[ -n "$svc" ]] && service_array+=("$svc::$region")
    done <<< "$services"
  fi
done

if [[ ${#service_array[@]} -eq 0 ]]; then
  handle_error "No se encontraron servicios Cloud Run en las regiones configuradas."
fi

echo -e "${GREEN}🟢 Servicios encontrados:${NC}"
for i in "${!service_array[@]}"; do
  svc_name="${service_array[$i]%%::*}"
  svc_region="${service_array[$i]##*::}"
  echo "$((i+1)). Servicio: ${svc_name}, Región: ${svc_region}"
done

read -rp $'\nSeleccione el número del servicio que desea eliminar: ' service_index
if ! [[ "$service_index" =~ ^[0-9]+$ ]] || [ "$service_index" -lt 1 ] || [ "$service_index" -gt "${#service_array[@]}" ]; then
  handle_error "Selección inválida. Por favor, ingrese un número válido."
fi

selected="${service_array[$((service_index-1))]}"
service_name="${selected%%::*}"
region="${selected##*::}"

print_section "Detalles del servicio seleccionado"
echo "Nombre : ${service_name}"
echo "Región : ${region}"

print_section "Buscando imágenes relacionadas en Container Registry"

# Buscar imágenes relacionadas al servicio por nombre
images=$(gcloud container images list --format="value(NAME)" | grep "/$service_name$" || true)

if [[ -z "$images" ]]; then
  echo -e "${YELLOW}⚠️ No se encontraron imágenes relacionadas al servicio. Mostrando todas las imágenes disponibles.${NC}"
  images=$(gcloud container images list --format="value(NAME)")
  [[ -z "$images" ]] && handle_error "No se encontraron imágenes en Container Registry."
fi

IFS=$'\n' read -rd '' -a image_array <<< "$images"

echo -e "${GREEN}🟢 Imágenes disponibles:${NC}"
for i in "${!image_array[@]}"; do
  echo "$((i+1)). ${image_array[$i]}"
done

read -rp $'\nSeleccione el número de la imagen que desea eliminar: ' image_index
if ! [[ "$image_index" =~ ^[0-9]+$ ]] || [ "$image_index" -lt 1 ] || [ "$image_index" -gt "${#image_array[@]}" ]; then
  handle_error "Selección inválida. Por favor, ingrese un número válido."
fi

selected_image="${image_array[$((image_index-1))]}"
project_and_image="${selected_image#gcr.io/}"
project_name="${project_and_image%%/*}"
image_name="${project_and_image#*/}"

print_section "Imagen seleccionada"
echo "Proyecto : ${project_name}"
echo "Imagen   : ${image_name}"

# Obtener el digest SHA256 para la imagen
digest=$(gcloud container images list-tags "gcr.io/${project_name}/${image_name}" --format='get(digest)' --limit=1 --filter='tags:*' | head -n 1)

if [[ -z "$digest" ]]; then
  digest="latest"
fi

if [[ "$digest" == "latest" ]]; then
  image_ref="gcr.io/${project_name}/${image_name}:latest"
else
  image_ref="gcr.io/${project_name}/${image_name}@${digest}"
fi

echo
read -rp "¿Confirmas eliminar el servicio, la imagen (con todas sus etiquetas) y los archivos locales relacionados? (s/n): " confirm
if [[ ! "$confirm" =~ ^[sS]$ ]]; then
  echo -e "${YELLOW}❌ Operación cancelada por el usuario.${NC}"
  exit 0
fi

# -------------------------------
# Eliminación de recursos
# -------------------------------

print_section "Eliminando servicio Cloud Run"
if ! gcloud run services delete "${service_name}" --platform=managed --region="${region}" --quiet; then
  echo -e "${YELLOW}⚠️ El servicio pudo no existir o hubo un problema al eliminar.${NC}"
else
  echo -e "${GREEN}✅ Servicio eliminado correctamente.${NC}"
fi

print_section "Eliminando imagen del contenedor (incluyendo tags)"
echo "🔗 Imagen a eliminar: ${image_ref}"
if ! gcloud container images delete "${image_ref}" --force-delete-tags --quiet; then
  echo -e "${YELLOW}⚠️ Imagen no encontrada o ya eliminada.${NC}"
else
  echo -e "${GREEN}✅ Imagen eliminada correctamente.${NC}"
fi

print_section "Eliminando archivos locales relacionados"
files_to_delete=(
  "./script-v2ray.sh"
  "./script-v2ray-uninstall.sh"
)

for file in "${files_to_delete[@]}"; do
  if [[ -f "$file" ]]; then
    echo "🗑️ Eliminando archivo: ${file}"
    rm -f "$file"
  else
    echo "ℹ️ Archivo no encontrado: ${file}"
  fi
done

echo -e "\n${GREEN}🎉 Proceso de limpieza completado con éxito.${NC}"
