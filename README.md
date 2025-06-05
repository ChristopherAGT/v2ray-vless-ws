# 🚀 Despliegue Automático de V2Ray (VLESS + WS) en Google Cloud Run

Este documento describe cómo ejecutar un script directamente desde tu repositorio de GitHub en Google Cloud Shell para desplegar automáticamente un servicio VLESS + WebSocket usando Docker y Cloud Run.

---

## 📌 Requisitos Previos

Antes de comenzar, asegúrate de lo siguiente:

- ✅ Tener una cuenta activa en [Google Cloud Platform (GCP)](https://console.cloud.google.com/).
- ✅ Haber creado un proyecto en GCP.
- ✅ Tener habilitado el servicio **Cloud Shell**.
- ✅ Haber ejecutado `gcloud init` al menos una vez (el script lo pedirá si es necesario).

---

## 🧰 Herramientas Utilizadas

- 🛠️ **Google Cloud SDK (`gcloud`)**  
- 🐳 **Docker** (preinstalado en Cloud Shell)  
- ☁️ **Cloud Run**  
- 🔗 **Git**

---

## 📦 Repositorio del Proyecto

El script automatizado se encuentra en el siguiente repositorio:

🔗 [`https://github.com/ChristopherAGT/v2ray-vless-ws`](https://github.com/ChristopherAGT/v2ray-vless-ws)

---

## 🔧 Paso 1: Ejecutar el Script desde Cloud Shell

En **Google Cloud Shell**, copia y pega el siguiente comando para descargar y ejecutar el script directamente desde GitHub:

```bash
wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/script-v2ray.sh -O script-v2ray.sh && bash script-v2ray.sh
```

Este comando hace lo siguiente:

1. 📥 Descarga el archivo `script-v2ray.sh` desde el repositorio.  
2. ▶️ Lo ejecuta automáticamente en tu entorno de Cloud Shell.

---

## ⚙️ ¿Qué Hace Este Script?

1. 🔍 Verifica el proyecto activo en GCP.  
2. 🌀 Clona el repositorio `v2ray-vless-ws` si no está presente.  
3. 🛠️ Construye una imagen Docker basada en el `Dockerfile` incluido.  
4. ⏫ Sube la imagen al Container Registry (`gcr.io`).  
5. 🚀 Despliega el servicio en Cloud Run (región predeterminada: `us-east1`, puerto: `8080`).  
6. ✅ Muestra un mensaje final de éxito con los detalles del servicio.

---

## 📁 Archivos Importantes

- `script-v2ray.sh` → Script automatizado de despliegue (ejecutable en Cloud Shell).  
- `config.json` → Configuración para V2Ray (puedes modificarlo o generar un link de descarga si lo deseas).  
- `Dockerfile` → Define cómo se construye la imagen Docker para V2Ray.

---

## 📌 Recomendaciones Finales

- 🔒 Verifica que tengas permisos suficientes para desplegar servicios en el proyecto.  
- 🔁 Puedes modificar el script según tus necesidades (cambiar región, puertos, configuración, etc.).  
- 🔗 Si deseas generar un enlace de descarga para el `config.json`, puedes añadir esa funcionalidad directamente en el script.

---
