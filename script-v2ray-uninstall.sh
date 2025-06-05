#!/bin/bash

# Lista de regiones donde buscar servicios Cloud Run (ajusta según tus zonas usadas)
regions=(us-central1 us-east1 us-east4 us-west1 europe-west1 europe-west4 asia-northeast1 asia-southeast1)

declare -a service_array

echo "🔍 Buscando servicios Cloud Run en todas las regiones..."

for region in "${regions[@]}"; do
  services=$(gcloud run services list --platform=managed --region="$region" --format="value(metadata.name)" 2>/dev/null)
  if [ -n "$services" ]; then
    while IFS= read -r svc; do
      service_array+=("$svc $region")
    done <<< "$services"
  fi
done

if [ ${#service_array[@]} -eq 0 ]; then
  echo "❌ No se encontraron servicios Cloud Run en las regiones definidas."
  exit 1
fi

echo "🟢 Servicios disponibles:"
for i in "${!service_array[@]}"; do
  svc_name=$(echo "${service_array[$i]}" | awk '{print $1}')
  svc_region=$(echo "${service_array[$i]}" | awk '{print $2}')
  echo "$((i+1)). Servicio: $svc_name, Región: $svc_region"
done

read -p "Selecciona el número del servicio que quieres eliminar: " service_index
if ! [[ "$service_index" =~ ^[0-9]+$ ]] || [ "$service_index" -lt 1 ] || [ "$service_index" -gt "${#service_array[@]}" ]; then
  echo "❌ Selección inválida."
  exit 1
fi

selected="${service_array[$((service_index-1))]}"
service_name=$(echo "$selected" | awk '{print $1}')
region=$(echo "$selected" | awk '{print $2}')

echo -e "\n🔎 Detalles del servicio seleccionado:"
echo "Nombre: $service_name"
echo "Región: $region"

echo -e "\n🔍 Buscando imágenes relacionadas en Container Registry..."
images=$(gcloud container images list --format="value(NAME)" | grep "$service_name")

if [ -z "$images" ]; then
  echo "⚠️ No se encontraron imágenes relacionadas. Mostrando todas..."
  images=$(gcloud container images list --format="value(NAME)")
  if [ -z "$images" ]; then
    echo "❌ No hay imágenes disponibles en Container Registry."
    exit 1
  fi
fi

IFS=$'\n' read -rd '' -a image_array <<< "$images"
echo "🟢 Imágenes disponibles:"
for i in "${!image_array[@]}"; do
  echo "$((i+1)). ${image_array[$i]}"
done

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

# Obtener la primera etiqueta disponible, si no hay usar latest
tag=$(gcloud container images list-tags "gcr.io/$project_name/$image_name" --format='get(tags)' --limit=1 | head -n1)
tag=${tag:-latest}

read -p $'\n¿Deseas eliminar el servicio, la imagen y los archivos locales relacionados? (s/n): ' confirm
if [[ "$confirm" != [sS] ]]; then
  echo "❌ Operación cancelada."
  exit 1
fi

echo -e "\n🗑️ Eliminando servicio Cloud Run..."
gcloud run services delete "$service_name" --platform=managed --region="$region" --quiet

echo "🗑️ Eliminando imagen del contenedor..."
gcloud container images delete "gcr.io/$project_name/$image_name:$tag" --quiet

echo "🧹 Eliminando archivos locales relacionados..."
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

echo -e "\n✅ Proceso de desinstalación completado."
