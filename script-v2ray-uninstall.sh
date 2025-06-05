#!/bin/bash

KEYWORD="v2ray"

echo "🔍 Buscando servicios Cloud Run con '$KEYWORD'..."

services=$(gcloud run services list --platform=managed --format="value(metadata.name,location)" | grep "$KEYWORD")

if [ -z "$services" ]; then
  echo "❌ No se encontraron servicios Cloud Run con '$KEYWORD'."
else
  echo "🟢 Servicios encontrados:"
  IFS=$'\n' read -rd '' -a service_array <<<"$services"
  for i in "${!service_array[@]}"; do
    echo "$((i+1)). ${service_array[$i]}"
  done

  read -p "¿Eliminar todos estos servicios? (s/n): " confirm
  if [[ "$confirm" == [sS] ]]; then
    for service in "${service_array[@]}"; do
      service_name=$(echo "$service" | awk '{print $1}')
      region=$(echo "$service" | awk '{print $2}')
      echo "🗑️ Eliminando servicio: $service_name en región $region"
      gcloud run services delete "$service_name" --platform=managed --region="$region" --quiet
    done
  else
    echo "❌ Cancelado la eliminación de servicios."
  fi
fi

echo "🔍 Buscando imágenes en Container Registry con '$KEYWORD'..."

images=$(gcloud container images list --format="value(NAME)" | grep "$KEYWORD")

if [ -z "$images" ]; then
  echo "❌ No se encontraron imágenes con '$KEYWORD'."
else
  echo "🟢 Imágenes encontradas:"
  IFS=$'\n' read -rd '' -a image_array <<<"$images"
  for i in "${!image_array[@]}"; do
    echo "$((i+1)). ${image_array[$i]}"
  done

  read -p "¿Eliminar todas estas imágenes? (s/n): " confirm_images
  if [[ "$confirm_images" == [sS] ]]; then
    for img in "${image_array[@]}"; do
      echo "🗑️ Eliminando imagen: $img"
      gcloud container images delete "$img" --quiet
    done
  else
    echo "❌ Cancelado la eliminación de imágenes."
  fi
fi

# Eliminar scripts y archivos locales (ajusta rutas si sabes más archivos)
echo "🧹 Eliminando scripts y archivos locales relacionados..."

files_to_delete=(
  "./script-v2ray.sh"
  "./script-v2ray-uninstall.sh"
  # Agrega aquí más archivos o rutas si sabes que el script creó otros
)

for file in "${files_to_delete[@]}"; do
  if [ -f "$file" ]; then
    echo "🗑️ Eliminando archivo $file"
    rm -f "$file"
  else
    echo "ℹ️ Archivo $file no encontrado, saltando."
  fi
done

echo "✅ Limpieza completa."
