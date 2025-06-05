#!/bin/bash

# Regiones definidas (ajusta según necesidad)
regions=(
  us-central1 us-east1 us-east4 us-west1
  europe-west1 europe-west4
  asia-northeast1 asia-southeast1
)

declare -a service_array

echo "🔍 Buscando servicios Cloud Run en todas las regiones..."

# Buscar servicios en todas las regiones
for region in "${regions[@]}"; do
  services=$(gcloud run services list --platform=managed --region="$region" --format="value(metadata.name)" 2>/dev/null)
  if [ -n "$services" ]; then
    while IFS= read -r svc; do
      [[ -n "$svc" ]] && service_array+=("$svc::$region")
    done <<< "$services"
  fi
done

# Validar si se encontraron servicios
if [ ${#service_array[@]} -eq 0 ]; then
  echo "❌ No se encontraron servicios Cloud Run en las regiones definidas."
  exit 1
fi

echo "🟢 Servicios disponibles:"
for i in "${!service_array[@]}"; do
  svc_name="${service_array[$i]%%::*}"
  svc_region="${service_array[$i]##*::}"
  echo "$((i+1)). Servicio: $svc_name, Región: $svc_region"
done

read -rp "Selecciona el número del servicio que quieres eliminar: " service_index
if ! [[ "$service_index" =~ ^[0-9]+$ ]] || [ "$service_index" -lt 1 ] || [ "$service_index" -gt "${#service_array[@]}" ]; then
  echo "❌ Selección inválida."
  exit 1
fi

selected="${service_array[$((service_index-1))]}"
service_name="${selected%%::*}"
region="${selected##*::}"

echo -e "\n🔎 Detalles del servicio seleccionado:"
echo "Nombre : $service_name"
echo "Región : $region"

echo -e "\n🔍 Buscando imágenes relacionadas en Container Registry..."
images=$(gcloud container images list --format="value(NAME)" | grep "/$service_name$")

if [ -z "$images" ]; then
  echo "⚠️ No se encontraron imágenes relacionadas. Mostrando todas..."
  images=$(gcloud container images list --format="value(NAME)")
  [ -z "$images" ] && echo "❌ No hay imágenes disponibles." && exit 1
fi

IFS=$'\n' read -rd '' -a image_array <<< "$images"

echo "🟢 Imágenes disponibles:"
for i in "${!image_array[@]}"; do
  echo "$((i+1)). ${image_array[$i]}"
done

read -rp "Selecciona el número de la imagen que quieres eliminar: " image_index
if ! [[ "$image_index" =~ ^[0-9]+$ ]] || [ "$image_index" -lt 1 ] || [ "$image_index" -gt "${#image_array[@]}" ]; then
  echo "❌ Selección inválida."
  exit 1
fi

selected_image="${image_array[$((image_index-1))]}"
project_and_image="${selected_image#gcr.io/}"
project_name="${project_and_image%%/*}"
image_name="${project_and_image#*/}"

echo -e "\n✅ Imagen seleccionada:"
echo "Proyecto : $project_name"
echo "Imagen   : $image_name"

# Obtener etiqueta
tag=$(gcloud container images list-tags "gcr.io/$project_name/$image_name" --format='value(tags)' --limit=1 | head -n1 | cut -d',' -f1)
tag=${tag:-latest}

# Validar formato correcto de tag
if [[ "$tag" =~ ^sha256:* ]]; then
  image_ref="gcr.io/$project_name/$image_name@$tag"
else
  image_ref="gcr.io/$project_name/$image_name:$tag"
fi

read -rp $'\n¿Deseas eliminar el servicio, la imagen y los archivos locales relacionados? (s/n): ' confirm
if [[ ! "$confirm" =~ ^[sS]$ ]]; then
  echo "❌ Operación cancelada."
  exit 1
fi

echo -e "\n🗑️ Eliminando servicio Cloud Run..."
gcloud run services delete "$service_name" --platform=managed --region="$region" --quiet

echo "🗑️ Eliminando imagen del contenedor..."
gcloud container images delete "$image_ref" --quiet || echo "⚠️ Imagen no encontrada o ya eliminada."

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
