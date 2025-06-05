#!/bin/bash

echo "🔍 Obteniendo lista de servicios Cloud Run..."
services=$(gcloud run services list --platform=managed --format="value(metadata.name)")
if [ -z "$services" ]; then
  echo "❌ No se encontraron servicios Cloud Run."
  exit 1
fi

# Mostrar servicios enumerados
echo "🟢 Servicios disponibles:"
IFS=$'\n' read -rd '' -a service_array <<<"$services"
for i in "${!service_array[@]}"; do
  echo "$((i+1)). Servicio: ${service_array[$i]}"
done

# Selección del servicio
read -p "Selecciona el número del servicio que quieres eliminar: " service_index
if ! [[ "$service_index" =~ ^[0-9]+$ ]] || [ "$service_index" -lt 1 ] || [ "$service_index" -gt "${#service_array[@]}" ]; then
  echo "❌ Selección inválida."
  exit 1
fi

service_name="${service_array[$((service_index-1))]}"
echo "Servicio seleccionado: $service_name"

# Obtener región del servicio automáticamente
region=$(gcloud run services describe "$service_name" --platform=managed --format="value(location)")
if [ -z "$region" ]; then
  echo "❌ No se pudo determinar la región del servicio."
  exit 1
fi
echo "Región detectada: $region"

# Obtener imagen(s) asociadas al servicio
echo -e "\n🔍 Buscando imagen(es) asociada(s) al servicio..."

# Listar revisiones y obtener la imagen usada en cada revisión
images=()
revisions=$(gcloud run revisions list --service="$service_name" --platform=managed --region="$region" --format="value(spec.containers[0].image)")
if [ -z "$revisions" ]; then
  echo "⚠️ No se encontraron imágenes asociadas al servicio."
else
  IFS=$'\n' read -rd '' -a images <<<"$revisions"
fi

if [ ${#images[@]} -eq 0 ]; then
  echo "⚠️ No se detectaron imágenes. Listando imágenes relacionadas por nombre del servicio..."

  images_raw=$(gcloud container images list --format="value(NAME)" | grep "$service_name")

  if [ -z "$images_raw" ]; then
    echo "❌ No se encontraron imágenes en Container Registry relacionadas."
  else
    IFS=$'\n' read -rd '' -a images <<<"$images_raw"
  fi
fi

if [ ${#images[@]} -eq 0 ]; then
  echo "❌ No se encontraron imágenes para eliminar."
else
  echo "🟢 Imágenes encontradas:"
  for i in "${!images[@]}"; do
    echo "$((i+1)). ${images[$i]}"
  done

  read -p "Selecciona el número de la imagen que quieres eliminar (o presiona Enter para eliminar todas): " img_index

  images_to_delete=()
  if [[ -z "$img_index" ]]; then
    images_to_delete=("${images[@]}")
  else
    if ! [[ "$img_index" =~ ^[0-9]+$ ]] || [ "$img_index" -lt 1 ] || [ "$img_index" -gt "${#images[@]}" ]; then
      echo "❌ Selección inválida."
      exit 1
    fi
    images_to_delete=("${images[$((img_index-1))]}")
  fi
fi

# Detectar repositorios a partir de imágenes (asumiendo gcr.io o region-docker.pkg.dev)
repositories=()
for img in "${images_to_delete[@]}"; do
  # Extraer repo según el formato
  if [[ "$img" =~ ^gcr.io/([^/]+)/([^:@]+) ]]; then
    repositories+=("gcr.io/${BASH_REMATCH[1]}")
  elif [[ "$img" =~ ^([a-z0-9-]+)-docker.pkg.dev/([^/]+)/([^/]+)/([^:@]+) ]]; then
    repo="${BASH_REMATCH[1]}-docker.pkg.dev/${BASH_REMATCH[2]}/${BASH_REMATCH[3]}"
    repositories+=("$repo")
  fi
done

# Eliminar duplicados en repositorios
repositories=($(echo "${repositories[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

echo -e "\nRepositorios detectados para posible eliminación:"
for repo in "${repositories[@]}"; do
  echo " - $repo"
done

# Confirmación final
read -p $'\n¿Deseas eliminar el servicio, las imágenes seleccionadas y los repositorios detectados? (s/n): ' confirm
if [[ "$confirm" != [sS] ]]; then
  echo "❌ Operación cancelada."
  exit 1
fi

echo -e "\n🗑️ Eliminando servicio Cloud Run..."
gcloud run services delete "$service_name" --platform=managed --region="$region" --quiet

if [ ${#images_to_delete[@]} -gt 0 ]; then
  for img in "${images_to_delete[@]}"; do
    echo "🗑️ Eliminando imagen: $img"
    gcloud container images delete "$img" --quiet --force-delete-tags || \
    gcloud artifacts docker images delete "$img" --quiet --delete-tags || \
    echo "⚠️ No se pudo eliminar la imagen $img con gcloud container images ni artifacts."
  done
fi

# Opción para eliminar repositorios (solo si quieres)
read -p $'\n¿Quieres eliminar los repositorios detectados? Esto puede afectar otros recursos. (s/n): ' del_repos
if [[ "$del_repos" == [sS] ]]; then
  for repo in "${repositories[@]}"; do
    echo "🗑️ Eliminando repositorio: $repo"
    # Para Artifact Registry, eliminar repositorio puede requerir permisos y cuidado, ejemplo:
    # gcloud artifacts repositories delete "$repo" --location="$region" --quiet
    echo "⚠️ No se implementó eliminación automática de repositorios, debes hacerlo manualmente si es necesario."
  done
fi

echo "🧹 Eliminando archivos locales relacionados..."

files_to_delete=(
  "./script-v2ray.sh"
  "./script-v2ray-uninstall.sh"
  # Agrega más archivos o rutas si las conoces
)

for file in "${files_to_delete[@]}"; do
  if [ -f "$file" ]; then
    echo "🗑️ Eliminando archivo $file"
    rm -f "$file"
  else
    echo "ℹ️ Archivo $file no encontrado, saltando."
  fi
done

echo -e "\n✅ Proceso de desinstalación completado."
