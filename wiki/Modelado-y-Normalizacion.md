# Modelado y Normalización (MEER → MR → 3FN/BCNF)

## 1. Modelo Entidad-Relación Extendido (MEER)
* **Superclase `Usuario`:** Centraliza `numeroIdentificacion` (PK), `nombres`, `apellidoPaterno`, `apellidoMaterno`, `telefono` y `correoElectronico` (`UNIQUE`).
* **Especialización `{inclusiva / solapada}` hacia `Cliente` y `Domiciliario`:** Una misma persona puede actuar como cliente, como domiciliario o ambos sin duplicar datos personales (**RN-01**).
* **Entidad geográfica `Barrio`:** Modela la relación `barrio → comuna` para las 22 comunas de Santiago de Cali.
* **Exclusividad de origen (`SolicitudDomicilio`):** Toda solicitud parte exclusivamente de un `EstablecimientoAliado` **o** de una ubicación externa (`ubicacionRecogidaExterna`, `idBarrioRecogidaExterna`), nunca ambos ni ninguno (**RN-03**).

## 2. Reglas de Negocio Implementadas
| Código | Regla | Mecanismo en MySQL 8 |
| :--- | :--- | :--- |
| **RN-01** | Unicidad de Usuario y Roles solapados | PK `numeroIdentificacion` en `Usuario` + FKs en `Cliente` y `Domiciliario` |
| **RN-02** | Múltiples direcciones por cliente | Relación 1:N `Cliente → DireccionEntrega` (`FK NOT NULL`) |
| **RN-03** | Exclusividad del punto de recogida | `CONSTRAINT ck_lugar_recogida CHECK (...)` |
| **RN-04** | La dirección de entrega pertenece al cliente | `UNIQUE (idDireccion, numeroIdentificacionCliente)` + FK compuesta en `SolicitudDomicilio` |
| **RN-05** | Solo domiciliarios activos y fecha obligatoria | `ck_asignacion` + `trg_validar_domiciliario_activo_ins/upd` + `sp_asignar_domiciliario` |
| **RN-06** | Ciclo de vida y máquina de estados | `ENUM` + `ck_estado_domiciliario` + `sp_actualizar_estado_solicitud` |
| **RN-07** | Tipificación de incidentes | `ENUM` en `Incidente` + `FK NOT NULL` hacia `SolicitudDomicilio` |

## 3. Proceso de Normalización
* **1FN:** Se descompuso `nombreCompleto` en `nombres`, `apellidoPaterno` y `apellidoMaterno`; se eliminaron atributos multivaluados y duplicados.
* **2FN:** Todas las tablas utilizan clave primaria simple atómica (`numeroIdentificacion`, `idBarrio`, `idDireccion`, `codigoEstablecimiento`, `codigoDomiciliario`, `numeroSolicitud`, `codigoIncidente`, `idAuditoria`), impidiendo dependencias parciales.
* **3FN:** Se extrajo `Barrio(idBarrio, nombreBarrio, comuna)` para eliminar la dependencia transitiva `barrio → comuna`. En `SolicitudDomicilio`, `numeroIdentificacionCliente` se mantiene como desnormalización controlada protegida por la FK compuesta hacia `DireccionEntrega(idDireccion, numeroIdentificacionCliente)`.
* **BCNF / 4FN / 5FN:** Todo determinante es superclave (incluidas las claves candidatas de `Usuario` y `Domiciliario`) y no existen dependencias multivaluadas independientes ni de unión cíclica.
