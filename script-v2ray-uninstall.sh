#!/bin/bash

echo "🔍 Obteniendo lista de servicios Cloud Run..."
services=$(gcloud run services list --platform=managed --format="value(metadata.name,location)")
if [ -z "$services" ]; then
  echo "❌ No se encontraron servicios Cloud Run."
  exit 1
fi

# Mostrar servicios enumerados
echo "🟢 Servicios disponibles:"
IFS=$'\n' read -rd '' -a service_array <<<"$services"
for i in "${!service_array[@]}"; do
  echo "$((i+1)). ${service_array[$i]}"
done

# Selección del servicio
read -p "Selecciona el número del servicio que quieres eliminar: " service_index
if ! [[ "$service_index" =~ ^[0-9]+$ ]] || [ "$service_index" -lt 1 ] || [ "$service_index" -gt "${#service_array[@]}" ]; then
  echo "❌ Selección inválida."
  exit 1
fi

selected_service="${service_array[$((service_index-1))]}"
service_name=$(echo "$selected_service" | awk '{print $1}')
region=$(echo "$selected_service" | awk '{print $2}')

echo "✅ Servicio seleccionado: $service_name (Región: $region)"

echo "🔍 Obteniendo lista de imágenes en Container Registry..."
images=$(gcloud container images list --format="value(NAME)")
if [ -z "$images" ]; then
  echo "❌ No se encontraron imágenes."
  exit 1
fi

# Mostrar imágenes enumeradas
echo "🟢 Imágenes disponibles:"
IFS=$'\n' read -rd '' -a image_array <<<"$images"
for i in "${!image_array[@]}"; do
  echo "$((i+1)). ${image_array[$i]}"
done

# Selección de la imagen
read -p "Selecciona el número de la imagen que quieres eliminar: " image_index
if ! [[ "$image_index" =~ ^[0-9]+$ ]] || [ "$image_index" -lt 1 ] || [ "$image_index" -gt "${#image_array[@]}" ]; then
  echo "❌ Selección inválida."
  exit 1
fi

selected_image="${image_array[$((image_index-1))]}"
project_name=$(echo "$selected_image" | cut -d'/' -f2)
image_name=$(echo "$selected_image" | cut -d'/' -f3)

echo "✅ Imagen seleccionada: $image_name (Proyecto: $project_name)"

read -p "¿Deseas continuar con la eliminación del servicio y la imagen? (s/n): " confirm
if [[ "$confirm" != [sS] ]]; then
  echo "❌ Operación cancelada."
  exit 1
fi

echo "🗑️ Eliminando servicio Cloud Run..."
gcloud run services delete "$service_name" --platform=managed --region="$region" --quiet

echo "🗑️ Eliminando imagen del contenedor..."
gcloud container images delete "gcr.io
