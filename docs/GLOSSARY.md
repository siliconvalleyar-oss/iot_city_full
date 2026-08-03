# Glosario — IoT City Web

**Versión:** 1.0.0
**Fecha:** 2026-08-02
**Propósito:** Definiciones de términos del dominio IoT/red mesh y del sistema, para alinear al equipo y a las IAs colaboradoras.

---

## A

| Término | Definición |
|---|---|
| **Active** | Estado lógico ON/OFF de un dispositivo (luminaria encendida/apagada). |
| **ADR (Architecture Decision Record)** | Documento que registra una decisión de arquitectura y su contexto (ver `ADR.md`). |

## B

| Término | Definición |
|---|---|
| **Blackout** | Corte de tensión simulado que apaga toda la red. |
| **BFS (Breadth-First Search)** | Algoritmo de enrutamiento usado por el simulador mesh para encontrar rutas. |

## C

| Término | Definición |
|---|---|
| **Camera** | Tipo de dispositivo urbano con consumo bajo (10–35 W) y telemetría intensiva. |
| **Chart.js** | Biblioteca JS de gráficos usada en el dashboard (v4.4.1, CDN). |
| **connected_to** | Lista de IDs de routers vecinos de un nodo en la mesh. |
| **Consumption** | Consumo de energía del dispositivo en watts (simulado). |

## D

| Término | Definición |
|---|---|
| **Dashboard** | SPA energética con 6 pestañas: Overview, Zonas, Tráfico, Heatmap, Optimización, Nodos. |
| **Device** | Nodo de la red (router, end_device o camera). Ver `DATA_MODEL.md`. |
| **Duty cycle** | Fracción (0–1) del tiempo que el nodo está activo transmitiendo. |
| **devices.json** | Archivo JSON que persiste los dispositivos (`data/`). |

## E

| Término | Definición |
|---|---|
| **End device** | Nodo de la mesh que no reenvía tráfico; se asocia a un router. |
| **Energy optimizer** | Módulo con 4 algoritmos de optimización energética (`energy/optimizer.py`). |
| **End_devices** | Lista de end devices asociados a un router (solo routers). |

## F

| Término | Definición |
|---|---|
| **Fail / Fallo de nodo** | Simulación de caída de un nodo (permanece apagado hasta restauración). |
| **Firmware snippets** | Header C/C++ para el nodo MRF24J40 + ATmega (`firmware_snippets/iot_city_node.h`). |

## G

| Término | Definición |
|---|---|
| **Gateway** | Raspberry Pi simulada que publica telemetría a MQTT (Norte, Centro, Sur). |
| **GW_001** | Gateway único del `mesh_simulator` (distinto de los 3 del `gateway_simulator`). |

## H

| Término | Definición |
|---|---|
| **Heatmap** | Mapa de calor de consumo energético sobre la vista ciudad. |

## I

| Término | Definición |
|---|---|
| **Icon** | Ícono SVG del dispositivo (`lamp`, `traffic`, `sensor`, `camera`, `router`). |
| **IoT City** | Plataforma de gestión de luminarias y dispositivos urbanos con red mesh Zigbee simulada. |

## L

| Término | Definición |
|---|---|
| **last_seen** | Timestamp epoch de la última telemetría recibida del dispositivo. |
| **Level** | Nivel de luz/batería (0–100). Un nodo con level < 50 se muestra ámbar. |
| **LQI (Link Quality Indicator)** | Indicador de calidad de enlace (100–255) publicado por gateways. |

## M

| Término | Definición |
|---|---|
| **Mesh** | Topología de red donde cada nodo se conecta a los 2 routers más cercanos. |
| **Metrics engine** | Motor de métricas energéticas (`analytics/metrics_engine.py`) con `NodeEnergyModel`. |
| **MRF24J40** | Transceptor 802.15.4/Zigbee de Microchip; base del modelo de consumo. |
| **MQTT** | Protocolo pub/sub usado para telemetría (broker Mosquitto, puerto 1883). |

## N

| Término | Definición |
|---|---|
| **NodeEnergyModel** | Modelo matemático de consumo por nodo basado en el datasheet DS39776C. |
| **Network update** | Broadcast WS periódico (~3 s) con devices + metrics completos. |

## O

| Término | Definición |
|---|---|
| **Optimization** | Aplicación de estrategias (duty cycling, TX power, agregación, intervalo) por nodo. |
| **Overlay** | Capa del mapa: enlaces mesh, anillos de cobertura, etc. |

## P

| Término | Definición |
|---|---|
| **Packets sent/received** | Contadores de paquetes TX/RX acumulados por nodo. |
| **Palette** | Tema de colores configurable (`/api/admin/palettes`). |
| **Pattern** | Patrón geométrico de generación de ciudad (ring, grid, star, spiral, cluster…). |
| **Powered** | Tensión eléctrica presente en el dispositivo (diferente de `active`). |

## R

| Término | Definición |
|---|---|
| **Router** | Nodo de la mesh que reenvía tráfico; conecta end devices. |
| **RSSI** | Potencia de señal recibida en dBm (−100..−30). |
| **Restore** | Restauración de la red tras blackout. |

## S

| Término | Definición |
|---|---|
| **Seed** | Semilla de `random.Random` para generación reproducible de la ciudad. |
| **Signal** | RSSI del dispositivo (dBm). |
| **Snapshot** | Snapshot histórico de métricas en `data/metrics/`. |
| **Sleep mode** | Modo de bajo consumo del nodo (idle/power_save/power_down). |
| **Street** | Calle/avenida donde está el dispositivo. |

## T

| Término | Definición |
|---|---|
| **Telemetry** | Mensaje MQTT con estado del dispositivo (consumo, señal, paquetes). |
| **Timeseries** | Serie temporal de potencia/tráfico por nodo o global. |
| **Toggle** | Acción WS/API que conmuta `active` de un dispositivo. |

## W

| Término | Definición |
|---|---|
| **WebSocket** | Canal tiempo real (`/ws` mapa, `/api/dashboard/ws` dashboard). |
| **Zone** | Agrupación geográfica de nodos (Norte/Centro/Sur, asignación cíclica). |

---

## Siglas

| Sigla | Significado |
|---|---|
| ADR | Architecture Decision Record |
| API | Application Programming Interface |
| BFS | Breadth-First Search |
| LQI | Link Quality Indicator |
| MQTT | Message Queuing Telemetry Transport |
| RSSI | Received Signal Strength Indicator |
| SNR | Signal-to-Noise Ratio |
| WS | WebSocket |
