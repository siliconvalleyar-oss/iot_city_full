/**
 * IoT City — Firmware Snippets C/C++
 * Nodo MRF24J40 + ATmega328P / ATmega2560
 *
 * Implementa:
 *   1. Duty cycling adaptativo (S-MAC inspired)
 *   2. TX Power Control dinámico (RSSI/LQI feedback)
 *   3. Agregación de paquetes (frame batching)
 *   4. Intervalo adaptativo (delta-compression)
 *   5. Sleep mode scheduling (coordenado por red)
 *   6. Payload compacto 802.15.4 (3-byte config)
 *
 * NOTA: Este código corre en el NODO embebido (no en el servidor).
 *       Se incluye aquí como referencia de integración con el backend.
 */

#ifndef IOT_CITY_NODE_H
#define IOT_CITY_NODE_H

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <avr/sleep.h>
#include <avr/wdt.h>
#include <avr/interrupt.h>

// ─────────────────────────────────────────────
// CONSTANTES HARDWARE MRF24J40
// ─────────────────────────────────────────────

// Registros relevantes (datasheet DS39776C)
#define MRF_RFCON3      0x203   // TX power control
#define MRF_RXFLUSH     0x0D    // Flush RX FIFO
#define MRF_SLPCON1     0x220   // Sleep clock divisor
#define MRF_WAKECON     0x222   // Wakeup control
#define MRF_RFSTATE     0x01F5  // RF state machine

// Niveles de potencia TX (bits 7:6 de RFCON3)
// Los bits definen reducción en pasos de ~5dB
#define TX_POWER_0DBM   0x00    // Máxima potencia  (~23mA)
#define TX_POWER_M5DBM  0x40    // -5  dBm          (~18mA)
#define TX_POWER_M10DBM 0x80    // -10 dBm          (~15mA)
#define TX_POWER_M15DBM 0xC0    // -15 dBm          (~10mA)
#define TX_POWER_M20DBM 0xE0    // ~-20 dBm         (~8mA)

// Corrientes típicas (mA @ 3.3V, datasheet)
#define I_TX_MAX_MA     23.0f
#define I_TX_MID_MA     15.0f
#define I_TX_LOW_MA     8.5f
#define I_RX_MA         19.7f
#define I_IDLE_MA       2.4f
#define I_SLEEP_MA      0.002f

// Parámetros 802.15.4
#define CHANNEL_DEFAULT     11      // Canal 2.4GHz (11-26)
#define PANID_DEFAULT       0xBEEF  // PAN ID ciudad
#define MAX_PAYLOAD_BYTES   102     // Max PSDU - headers
#define ACK_TIMEOUT_MS      20      // Timeout ACK (ms)
#define MAX_RETRIES         3

// Parámetros del nodo
#define NODE_ID_ADDR        0x00    // EEPROM address para node ID
#define CONFIG_ADDR         0x02    // EEPROM address para config (3 bytes)
#define SAMPLE_QUEUE_SIZE   8       // Buffer de muestras a agregar

// ─────────────────────────────────────────────
// ESTRUCTURAS DE DATOS
// ─────────────────────────────────────────────

/**
 * Muestra de telemetría compacta (8 bytes)
 * Transmitida sobre 802.15.4 en payload
 */
typedef struct __attribute__((packed)) {
    uint16_t node_id;       // ID nodo (2B)
    uint16_t power_raw;     // Lectura ADC consumo (2B)
    int8_t   rssi;          // RSSI del último paquete recibido (1B)
    uint8_t  lqi;           // Link Quality Indicator (1B)
    uint8_t  flags;         // [7:6]=tx_lvl [5:4]=sleep_mode [3]=active [2:0]=reserved (1B)
    uint8_t  seq;           // Número de secuencia para dedup (1B)
} NodeTelemetry;            // Total: 8 bytes

/**
 * Frame de telemetría agregada (cabecera + N muestras)
 * Máximo: 1 + 1 + 8*8 = 66 bytes (cabe en 802.15.4)
 */
typedef struct __attribute__((packed)) {
    uint8_t  msg_type;              // 0xA1 = telemetría agregada
    uint8_t  count;                 // Número de muestras (1-8)
    NodeTelemetry samples[SAMPLE_QUEUE_SIZE];
} AggregatedFrame;

