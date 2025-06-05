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

# Detectar repositorios Artifact Registry (nombre y región)
declare -A artifact_repos  # clave=repo, valor=region

echo -e "\n🔍 Detectando repositorios Artifact Registry relacionados..."

for img in "${images_to_delete[@]}"; do
  # Ejemplo repo Artifact Registry:
  # us-central1-docker.pkg.dev/my-project/my-repo/my-image
  if [[ "$img" =~ ^([a-z0-9-]+)-docker.pkg.dev/([^/]+)/([^/]+)/.+$ ]]; then
    repo_region="${BASH_REMATCH[1]}"
    repo_project="${BASH_REMATCH[2]}"
    repo_name="${BASH_REMATCH[3]}"
    artifact_repos["$repo_name"]="$repo_region"
  fi
done

if [ ${#artifact_repos[@]} -eq 0 ]; then
  echo "ℹ️ No se detectaron repositorios Artifact Registry en las imágenes seleccionadas."
else
  echo "Repositorios Artifact Registry detectados:"
  for repo in "${!artifact_repos[@]}"; do
    echo " - $repo (región: ${artifact_repos[$repo]})"
  done
fi

read -p $'\n¿Quieres eliminar los repositorios Artifact Registry detectados? (s/n): ' delete_repos_confirm

if [[ "$delete_repos_confirm" =~ ^[sS]$ ]]; then
  for repo in "${!artifact_repos[@]}"; do
    region_repo=${artifact_repos[$repo]}
    echo "Eliminando repositorio Artifact Registry: $repo en región $region_repo"
    gcloud artifacts repositories delete "$repo" --location="$region_repo" --quiet || {
      echo "⚠️ Error eliminando repositorio $repo"
    }
  done
else
  echo "Repositorios no eliminados."
fi

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
  if ! gcloud container images delete "$img" --quiet --force-delete-tags; then
    gcloud artifacts docker images delete "$img" --quiet --delete-tags || \
      echo "⚠️ No se pudo eliminar la imagen $img con los comandos disponibles."
  fi
done

echo "🧹 Eliminando archivos locales relacionados..."

files_to_delete=(
  "./script-v2ray.sh"
  "./script-v2ray-uninstall.sh"
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
