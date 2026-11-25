# Objetos Procedimentales SQL (MySQL 8)

Todos los objetos se crean automáticamente al ejecutar `sql/01_BD_SistemaDomicilios_Final.sql`.

## 1. Funciones Almacenadas
* `fn_calcular_tarifa_entrega(p_comuna, p_montoTotal)` (`DETERMINISTIC NO SQL`): Calcula la tarifa base según la comuna de Cali (`$5.500`, `$6.500` o `$7.500` COP) y aplica 50% de descuento cuando el monto del pedido es `>= $80.000` COP.
* `fn_contar_incidentes_solicitud(p_numeroSolicitud)` (`NOT DETERMINISTIC READS SQL DATA`): Retorna el conteo de incidentes asociados a una solicitud.

## 2. Vistas Analíticas (VIEWS)
* `vw_solicitudes_activas_cali`: Consolida las solicitudes en estado `'creada'`, `'asignada'` o `'en curso'` con origen, destino, barrio, comuna, domiciliario, tarifa calculada y conteo de incidentes.
* `vw_resumen_domiciliarios`: Desempeño de cada repartidor (asignadas, finalizadas, monto total finalizado e incidentes).
* `vw_resumen_establecimientos`: Volumen de pedidos y facturación acumulada por cada establecimiento aliado.

## 3. Disparadores (TRIGGERS)
* `trg_validar_incidente_fecha` (`BEFORE INSERT ON Incidente`): Rechaza (`SQLSTATE '45000'`) cualquier incidente cuya fecha sea anterior a la creación de la solicitud.
* `trg_validar_domiciliario_activo_ins` (`BEFORE INSERT ON SolicitudDomicilio`): Protege RN-05 impidiendo insertar una solicitud asignada a un domiciliario inactivo.
* `trg_validar_domiciliario_activo_upd` (`BEFORE UPDATE ON SolicitudDomicilio`): Protege RN-05 impidiendo reasignar una solicitud a un domiciliario inactivo directamente por SQL.
* `trg_auditar_incidente` (`AFTER INSERT ON Incidente`): Registra automáticamente en `AuditoriaSistema` cada novedad operativa.
* `trg_auditar_cambio_estado_solicitud` (`AFTER UPDATE ON SolicitudDomicilio`): Registra en `AuditoriaSistema` toda transición de estado.

## 4. Procedimientos Almacenados Transaccionales (ACID)
* `sp_registrar_solicitud`: Valida propiedad de la dirección (RN-04), monto no negativo, exclusividad de origen (RN-03) y existencia de establecimiento o barrio dentro de una transacción `START TRANSACTION` / `COMMIT` / `ROLLBACK`.
* `sp_asignar_domiciliario`: Bloquea filas con `SELECT ... FOR UPDATE`, verifica que el domiciliario exista y esté `'activo'` y que la solicitud esté `'creada'`; de lo contrario ejecuta `ROLLBACK`.
* `sp_actualizar_estado_solicitud`: Controla las transiciones válidas (`asignada → en curso → finalizada`, o `cancelada` mientras no esté cerrada).