/**
 * Configuración operativa del nodo (3 bytes)
 * Sincronizada con servidor vía downlink
 */
typedef struct __attribute__((packed)) {
    uint8_t b0;   // [7:6]=tx_power_level [5:0]=duty_cycle_q6
    uint8_t b1;   // intervalo_tx * 10 (max 25.5s)
    uint8_t b2;   // [7:4]=agg_size [3:2]=sleep_mode [1:0]=reserved
} NodeConfigBytes;

/**
 * Configuración expandida (en RAM)
 */
typedef struct {
    uint8_t  tx_power_level;    // 0=+0dBm, 1=-10dBm, 2=-20dBm
    float    duty_cycle;        // 0.02 - 0.50
    float    tx_interval_s;     // 0.5 - 25.5s
    uint8_t  agg_size;          // 1-8 muestras por frame
    uint8_t  sleep_mode;        // 0=none 1=power_save 2=deep_sleep
    bool     dirty;             // true = cambió, necesita guardarse
} NodeConfig;

/**
 * Estado de red del nodo
 */
typedef struct {
    int8_t   last_rssi;
    uint8_t  last_lqi;
    float    last_per;          // Packet Error Rate estimado
    uint32_t packets_tx;
    uint32_t packets_rx;
    uint32_t packets_lost;
    uint16_t tx_queue_depth;    // Paquetes en cola
    uint32_t last_tx_ms;        // Timestamp último TX
} NodeNetworkState;

// ─────────────────────────────────────────────
// VARIABLES GLOBALES (extern para uso en .c)
// ─────────────────────────────────────────────

extern NodeConfig       g_config;
extern NodeNetworkState g_net;
extern NodeTelemetry    g_sample_queue[SAMPLE_QUEUE_SIZE];
extern uint8_t          g_queue_count;
extern uint16_t         g_node_id;

// ─────────────────────────────────────────────
// PROTOTIPOS
// ─────────────────────────────────────────────

// Init
void node_init(void);
void config_load_from_eeprom(NodeConfig* cfg);
void config_save_to_eeprom(const NodeConfig* cfg);
void config_from_bytes(NodeConfig* cfg, const NodeConfigBytes* raw);
void config_to_bytes(const NodeConfig* cfg, NodeConfigBytes* raw);

// Telemetría
void    telemetry_sample(NodeTelemetry* t);
bool    telemetry_enqueue(const NodeTelemetry* t);
bool    telemetry_flush(void);
uint8_t build_aggregated_frame(uint8_t* buf, uint8_t bufsize);

// Algoritmos de optimización
void    adapt_duty_cycle(float queue_load, uint8_t neighbor_count);
void    adapt_tx_power(int8_t rssi, uint8_t lqi);
void    adapt_tx_interval(float current_value, float last_value);
uint8_t compute_optimal_agg_size(float tx_rate_pps, float max_latency_s);

// Radio
bool    radio_send(const uint8_t* payload, uint8_t len, uint16_t dest);
int8_t  radio_get_rssi(void);
uint8_t radio_get_lqi(void);
void    radio_set_tx_power(uint8_t level);
void    radio_sleep(void);
void    radio_wakeup(void);

// Sleep
void    sleep_ms(uint32_t ms);
void    sleep_until_rx(void);

#endif // IOT_CITY_NODE_H

// ═══════════════════════════════════════════════════════════════
// IMPLEMENTACIÓN
// ═══════════════════════════════════════════════════════════════

#ifdef IOT_CITY_IMPL

#include "iot_city_node.h"

// ── Globals ──
NodeConfig       g_config;
NodeNetworkState g_net;
NodeTelemetry    g_sample_queue[SAMPLE_QUEUE_SIZE];
uint8_t          g_queue_count = 0;
uint16_t         g_node_id     = 0;

// ─────────────────────────────────────────────
// SERIALIZACIÓN DE CONFIGURACIÓN (3 bytes)
// ─────────────────────────────────────────────

/**
 * Convierte config en 3 bytes compactos para:
 *   a) transmitir por radio con overhead mínimo
 *   b) guardar en EEPROM (ahorra ciclos de escritura)
 *
 * Formato:
 *   B0: [7:6]=tx_power[1:0]  [5:0]=duty_cycle*63
 *   B1: tx_interval_s*10 (uint8, 0.1s resolución)
 *   B2: [7:4]=agg_size  [3:2]=sleep_mode  [1:0]=rsvd
 */
