#!/bin/bash

echo "🔍 Obteniendo lista de servicios Cloud Run..."

# Obtener servicios
service_names=$(gcloud run services list --platform=managed --format="value(metadata.name)")
if [ -z "$service_names" ]; then
  echo "❌ No se encontraron servicios Cloud Run."
  exit 1
fi

# Construir arreglo de servicios con sus regiones
declare -a service_array
while IFS= read -r svc; do
  region=$(gcloud run services describe "$svc" --platform=managed --format="value(metadata.annotations.run.googleapis.com/location)")
  service_array+=("$svc $region")
done <<< "$service_names"

# Mostrar lista para selección
echo "🟢 Servicios disponibles:"
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

# Asignar selección
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

# Mostrar imágenes
IFS=$'\n' read -rd '' -a image_array <<< "$images"
echo "🟢 Imágenes disponibles:"
for i in "${!image_array[@]}"; do
  echo "$((i+1)). ${image_array[$i]}"
done

# Selección de imagen
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

# Obtener tag (si existe)
tag=$(gcloud container images list-tags "gcr.io/$project_name/$image_name" --format='get(tags)' --limit=1 | head -n1)
tag=${tag:-latest}

# Confirmación final
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
