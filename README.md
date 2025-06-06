# 🚀 Despliegue Automático de V2Ray (VLESS + WS) en Google Cloud Run

Este repositorio permite desplegar y remover automáticamente un servidor **V2Ray (VLESS + WebSocket)** utilizando **Docker** y **Google Cloud Run**, todo desde **Google Cloud Shell** con un solo comando.

---

## ✅ Requisitos Previos

Antes de comenzar, asegúrate de lo siguiente:

- Tener una cuenta activa en [Google Cloud Platform (GCP)](https://console.cloud.google.com/).
- Haber creado un proyecto en GCP.
- Tener habilitado el servicio **Cloud Shell**.

> ℹ️ El script solicitará las configuraciones necesarias durante la ejecución si no están previamente establecidas.

---

## 🛠 Herramientas Utilizadas

- **Google Cloud SDK (`gcloud`)**
- **Docker** (preinstalado en Cloud Shell)
- **Cloud Run**
- **Git**

---

## 📦 Repositorio Base del Proyecto

Este script se apoya en los recursos y configuraciones incluidos en el siguiente repositorio base:

🔗 [`https://github.com/ChristopherAGT/gcp-v2ray`](https://github.com/ChristopherAGT/gcp-v2ray)

---

## 🏗️ Construcción

En **Google Cloud Shell**, ejecuta el siguiente comando para desplegar automáticamente el servicio:

```bash
wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/script-v2ray.sh -O script-v2ray.sh && bash script-v2ray.sh
```

### 🧱 Este script:

- 🧩 Solicita un nombre personalizado para la imagen Docker.
- 🌍 Muestra una lista de regiones disponibles en Cloud Run para que elijas dónde desplegar tu servicio.
- 📸 Al finalizar, muestra una serie de **datos importantes** que debes **guardar o capturar en pantalla**, ya que son necesarios para configurar tu cliente.

### 📋 Detalles sobre la función de este cript:

- 🔎 Verifica el proyecto activo en GCP.
- 📂 Clona el repositorio base si aún no está presente.
- 🛠️ Construye una imagen Docker personalizada con la configuración de V2Ray.
- ☁️ Sube la imagen al Container Registry (gcr.io).
- 🚀 Despliega el servicio en Cloud Run, utilizando los parámetros seleccionados.

---

## 🧹 Remover Servicios

Para eliminar servicios desplegados previamente, ejecuta:

```bash
wget -q https://raw.githubusercontent.com/ChristopherAGT/v2ray-vless-ws/main/script-v2ray-uninstall.sh -O script-v2ray-uninstall.sh && bash script-v2ray-uninstall.sh
```

Este proceso incluye:

- ⏳ Esperar unos segundos mientras se cargan los servicios disponibles.  
- 📋 Seleccionar el servicio que deseas eliminar de Cloud Run.  
- 🧼 Elegir si también deseas eliminar la imagen del contenedor en Container Registry.

---

## 🧾 Configuración Importante

- 📜 `script-v2ray.sh` → Script automatizado de despliegue.  
- 📜 `script-v2ray-uninstall.sh` → Script para remover servicios y limpiar recursos.  
- 📜 `config.json` → Configuración de V2Ray (puedes personalizarla).  
- 📜 `Dockerfile` → Define la imagen Docker del servicio.

---

## 🔗 Config URI

Una vez desplegado el servicio, puedes utilizar el siguiente formato para configurar tu cliente:

```bash
vless://TU-UUID@TU-BUG-HOST:443?path=%2FCloud-CDN%2F&security=tls&encryption=none&host=TU-SUBDOMINIO-GOOGLE-CLOUD&fp=random&type=ws&sni=TU-BUG-HOST#
```

🔧 **Importante:** Asegúrate de reemplazar los siguientes campos según corresponda:

- `añade.tu.uuid.generado` → UUID generado automáticamente durante la instalación.
- `añade.tu.bug.host` → Host de bug (por ejemplo, `www.microsoft.com`).
- `añade.tu.subdominio.google.cloud` → Subdominio que apunta a tu servicio en Cloud Run.

---

Con este sistema, el despliegue y la eliminación de servicios son rápidos, seguros y totalmente automáticos desde Google Cloud Shell.  
✨ **Simplemente copia, pega y sigue las instrucciones en pantalla.**