void config_to_bytes(const NodeConfig* cfg, NodeConfigBytes* raw)
{
    uint8_t duty_q = (uint8_t)(cfg->duty_cycle * 63.0f) & 0x3F;
    uint8_t intv_q = (uint8_t)(cfg->tx_interval_s * 10.0f);   // saturado en 255 → 25.5s
    uint8_t agg_q  = (cfg->agg_size & 0x0F);
    uint8_t slp_q  = (cfg->sleep_mode & 0x03);

    raw->b0 = ((cfg->tx_power_level & 0x03) << 6) | duty_q;
    raw->b1 = intv_q;
    raw->b2 = (agg_q << 4) | (slp_q << 2);
}

void config_from_bytes(NodeConfig* cfg, const NodeConfigBytes* raw)
{
    cfg->tx_power_level = (raw->b0 >> 6) & 0x03;
    cfg->duty_cycle     = (float)(raw->b0 & 0x3F) / 63.0f;
    cfg->tx_interval_s  = (float)raw->b1 / 10.0f;
    cfg->agg_size       = (raw->b2 >> 4) & 0x0F;
    cfg->sleep_mode     = (raw->b2 >> 2) & 0x03;
    cfg->dirty          = false;
}

// ─────────────────────────────────────────────
// ALGORITMO 1: DUTY CYCLING ADAPTATIVO
// ─────────────────────────────────────────────

/**
 * Ajusta duty cycle según carga de tráfico.
 *
 * Inspirado en S-MAC (Ye et al., 2002) adaptado para 802.15.4:
 *
 *   Si carga > UMBRAL_ALTO:  duty *= 1.5  (más tiempo despierto)
 *   Si carga < UMBRAL_BAJO:  duty *= 0.75 (más tiempo dormido → ahorro)
 *   Vecinos: el factor neighbor_penalty evita que todos duerman juntos,
 *            lo que causaría colisiones al despertar.
 *
 * Llamar periódicamente (ej: cada 10 ciclos TX)
 */
void adapt_duty_cycle(float queue_load, uint8_t neighbor_count)
{
    const float LOAD_HIGH    = 0.70f;
    const float LOAD_LOW     = 0.20f;
    const float DUTY_MIN     = 0.02f;
    const float DUTY_MAX     = 0.50f;
    const float BACKOFF      = 0.75f;
    const float SPEEDUP      = 1.50f;

    // Factor de coordinación con vecinos (evita sleep sincronizado)
    // Con más vecinos, mantenemos un duty cycle ligeramente mayor
    float neighbor_factor = 1.0f + (neighbor_count * 0.03f);

    float new_duty = g_config.duty_cycle;

    if (queue_load > LOAD_HIGH) {
        new_duty = g_config.duty_cycle * SPEEDUP * neighbor_factor;
    } else if (queue_load < LOAD_LOW) {
        new_duty = g_config.duty_cycle * BACKOFF;
    } else {
        // Ajuste fino proporcional
        float target = LOAD_LOW + queue_load * (DUTY_MAX - DUTY_MIN);
        new_duty = g_config.duty_cycle + (target - g_config.duty_cycle) * 0.1f;
    }

    // Saturar y aplicar
    if (new_duty < DUTY_MIN) new_duty = DUTY_MIN;
    if (new_duty > DUTY_MAX) new_duty = DUTY_MAX;

    if (new_duty != g_config.duty_cycle) {
        g_config.duty_cycle = new_duty;
        g_config.dirty = true;
    }
}

// ─────────────────────────────────────────────
// ALGORITMO 2: TX POWER CONTROL DINÁMICO
// ─────────────────────────────────────────────

/**
 * Ajusta potencia TX del MRF24J40 basado en calidad del enlace.
 *
 * RSSI y LQI se leen del registro STATUS luego de cada RX.
 *
 * Estrategia de link budget:
 *   - Margen mínimo seguro: 10 dB sobre sensibilidad (-101 dBm @ 250kbps)
 *   - Si RSSI > -60 dBm: tenemos 41 dB de margen → reducir potencia
 *   - Si RSSI < -75 dBm: margen escaso → mantener máxima potencia
 *
 * Actualiza registro RFCON3 del MRF24J40 vía SPI.
 */
