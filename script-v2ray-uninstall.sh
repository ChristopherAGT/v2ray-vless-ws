#!/bin/bash

───────────────────────────────────────────────

Script para limpieza de servicios Cloud Run

Autor: Christopher - Guatemalteco 🇬🇹

Versión: Pro

Descripción: Elimina servicios Cloud Run, imágenes en Container Registry, y archivos locales relacionados.

───────────────────────────────────────────────

─── Colores ───────────────────────────────────

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' NC='\033[0m' # sin color

─── Verificación de dependencias ──────────────

for cmd in gcloud grep sed tr head cut; do command -v "$cmd" >/dev/null 2>&1 || { echo -e "${RED}❌ Requiere '$cmd' pero no está instalado. Abortando.${NC}"; exit 1; } done

─── Función de manejo de errores ──────────────

handle_error() { echo -e "${RED}❌ Error en: $1. Abortando.${NC}" exit 1 }

─── Regiones a inspeccionar ───────────────────

regions=( us-central1 us-east1 us-east4 us-west1 europe-west1 europe-west4 asia-northeast1 asia-southeast1 )

declare -a service_array

echo -e "${YELLOW}🔍 Buscando servicios Cloud Run en todas las regiones...${NC}"

for region in "${regions[@]}"; do services=$(gcloud run services list --platform=managed --region="$region" --format="value(metadata.name)" 2>/dev/null) if [ -n "$services" ]; then while IFS= read -r svc; do [[ -n "$svc" ]] && service_array+=("$svc::$region") done <<< "$services" fi done

if [ ${#service_array[@]} -eq 0 ]; then echo -e "${RED}❌ No se encontraron servicios Cloud Run en las regiones definidas.${NC}" exit 1 fi

echo -e "\n${GREEN}🟢 Servicios disponibles:${NC}" for i in "${!service_array[@]}"; do svc_name="${service_array[$i]%%::}" svc_region="${service_array[$i]##::}" echo "$((i+1)). Servicio: $svc_name, Región: $svc_region" done

read -rp $'\nSelecciona el número del servicio que quieres eliminar: ' service_index if ! [[ "$service_index" =~ ^[0-9]+$ ]] || [ "$service_index" -lt 1 ] || [ "$service_index" -gt "${#service_array[@]}" ]; then echo -e "${RED}❌ Selección inválida.${NC}" exit 1 fi

selected="${service_array[$((service_index-1))]}" service_name="${selected%%::}" region="${selected##::}"

echo -e "\n${YELLOW}🔎 Detalles del servicio seleccionado:${NC}" echo "Nombre : $service_name" echo "Región : $region"

─── Buscar imágenes en Container Registry ─────

echo -e "\n${YELLOW}🔍 Buscando imágenes relacionadas en Container Registry...${NC}" images=$(gcloud container images list --format="value(NAME)" | grep "/$service_name$")

if [ -z "$images" ]; then echo -e "${YELLOW}⚠️ No se encontraron imágenes relacionadas. Mostrando todas...${NC}" images=$(gcloud container images list --format="value(NAME)") [ -z "$images" ] && echo -e "${RED}❌ No hay imágenes disponibles.${NC}" && exit 1 fi

IFS=$'\n' read -rd '' -a image_array <<< "$images"

echo -e "\n${GREEN}🟢 Imágenes disponibles:${NC}" for i in "${!image_array[@]}"; do echo "$((i+1)). ${image_array[$i]}" done

read -rp $'\nSelecciona el número de la imagen que quieres eliminar: ' image_index if ! [[ "$image_index" =~ ^[0-9]+$ ]] || [ "$image_index" -lt 1 ] || [ "$image_index" -gt "${#image_array[@]}" ]; then echo -e "${RED}❌ Selección inválida.${NC}" exit 1 fi

selected_image="${image_array[$((image_index-1))]}" project_and_image="${selected_image#gcr.io/}" project_name="${project_and_image%%/}" image_name="${project_and_image#/}"

echo -e "\n${YELLOW}✅ Imagen seleccionada:${NC}" echo "Proyecto : $project_name" echo "Imagen   : $image_name"

─── Obtener tag más reciente ──────────────────

tag=$(gcloud container images list-tags "gcr.io/$project_name/$image_name" 
--format='get(tags)' --limit=1 | sed 's/,.*//' | tr -d '[:space:]') tag=${tag:-latest}

─── Formato final de referencia ───────────────

if [[ "$tag" =~ ^sha256: ]]; then image_ref="gcr.io/$project_name/$image_name@$tag" else image_ref="gcr.io/$project_name/$image_name:$tag" fi

─── Confirmación del usuario ──────────────────

read -rp $'\n¿Deseas eliminar el servicio? (s/n): ' confirm_svc read -rp $'¿Deseas eliminar la imagen? (s/n): ' confirm_img read -rp $'¿Deseas eliminar los archivos locales relacionados? (s/n): ' confirm_files

─── Eliminación del servicio ──────────────────

if [[ "$confirm_svc" =~ ^[sS]$ ]]; then echo -e "\n${YELLOW}🗑️ Eliminando servicio Cloud Run...${NC}" gcloud run services delete "$service_name" --platform=managed --region="$region" --quiet || handle_error "eliminar el servicio" fi

─── Eliminación de imagen ─────────────────────

if [[ "$confirm_img" =~ ^[sS]$ ]]; then echo -e "\n${YELLOW}🗑️ Eliminando imagen del contenedor...${NC}" echo "🔗 Eliminando: $image_ref" gcloud container images delete "$image_ref" --quiet --force-delete-tags >/dev/null 2>&1 || echo -e "${YELLOW}⚠️ Imagen no encontrada o ya eliminada.${NC}" fi

─── Archivos locales a eliminar ───────────────

if [[ "$confirm_files" =~ ^[sS]$ ]]; then echo -e "\n${YELLOW}🧹 Eliminando archivos locales relacionados...${NC}" files_to_delete=( "./script-v2ray.sh" "./script-v2ray-uninstall.sh" ) for file in "${files_to_delete[@]}"; do if [ -f "$file" ]; then echo "🗑️ Eliminando $file" rm -f "$file" else echo "ℹ️ Archivo $file no encontrado." fi done fi

─── Finalización ──────────────────────────────

echo -e "\n${GREEN}✅ Proceso de desinstalación completado con éxito.${NC}" exit 0

