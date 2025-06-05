#!/bin/bash

echo "🔍 Obteniendo lista de servicios Cloud Run con región..."

services=""
for svc in $(gcloud run services list --platform=managed --format="value(metadata.name)"); do
  region=$(gcloud run services describe "$svc" --platform=managed --format="value(metadata.annotations.run.googleapis.com/location)")
  services+="$svc $region"$'\n'
done

if [ -z "$services" ]; then
  echo "❌ No se encontraron servicios Cloud Run."
  exit 1
fi

# Mostrar servicios enumerados con breve info
echo "🟢 Servicios disponibles:"
IFS=$'\n' read -rd '' -a service_array <<<"$services"
for i in "${!service_array[@]}"; do
  svc_name=$(echo "${service_array[$i]}" | awk '{print $1}')
  svc_region=$(echo "${service_array[$i]}" | awk '{print $2}')
  echo "$((i+1)). Servicio: $svc_name, Región: $svc_region"
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

echo -e "\n🔎 Detalles del servicio seleccionado:"
echo "Nombre: $service_name"
echo "Región: $region"

echo -e "\n🔍 Buscando imágenes relacionadas en Container Registry..."

# Listar imágenes que contengan el nombre del servicio para facilitar selección
images=$(gcloud container images list --format="value(NAME)" | grep "$service_name")

if [ -z "$images" ]; then
  echo "⚠️ No se encontraron imágenes relacionadas con el servicio '$service_name'."
  echo "Obteniendo lista completa de imágenes..."

  images=$(gcloud container images list --format="value(NAME)")
  if [ -z "$images" ]; then
    echo "❌ No se encontraron imágenes en Container Registry."
    exit 1
  fi
fi

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

echo -e "\n✅ Imagen seleccionada:"
echo "Proyecto: $project_name"
echo "Imagen: $image_name"

# Confirmación final
read -p $'\n¿Deseas eliminar el servicio, la imagen y los archivos locales relacionados? (s/n): ' confirm
if [[ "$confirm" != [sS] ]]; then
  echo "❌ Operación cancelada."
  exit 1
fi

echo -e "\n🗑️ Eliminando servicio Cloud Run..."
gcloud run services delete "$service_name" --platform=managed --region="$region" --quiet

echo "🗑️ Eliminando imagen del contenedor..."
gcloud container images delete "gcr.io/$project_name/$image_name" --quiet

echo "🧹 Eliminando archivos locales relacionados..."

files_to_delete