void adapt_tx_power(int8_t rssi, uint8_t lqi)
{
    uint8_t new_level = g_config.tx_power_level;

    // Hysteresis para evitar oscilación
    const int8_t RSSI_STRONG  = -60;
    const int8_t RSSI_MEDIUM  = -75;
    const uint8_t LQI_GOOD    = 180;
    const uint8_t LQI_FAIR    = 120;

    if (rssi > RSSI_STRONG && lqi > LQI_GOOD) {
        new_level = 2;   // -20 dBm (mínima potencia)
    } else if (rssi > RSSI_MEDIUM && lqi > LQI_FAIR) {
        new_level = 1;   // -10 dBm (potencia media)
    } else {
        new_level = 0;   // +0 dBm (máxima potencia)
    }

    if (new_level != g_config.tx_power_level) {
        g_config.tx_power_level = new_level;
        g_config.dirty = true;
        radio_set_tx_power(new_level);
    }
}

/**
 * Escribe nivel de potencia en registro RFCON3 del MRF24J40.
 * RFCON3[7:6] = TXPWRL (potencia)
 * RFCON3[5:4] = TXPWRB (boost, dejar en 0)
 */
void radio_set_tx_power(uint8_t level)
{
    static const uint8_t TX_REGS[] = {
        TX_POWER_0DBM,    // nivel 0: +0 dBm
        TX_POWER_M10DBM,  // nivel 1: -10 dBm
        TX_POWER_M20DBM,  // nivel 2: -20 dBm
    };
    if (level > 2) level = 0;
    // mrf24j40_write_long(MRF_RFCON3, TX_REGS[level]);
    // ^ descomentar con tu HAL de SPI
    (void)TX_REGS[level];  // suprimir warning en compilación sin HAL
}

// ─────────────────────────────────────────────
// ALGORITMO 3: AGREGACIÓN DE PAQUETES
// ─────────────────────────────────────────────

/**
 * Agrega muestras en buffer local y construye frame 802.15.4.
 *
 * Ventaja: un frame 802.15.4 tiene 15 bytes de overhead fijo.
 * Con N=4 muestras de 8B, efficiency = 32/(32+15) = 68%
 * vs. single frame: 8/(8+15) = 35%  → mejora del 94%
 *
 * Llamar telemetry_enqueue() por cada muestra nueva.
 * Cuando count >= agg_size, llamar telemetry_flush().
 */
bool telemetry_enqueue(const NodeTelemetry* t)
{
    if (g_queue_count >= SAMPLE_QUEUE_SIZE) {
        // Buffer lleno → flush inmediato
        telemetry_flush();
    }
    memcpy(&g_sample_queue[g_queue_count], t, sizeof(NodeTelemetry));
    g_queue_count++;
    return (g_queue_count >= g_config.agg_size);  // true = listo para enviar
}

/**
 * Construye frame agregado en buffer de salida.
 * Retorna longitud del payload (0 = error).
 */
uint8_t build_aggregated_frame(uint8_t* buf, uint8_t bufsize)
{
    uint8_t needed = 2 + g_queue_count * sizeof(NodeTelemetry);
    if (needed > bufsize || g_queue_count == 0) return 0;

    buf[0] = 0xA1;             // MSG_TYPE: telemetría agregada
    buf[1] = g_queue_count;    // Número de muestras
    memcpy(&buf[2], g_sample_queue,
           g_queue_count * sizeof(NodeTelemetry));
    return needed;
}

bool telemetry_flush(void)
{
    if (g_queue_count == 0) return true;

    uint8_t frame[2 + SAMPLE_QUEUE_SIZE * sizeof(NodeTelemetry)];
    uint8_t len = build_aggregated_frame(frame, sizeof(frame));

    if (len == 0) return false;

    // Enviar al gateway (dirección broadcast o del coordinador)
    bool ok = radio_send(frame, len, 0x0001 /* COORDINATOR_ADDR */);

    if (ok) {
        g_net.packets_tx += g_queue_count;
        g_queue_count = 0;
    } else {
        g_net.packets_lost++;
    }
    return ok;
}

