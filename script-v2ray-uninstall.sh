#!/bin/bash
set -e  # Detener ejecución si ocurre cualquier error

echo "🔍 Obteniendo lista de servicios Cloud Run..."
services=$(gcloud run services list --platform=managed --format="value(metadata.name,location)")
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
images=$(gcloud container images list --format="value(NAME)" | grep "$service_name" || true)

if [ -z "$images" ]; then
  echo "⚠️ No se encontraron imágenes relacionadas con
