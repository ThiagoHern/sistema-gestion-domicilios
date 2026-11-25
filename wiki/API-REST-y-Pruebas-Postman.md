# Catálogo de Endpoints REST y Pruebas en Postman

Base URL: `http://localhost:8080/api` (o la URL pública del puerto 8080 en Codespaces).

| Método | Endpoint | Objeto SQL que ejecuta | Uso |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/solicitudes` | `JOIN` + `fn_calcular_tarifa_entrega` + `fn_contar_incidentes_solicitud` | Listar solicitudes con tarifa e incidentes |
| `POST` | `/api/solicitudes` | `sp_registrar_solicitud` | Crear solicitud validando RN-03 y RN-04 |
| `PUT` | `/api/solicitudes/{id}/asignar` | `sp_asignar_domiciliario` | Asignar domiciliario activo (transacción ACID) |
| `PUT` | `/api/solicitudes/{id}/estado` | `sp_actualizar_estado_solicitud` | Cambiar estado y disparar trigger de auditoría |
| `POST` | `/api/incidentes` | `trg_validar_incidente_fecha` + `trg_auditar_incidente` | Registrar novedad operativa |
| `GET` | `/api/vistas` | `vw_solicitudes_activas_cali`, `vw_resumen_domiciliarios`, `vw_resumen_establecimientos` | Reportes analíticos |
| `GET` | `/api/auditoria` | `AuditoriaSistema` | Consultar trazabilidad generada por triggers |

## Casos de prueba rápidos para Postman

### 1. Crear solicitud válida (201 Created)
`POST /api/solicitudes`
```json
{
  "numeroIdentificacionCliente": "1001",
  "idDireccion": 1,
  "descripcionRecogida": "Almuerzo ejecutivo",
  "metodoPago": "efectivo",
  "montoTotal": 38000,
  "codigoEstablecimiento": 101,
  "ubicacionRecogidaExterna": null,
  "idBarrioRecogidaExterna": null
}
```

### 2. Prueba negativa: asignar domiciliario inactivo (400 Bad Request)
`PUT /api/solicitudes/501/asignar`
```json
{
  "codigoDomiciliario": 3
}
```
**Respuesta esperada:** `RECHAZADO: El domiciliario se encuentra inactivo.`

### 3. Prueba negativa: dirección ajena al cliente (400 Bad Request)
`POST /api/solicitudes`
```json
{
  "numeroIdentificacionCliente": "1001",
  "idDireccion": 3,
  "descripcionRecogida": "Prueba direccion ajena",
  "metodoPago": "efectivo",
  "montoTotal": 20000,
  "codigoEstablecimiento": 101
}
```
**Respuesta esperada:** `RECHAZADO: La dirección de entrega no pertenece al cliente indicado.`
