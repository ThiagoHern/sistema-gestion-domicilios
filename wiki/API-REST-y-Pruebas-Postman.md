# Catálogo de Endpoints REST y Pruebas en Postman

Base URL: `http://localhost:8080/api`

Importa en Postman el archivo [`postman/Sistema_Domicilios_Cali.postman_collection.json`](../postman/Sistema_Domicilios_Cali.postman_collection.json) para ejecutar toda la batería de pruebas automatizadas.

| Método | Endpoint | Objeto SQL / Capa | Descripción |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/health` | `SELECT 1` + conteos | Verifica conexión activa con MySQL 8 |
| `GET` | `/api/catalogos` | Tablas maestras | Retorna barrios, clientes, direcciones, domiciliarios y aliados |
| `GET` | `/api/solicitudes` | `JOIN` + funciones SQL | Lista solicitudes (filtros opcionales `?estado=` y `?cliente=`) |
| `GET` | `/api/solicitudes/{id}` | `JOIN` + `Incidente` | Detalle completo de una solicitud con sus incidentes (`404` si no existe) |
| `POST` | `/api/solicitudes` | `sp_registrar_solicitud` | Crea solicitud validando RN-03 y RN-04 (`201` / `400`) |
| `PUT` | `/api/solicitudes/{id}/asignar` | `sp_asignar_domiciliario` | Asigna domiciliario activo con transacción ACID (`200` / `400`) |
| `PUT` | `/api/solicitudes/{id}/estado` | `sp_actualizar_estado_solicitud` | Avanza estado y dispara trigger de auditoría |
| `GET` | `/api/incidentes` | `Incidente` | Lista incidentes (filtro opcional `?solicitud=`) |
| `POST` | `/api/incidentes` | `trg_validar_incidente_fecha` + `trg_auditar_incidente` | Registra novedad operativa (`201` / `400`) |
| `GET` | `/api/auditoria` | `AuditoriaSistema` | Últimos 50 eventos auditados por triggers |
| `GET` | `/api/vistas` | Las 3 `VIEWS` | Consolida las 3 vistas analíticas |
| `GET` / `POST` | `/api/clientes` | `Usuario` + `Cliente` + `DireccionEntrega` | Gestión de clientes con soporte a herencia solapada (RN-01) |
| `GET` / `POST` | `/api/direcciones`, `/api/clientes/{id}/direcciones` | `DireccionEntrega` | Registro y consulta de direcciones (RN-02) |
| `GET` / `POST` | `/api/domiciliarios` | `Usuario` + `Domiciliario` | Registro y listado de domiciliarios |
| `PUT` | `/api/domiciliarios/{codigo}/estado` | `Domiciliario` | Cambia estado `activo` / `inactivo` |
| `GET` / `POST` | `/api/establecimientos` | `EstablecimientoAliado` | Gestión de comercios aliados |
| `GET` / `POST` | `/api/barrios` | `Barrio` | Gestión de barrios y comunas (1–22) |

## Pruebas Negativas Destacadas (Postman y Laboratorio Web)
1. **RN-03 Doble origen:** `POST /api/solicitudes` enviando `codigoEstablecimiento` y `ubicacionRecogidaExterna` a la vez → `400 Bad Request`.
2. **RN-04 Dirección ajena:** `POST /api/solicitudes` con cliente `1001` y dirección `3` (de `1002`) → `400 Bad Request`.
3. **RN-05 Domiciliario inactivo:** `PUT /api/solicitudes/506/asignar` con `{"codigoDomiciliario": 3}` → `400 Bad Request` (`RECHAZADO: El domiciliario se encuentra inactivo.`).
4. **Trigger de fecha:** `POST /api/incidentes` con `fechaHoraIncidente: "2020-01-01T08:00:00"` → `400 Bad Request` (`SQLSTATE 45000`).
5. **RN-06 Salto de estado:** `PUT /api/solicitudes/506/estado` con `{"estado": "finalizada"}` → `400 Bad Request`.
