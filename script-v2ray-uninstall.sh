#!/bin/bash

set -e

echo "🔍 Obteniendo lista de servicios Cloud Run..."
services=$(gcloud run services list --platform=managed --format="value(metadata.name)")

if [ -z "$services" ]; then
  echo "❌ No se encontraron servicios Cloud Run."
  exit 1
fi

# Convertir servicios a array
IFS=$'\n' read -rd '' -a service_array <<<"$services"

echo "🟢 Servicios disponibles:"
for i in "${!service_array[@]}"; do
  echo "$((i+1)). ${service_array[$i]}"
done

read -p "Selecciona el número del servicio que quieres eliminar: " service_index

if ! [[ "$service_index" =~ ^[0-9]+$ ]] || [ "$service_index" -lt 1 ] || [ "$service_index" -gt "${#service_array[@]}" ]; then
  echo "❌ Selección inválida."
  exit 1
fi

service_name="${service_array[$((service_index-1))]}"
echo "Servicio seleccionado: $service_name"

# Obtener región automáticamente
region=$(gcloud run services describe "$service_name" --platform=managed --format="value(location)")

if [ -z "$region" ]; then
  echo "❌ No se pudo determinar la región del servicio."
  exit 1
fi

echo "Región detectada automáticamente: $region"

# Obtener imágenes usadas por revisiones del servicio
echo -e "\n🔍 Obteniendo imágenes usadas en revisiones del servicio..."

images=()
readarray -t images < <(gcloud run revisions list --service="$service_name" --platform=managed --region="$region" --format="value(spec.containers[0].image)")

if [ ${#images[@]} -eq 0 ]; then
  echo "⚠️ No se encontraron imágenes asociadas a las revisiones."
  echo "Intentando buscar imágenes que contengan el nombre del servicio..."

  images_raw=$(gcloud container images list --format="value(NAME)" | grep "$service_name" || true)

  if [ -z "$images_raw" ]; then
    echo "❌ No se encontraron imágenes relacionadas con el servicio."
    exit 1
  fi

  readarray -t images <<<"$images_raw"
fi

echo "🟢 Imágenes encontradas:"
for i in "${!images[@]}"; do
  echo "$((i+1)). ${images[$i]}"
done

read -p "Selecciona el número de la imagen que quieres eliminar (o presiona Enter para eliminar todas): " image_index

images_to_delete=()

if [[ -z "$image_index" ]]; then
  images_to_delete=("${images[@]}")
else
  if ! [[ "$image_index" =~ ^[0-9]+$ ]] || [ "$image_index" -lt 1 ] || [ "$image_index" -gt "${#images[@]}" ]; then
    echo "❌ Selección inválida."
    exit 1
  fi
  images_to_delete=("${images[$((image_index-1))]}")
fi

# Detectar repositorios para mostrar (no elimina automáticamente)
repositories=()
for img in "${images_to_delete[@]}"; do
  if [[ "$img" =~ ^gcr.io/([^/]+)/([^:@]+) ]]; then
    repositories+=("gcr.io/${BASH_REMATCH[1]}")
  elif [[ "$img" =~ ^([a-z0-9-]+)-docker.pkg.dev/([^/]+)/([^/]+)/([^:@]+) ]]; then
    repo="${BASH_REMATCH[1]}-docker.pkg.dev/${BASH_REMATCH[2]}/${BASH_REMATCH[3]}"
    repositories+=("$repo")
  fi
done

repositories=($(printf "%s\n" "${repositories[@]}" | sort -u))

echo -e "\nRepositorios detectados relacionados a las imágenes:"
for repo in "${repositories[@]}"; do
  echo " - $repo"
done

read -p $'\n¿Confirmas que deseas eliminar el servicio, las imágenes seleccionadas y los archivos locales relacionados? (s/n): ' confirm
if [[ ! "$confirm" =~ ^[sS]$ ]]; then
  echo "❌ Operación cancelada."
  exit 0
fi

echo -e "\n🗑️ Eliminando servicio Cloud Run..."
gcloud run services delete "$service_name" --platform=managed --region="$region" --quiet

echo "🗑️ Eliminando imágenes seleccionadas..."
for img in "${images_to_delete[@]}"; do
  echo "Eliminando imagen: $img"
  # Primero intentar con container images delete, si falla intentar artifacts docker images delete
  if ! gcloud container images delete "$img" --quiet --force-delete-tags; then
    gcloud artifacts docker images delete "$img" --quiet --delete-tags || \
      echo "⚠️ No se pudo eliminar la imagen $img con los comandos disponibles."
  fi
done

echo "🧹 Eliminando archivos locales relacionados..."

files_to_delete=(
  "./script-v2ray.sh"
  "./script-v2ray-uninstall.sh"
  # Agrega otros archivos o carpetas si los conoces
)

for file in "${files_to_delete[@]}"; do
  if [ -e "$file" ]; then
    echo "Eliminando $file"
    rm -rf "$file"
  else
    echo "Archivo $file no encontrado, saltando."
  fi
done

echo -e "\n✅ Proceso de desinstalación completado."
