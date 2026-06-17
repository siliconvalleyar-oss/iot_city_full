# 🚀 IoT City — Guía de Despliegue

> **Versión:** 1.0.0  
> **Última actualización:** Junio 2026  
> **Plataforma:** Ubuntu/Debian 20.04+ / Python 3.9+

---

## 📋 Requisitos del Sistema

- **SO:** Ubuntu/Debian 20.04+ (o Raspberry Pi OS)
- **Python:** 3.9+ (recomendado 3.12)
- **RAM:** 512 MB mínimo (1 GB recomendado)
- **Disco:** 500 MB libres
- **Puertos:** 5062 (API), 1883 (MQTT opcional)
- **Opcional:** Mosquitto MQTT Broker

---

## ⚡ Instalación Rápida

### 1. Clonar el repositorio

```bash
git clone <repo-url> iot-city
cd iot-city
```

### 2. Instalación automática

```bash
chmod +x scripts/install_system.sh
./scripts/install_system.sh
```

Esto instalará: Python venv, dependencias pip, Mosquitto (si está disponible).

### 3. Iniciar el sistema

```bash
chmod +x scripts/control_system.sh
./scripts/control_system.sh start
```

### 4. Abrir en navegador

```
http://localhost:5062
```

---

## 🛠️ Instalación Manual Paso a Paso

### 1. Preparar el entorno

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Python y dependencias del sistema
sudo apt install -y python3 python3-pip python3-venv git

# Opcional: MQTT Broker
sudo apt install -y mosquitto mosquitto-clients
sudo systemctl enable mosquitto
sudo systemctl start mosquitto
```

### 2. Crear entorno virtual

```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Instalar dependencias Python

```bash
pip install --upgrade pip
pip install -r backend/requirements.txt
```

### 4. Inicializar el backend

```bash
cd backend
python3 main.py &
cd ..
```

### 5. Iniciar simuladores (opcional)

```bash
# En terminales separadas:

# Simulador de red mesh
python3 simulator/mesh_simulator.py &

# Simulador de gateways MQTT
python3 mqtt/gateway_simulator.py &
```

### 6. Verificar

```bash
# Estado de la API
curl http://localhost:5062/api/devices

# Debería retornar ~20 dispositivos de ciudad demo
```

---

## 🐳 Despliegue con Docker

### docker-compose.yml

```yaml
version: '3.8'

services:
  mqtt:
    image: eclipse-mosquitto:2
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - mosquitto_data:/mosquitto/data
      - mosquitto_log:/mosquitto/log
    restart: unless-stopped

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "5062:5062"
    depends_on:
      - mqtt
    volumes:
      - ./data:/app/data
      - ./frontend:/app/frontend
      - ./assets:/app/assets
      - ./dashboard:/app/dashboard
    environment:
      - PORT=5062
      - HOST=0.0.0.0
      - MQTT_HOST=mqtt
      - MQTT_PORT=1883
    restart: unless-stopped

  simulator:
    build:
      context: ./simulator
      dockerfile: Dockerfile
    depends_on:
      - mqtt
      - backend
    volumes:
      - ./data:/app/data
    restart: unless-stopped

  gateway:
    build:
      context: ./mqtt
      dockerfile: Dockerfile
    depends_on:
      - mqtt
      - backend
    volumes:
      - ./data:/app/data
    restart: unless-stopped

volumes:
  mosquitto_data:
  mosquitto_log:
```

### Dockerfile (backend)

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5062

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5062"]
```

### Iniciar con Docker

```bash
docker compose up -d
docker compose logs -f
```

---

## 🌐 Configuración de Red

### Variables de entorno (`.env`)

```bash
PORT=5062
HOST=0.0.0.0
MQTT_HOST=localhost
MQTT_PORT=1883
DEBUG=false
```

### Firewall (ufw)

```bash
sudo ufw allow 5062/tcp    # API HTTP
sudo ufw allow 1883/tcp    # MQTT
sudo ufw enable
```

### Reverse Proxy (Nginx) — Opcional

```nginx
server {
    listen 80;
    server_name iot-city.tudominio.com;

    location / {
        proxy_pass http://127.0.0.1:5062;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /ws {
        proxy_pass http://127.0.0.1:5062;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

---

## 📊 Uso del Sistema

### Scripts de Control

```bash
./scripts/control_system.sh start     # Iniciar todo
./scripts/control_system.sh stop      # Detener todo
./scripts/control_system.sh restart   # Reiniciar
./scripts/control_system.sh status    # Estado
./scripts/control_system.sh logs      # Ver logs
```

### Gestión de Dispositivos

```bash
# Agregar dispositivo
./scripts/add_device.sh LAMP_001 120 300 router "Av. Mitre"

# Agregar con ícono y color
./scripts/add_device.sh SENSOR_05 400 200 end_device "Calle Belgrano" sensor "#00BFFF"

# Agregar semáforo
./scripts/add_device.sh TRF_001 550 350 router "Av. Corrientes" traffic "#FF6600"

# Listar dispositivos
./scripts/add_device.sh --list

# Eliminar dispositivo
./scripts/add_device.sh --delete LAMP_001

# Carga batch desde CSV
./scripts/add_device.sh --batch dispositivos.csv
```

### Simulaciones

```bash
# Blackout total
curl -X POST http://localhost:5062/api/simulate/blackout

# Restaurar red
curl -X POST http://localhost:5062/api/simulate/restore

# Fallo de nodo específico
curl -X POST http://localhost:5062/api/simulate/fail/LAMP_001
```

---

## 🔧 Mantenimiento

### Logs

```bash
# Logs del backend
tail -f logs/backend.log

# Logs del simulador
tail -f logs/simulator.log
```

### Respaldo de Datos

```bash
# Respaldo de la base de datos de dispositivos
cp data/devices.json backups/devices_$(date +%Y%m%d_%H%M%S).json

# Respaldo completo
tar -czf backup_iot_$(date +%Y%m%d).tar.gz data/ logs/ assets/
```

### Limpieza

```bash
# Limpiar cachés
./scripts/clear_cache.sh

# Reinstalación limpia
./scripts/clean_reinstall.sh
```

---

## 🐛 Solución de Problemas

### Puerto 5062 ocupado

```bash
lsof -ti:5062 | xargs kill
```

### Backend no inicia

```bash
cat logs/backend.log
# Verificar que no hay errores de sintaxis
cd backend && python3 main.py
```

### MQTT no conecta

```bash
sudo systemctl status mosquitto
sudo systemctl restart mosquitto
# Prueba de conexión
mosquitto_sub -h localhost -t 'iot/#' -v
```

### Sin datos en el mapa

```bash
curl http://localhost:5062/api/devices
# El backend genera ciudad demo automáticamente al iniciar
```

### Dashboard no carga

```bash
# Verificar que el backend está corriendo
curl http://localhost:5062/api/dashboard/summary
# Revisar logs del backend para errores de WebSocket
```

---

## 📈 Monitoreo

### Health Check

```bash
# Endpoint de salud (futuro)
# curl http://localhost:5062/health

# Verificar métricas
curl http://localhost:5062/api/metrics
```

### Dashboard

El dashboard energético está disponible en:
```
http://localhost:5062/dashboard
```

Incluye:
- KPIs en tiempo real vía WebSocket
- Gráficos de potencia, tráfico y eficiencia
- Mapa de calor de consumo
- Recomendaciones de optimización
- Tabla de nodos con búsqueda y filtros
