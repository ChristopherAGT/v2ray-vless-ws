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
RED='\033[1;31m'      # Rojo para errores (brillante/negrita)
GREEN='\033[1;32m'    # Verde para éxito (brillante/negrita)
YELLOW='\033[1;33m'   # Amarillo para advertencias/avisos (brillante/negrita)
CYAN='\033[1;36m'     # Cian para información/neutro (brillante/negrita)
NC='\033[0m'          # Reset (sin color)

# -------------------------------
# Funciones auxiliares
# -------------------------------

function handle_error {
  echo -e "${RED}❌ ERROR:${NC} $1"
  exit 1
}

function print_section {
  echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}🔹 $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# -------------------------------
# Variables globales
# -------------------------------

print_section "Obteniendo regiones disponibles para Cloud Run"

# Obtener regiones Cloud Run automáticamente
mapfile -t regions < <(gcloud run regions list --format="value(locationId)")

if [[ ${#regions[@]} -eq 0 ]]; then
  handle_error "No se encontraron regiones disponibles para Cloud Run."
fi

echo -e "${GREEN}✅️ Lista obtenida exitosamente${NC}"

declare -a service_array

print_section "Buscando servicios Cloud Run en todas las regiones (paralelizado)"
echo -ne "${YELLOW}⏳ Esto puede tardar unos segundos${NC}"

# Animación de puntos (mientras corre en background)
(
  while true; do
    for dots in "." ".." "..." "...." "....."; do
      echo -ne "\r${YELLOW}⏳ Esto puede tardar unos segundos, buscando servicios en todas las regiones$dots${NC}"
      sleep 0.5
    done
  done
) &
spinner_pid=$!

# Buscar servicios en paralelo
declare -a pids=()
declare -a tmp_files=()

for region in "${regions[@]}"; do
  tmp_file=$(mktemp)
  tmp_files+=("$tmp_file")
  (
    gcloud run services list --platform=managed --region="$region" --format="value(metadata.name)" 2>/dev/null || true
  ) > "$tmp_file" &
  pids+=($!)
done

for pid in "${pids[@]}"; do
  wait "$pid"
done

# Detener spinner
kill "$spinner_pid" &>/dev/null
wait "$spinner_pid" 2>/dev/null

echo -e "\r${GREEN}✅ Búsqueda completada.${NC}                                             "

# Leer resultados
for i in "${!tmp_files[@]}"; do
  region="${regions[$i]}"
  while IFS= read -r svc; do
    [[ -n "$svc" ]] && service_array+=("$svc::$region")
  done < "${tmp_files[$i]}"
  rm -f "${tmp_files[$i]}"
done

if [[ ${#service_array[@]} -eq 0 ]]; then
  handle_error "No se encontraron servicios Cloud Run en las regiones disponibles."
fi

echo -e "${GREEN}🟢 Servicios encontrados:${NC}"
echo "0. ❌ Cancelar y salir"
for i in "${!service_array[@]}"; do
  svc_name="${service_array[$i]%%::*}"
  svc_region="${service_array[$i]##*::}"
  echo "$((i+1)). Servicio: ${svc_name}, Región: ${svc_region}"
done

while true; do
  read -rp $'\nSeleccione el número del servicio que desea eliminar (o 0 para cancelar): ' service_index
  if [[ "$service_index" == "0" ]]; then
    echo -e "${YELLOW}🚪 Operación cancelada por el usuario.${NC}"
    exit 0
  elif [[ "$service_index" =~ ^[0-9]+$ ]] && [ "$service_index" -ge 1 ] && [ "$service_index" -le "${#service_array[@]}" ]; then
    break
  fi
  echo -e "${RED}❌ Opción inválida. Por favor, ingrese un número válido de la lista.${NC}"
done

selected="${service_array[$((service_index-1))]}"
service_name="${selected%%::*}"
region="${selected##*::}"

print_section "Detalles del servicio seleccionado"
echo "Nombre : ${service_name}"
echo "Región : ${region}"

print_section "Buscando imágenes relacionadas en Container Registry"

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

while true; do
  read -rp $'\nSeleccione el número de la imagen que desea eliminar: ' image_index
  if [[ "$image_index" =~ ^[0-9]+$ ]] && [ "$image_index" -ge 1 ] && [ "$image_index" -le "${#image_array[@]}" ]; then
    break
  fi
  echo -e "${RED}❌ Opción inválida. Por favor, ingrese un número válido de la lista.${NC}"
done

selected_image="${image_array[$((image_index-1))]}"
project_and_image="${selected_image#gcr.io/}"
project_name="${project_and_image%%/*}"
image_name="${project_and_image#*/}"

print_section "Imagen seleccionada"
echo "Proyecto : ${project_name}"
echo "Imagen   : ${image_name}"

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
  "./build-service-v2ray.sh"
  "./remove-service-v2ray.sh"
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