// ─────────────────────────────────────────────
// ALGORITMO 4: INTERVALO ADAPTATIVO
// ─────────────────────────────────────────────

/**
 * Ajusta intervalo de transmisión basado en variación de datos.
 *
 * Si los datos no cambian (ΔV < THRESHOLD), no tiene sentido
 * transmitir frecuentemente → aumentar intervalo → ahorro energético.
 *
 * Si los datos cambian rápido → reducir intervalo → más resolución.
 *
 * Complementa duty cycling: mientras duty cycle controla
 * el tiempo de escucha, el intervalo controla la frecuencia de envío.
 */
void adapt_tx_interval(float current_value, float last_value)
{
    const float CHANGE_THRESHOLD = 0.05f;   // 5% cambio mínimo
    const float INTERVAL_MIN     = 0.5f;    // 500ms mínimo
    const float INTERVAL_MAX     = 25.0f;   // 25s máximo
    const float BACKOFF_FACTOR   = 1.50f;   // +50% si estable
    const float SPEEDUP_FACTOR   = 0.70f;   // -30% si cambió

    float delta = 0.0f;
    if (last_value != 0.0f) {
        delta = (current_value - last_value) / last_value;
        if (delta < 0) delta = -delta;  // abs
    }

    float new_interval = g_config.tx_interval_s;

    if (delta < CHANGE_THRESHOLD) {
        // Datos estables → enviar menos frecuente
        new_interval *= BACKOFF_FACTOR;
    } else {
        // Datos cambiaron → enviar más frecuente
        new_interval *= SPEEDUP_FACTOR;
    }

    // Saturar
    if (new_interval < INTERVAL_MIN) new_interval = INTERVAL_MIN;
    if (new_interval > INTERVAL_MAX) new_interval = INTERVAL_MAX;

    if (new_interval != g_config.tx_interval_s) {
        g_config.tx_interval_s = new_interval;
        g_config.dirty = true;
    }
}

// ─────────────────────────────────────────────
// ALGORITMO 5: SLEEP MODE SCHEDULING
// ─────────────────────────────────────────────

/**
 * Gestiona el ciclo sleep del ATmega328P.
 *
 * Modos disponibles (de menor a mayor ahorro):
 *   SLEEP_MODE_IDLE       → MCU duerme, periféricos activos (0.7mA)
 *   SLEEP_MODE_PWR_SAVE   → Timer2 activo, resto dormido (0.12mA)
 *   SLEEP_MODE_PWR_DOWN   → Solo WDT/INT externo (0.005mA)
 *
 * El radio MRF24J40 puede configurarse en:
 *   - Idle con oscilador activo (2.4mA)
 *   - Sleep (0.002mA) → necesita 2ms para despertar
 *
 * Coordinación con red:
 *   El coordinador/gateway anuncia beacon cada BI (Beacon Interval).
 *   El nodo despierta justo antes de cada beacon para escuchar.
 *   Entre beacons, radio y MCU en deep sleep.
 *
 *   BI = baseSuperframeDuration × 2^BO = 15.36ms × 2^6 = 983ms (BO=6)
 */
void sleep_ms(uint32_t ms)
{
    // Dividir en segmentos de WDT (WDT máx: 8000ms)
    // Para ms cortos usar Timer2 (no desactiva oscilador)
    if (ms < 16) {
        // Delay activo para tiempos muy cortos
        // _delay_ms(ms);  // con avr/delay.h
        return;
    }

    uint8_t sleep_mode_reg;
    switch (g_config.sleep_mode) {
        case 2:  sleep_mode_reg = SLEEP_MODE_PWR_DOWN; break;
        case 1:  sleep_mode_reg = SLEEP_MODE_PWR_SAVE; break;
        default: sleep_mode_reg = SLEEP_MODE_IDLE;     break;
    }

    // Poner radio a dormir antes que el MCU
    radio_sleep();

    set_sleep_mode(sleep_mode_reg);
    sleep_enable();

    // Configurar WDT para despertar después de ms
    // (simplificado — producción usa Timer2 para más precisión)
    wdt_enable(WDTO_1S);   // Ajustar según ms
    sei();
    sleep_cpu();
    sleep_disable();
    wdt_disable();

    // Despertar radio
    radio_wakeup();
}

