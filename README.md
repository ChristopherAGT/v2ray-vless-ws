# 🚀 Despliegue Automático de V2Ray (VLESS + WS) en Google Cloud Run

Este documento describe cómo ejecutar un script directamente desde tu repositorio de GitHub en Google Cloud Shell para desplegar automáticamente un servicio VLESS + WebSocket usando Docker y Cloud Run.

---

## 📌 Requisitos Previos

Antes de comenzar, asegúrate de:

- ✅ Tener una cuenta activa en [Google Cloud Platform (GCP)](https://console.cloud.google.com/).
- ✅ Haber creado un proyecto de GCP.
- ✅ Tener habilitado el servicio **Cloud Shell**.
- ✅ Haber ejecutado `gcloud init` al menos una vez.

---

## 🧰 Herramientas utilizadas

- **Google Cloud SDK (`gcloud`)**
- **Docker** (preinstalado en Cloud Shell)
- **Cloud Run**
- **Git**

---

## 📦 Repositorio del Proyecto

El script automatizado se encuentra en el siguiente repositorio de GitHub:

🔗 [`https://github.com/ChristopherAGT/v2ray-vless-ws`](https://github.com/ChristopherAGT/v2ray-vless-ws)

---

## 🔧 Paso 1: Ejecutar el Script desde Cloud Shell

En tu **Google Cloud Shell**, copia y pega el siguiente comando para ejecutar el script directamente desde GitHub:

```bash
bash <(curl -s https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/deploy.sh)
```

Este comando:
1. Descarga el archivo `deploy.sh` desde el repositorio.
2. Lo ejecuta directamente en Cloud Shell.

---

## ⚙️ ¿Qué Hace Este Script?

1. 🔍 **Obtiene el ID del proyecto activo** en GCP.
2. 🌀 **Clona el repositorio** si es necesario.
3. 🛠️ **Construye una imagen Docker** con V2Ray VLESS + WebSocket.
4. ⏫ **Sube la imagen** a Google Container Registry.
5. 🚀 **Despliega el servicio** en Cloud Run.
6. ✅ Muestra un mensaje de éxito con detalles.

---

## 📁 Archivos importantes

- `deploy.sh` → Script automatizado de despliegue.
- `config.json` → Archivo de configuración de V2Ray (puede usarse para generar un link de descarga más adelante).
- `Dockerfile` → Instrucciones para construir la imagen Docker.

---

## 📝 Notas Finales

- Puedes modificar `deploy.sh` para adaptarlo a tus necesidades.
- Asegúrate de tener permisos suficientes en el proyecto de GCP.
- Revisa que el puerto `8080` esté permitido en Cloud Run.