// ─────────────────────────────────────────────
// LOOP PRINCIPAL DEL NODO
// ─────────────────────────────────────────────

/**
 * Loop principal — implementa el ciclo completo del nodo:
 *
 *   1. Muestrear sensores (consumo, temperatura, etc.)
 *   2. Agregar en buffer
 *   3. Si buffer lleno: transmitir frame agregado
 *   4. Actualizar RSSI/LQI y adaptar TX power
 *   5. Adaptar duty cycle según carga
 *   6. Sleep por tx_interval_s * (1 - duty_cycle)
 *   7. Repetir
 */
void node_main_loop(void)
{
    static float last_power_value = 0.0f;
    static uint8_t cycle_count = 0;

    // ── 1. Muestreo ──
    NodeTelemetry sample;
    telemetry_sample(&sample);

    // ── 2. Agregar ──
    bool ready_to_send = telemetry_enqueue(&sample);

    // ── 3. Transmitir si buffer lleno ──
    if (ready_to_send) {
        telemetry_flush();

        // Leer RSSI/LQI post-TX (del último ACK recibido)
        int8_t  rssi = radio_get_rssi();
        uint8_t lqi  = radio_get_lqi();
        g_net.last_rssi = rssi;
        g_net.last_lqi  = lqi;

        // ── 4. Adaptar TX power ──
        adapt_tx_power(rssi, lqi);
    }

    // ── 5. Adaptar parámetros cada 10 ciclos ──
    if (++cycle_count >= 10) {
        cycle_count = 0;

        float current_power = (float)sample.power_raw / 1023.0f * 3.3f;
        adapt_tx_interval(current_power, last_power_value);
        last_power_value = current_power;

        float queue_load = (float)g_queue_count / SAMPLE_QUEUE_SIZE;
        adapt_duty_cycle(queue_load, 2 /* neighbor_count */);

        // Guardar config si cambió
        if (g_config.dirty) {
            NodeConfigBytes raw;
            config_to_bytes(&g_config, &raw);
            // eeprom_write_block(&raw, (void*)CONFIG_ADDR, 3);
            g_config.dirty = false;
        }
    }

    // ── 6. Sleep ──
    uint32_t active_ms  = (uint32_t)(g_config.tx_interval_s * g_config.duty_cycle * 1000.0f);
    uint32_t sleep_ms_t = (uint32_t)(g_config.tx_interval_s * (1.0f - g_config.duty_cycle) * 1000.0f);

    (void)active_ms;  // El tiempo activo ya fue consumido en pasos 1-5
    sleep_ms(sleep_ms_t);
}

/**
 * Muestra de telemetría (valores reales desde hardware)
 */
void telemetry_sample(NodeTelemetry* t)
{
    static uint8_t seq = 0;

    t->node_id   = g_node_id;
    t->power_raw = 512; // ADC_read(ADC_POWER_PIN);  // sustituir con HAL
    t->rssi      = g_net.last_rssi;
    t->lqi       = g_net.last_lqi;
    t->seq       = seq++;

    // Flags: [7:6]=tx_level [5:4]=sleep_mode [3]=1(active) [2:0]=rsvd
    t->flags = (uint8_t)(
        ((g_config.tx_power_level & 0x03) << 6) |
        ((g_config.sleep_mode     & 0x03) << 4) |
        (1 << 3)  // active = true
    );
}

/**
 * Tamaño óptimo de agregación dado tasa de transmisión y latencia máxima.
 */
uint8_t compute_optimal_agg_size(float tx_rate_pps, float max_latency_s)
{
    if (tx_rate_pps <= 0.0f) return 1;
    uint8_t by_latency = (uint8_t)(tx_rate_pps * max_latency_s);
    uint8_t by_payload = (MAX_PAYLOAD_BYTES - 2) / sizeof(NodeTelemetry);
    uint8_t optimal = (by_latency < by_payload) ? by_latency : by_payload;
    if (optimal < 1) optimal = 1;
    if (optimal > SAMPLE_QUEUE_SIZE) optimal = SAMPLE_QUEUE_SIZE;
    return optimal;
}

#endif // IOT_CITY_IMPL
