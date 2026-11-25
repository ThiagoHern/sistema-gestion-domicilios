-- =============================================================================
-- SCRIPT DE CONSULTAS SQL, OBJETOS PROCEDIMENTALES Y PRUEBAS DE INTEGRIDAD
-- Proyecto Integrador - Bases de Datos 1 (UAO)
-- Ejecutar después de 01_BD_SistemaDomicilios_Final.sql en MySQL Workbench
-- =============================================================================

USE Sistema_gestion_operaciones_domicilios;

-- =============================================================================
-- 1. CONSULTAS BÁSICAS Y FILTROS SIMPLES (ENTREGA 2)
-- =============================================================================

SELECT * FROM Usuario;
SELECT * FROM Barrio;
SELECT * FROM EstablecimientoAliado;
SELECT * FROM SolicitudDomicilio;

SELECT * FROM SolicitudDomicilio WHERE numeroSolicitud = 503;
SELECT * FROM SolicitudDomicilio WHERE estado <> 'cancelada';
SELECT * FROM SolicitudDomicilio WHERE montoTotal > 30000;
SELECT * FROM SolicitudDomicilio WHERE montoTotal < 30000;
SELECT * FROM Domiciliario WHERE estado = 'activo';

SELECT nombreComercial, ubicacion
FROM EstablecimientoAliado
WHERE tipoEstablecimiento = 'restaurante';

-- =============================================================================
-- 2. OPERADORES LÓGICOS Y RANGOS
-- =============================================================================

SELECT * FROM SolicitudDomicilio
WHERE metodoPago = 'efectivo' AND montoTotal > 30000;

SELECT * FROM SolicitudDomicilio
WHERE estado = 'creada' OR estado = 'asignada';

SELECT * FROM SolicitudDomicilio
WHERE montoTotal BETWEEN 30000 AND 50000;

SELECT * FROM SolicitudDomicilio
WHERE estado IN ('en curso', 'finalizada');

SELECT * FROM SolicitudDomicilio
WHERE (estado = 'finalizada' OR estado = 'en curso')
  AND metodoPago = 'electrónico';

-- =============================================================================
-- 3. CONSULTAS MULTITABLA (INNER JOIN Y LEFT JOIN)
-- =============================================================================

-- Clientes con sus datos personales de Usuario
SELECT u.numeroIdentificacion, u.nombres, u.apellidoPaterno, u.telefono
FROM Cliente c
INNER JOIN Usuario u ON c.numeroIdentificacion = u.numeroIdentificacion;

-- Domiciliarios con su transporte y estado
SELECT d.codigoDomiciliario, u.nombres, u.apellidoPaterno, d.medioTransporte, d.estado
FROM Domiciliario d
INNER JOIN Usuario u ON d.numeroIdentificacion = u.numeroIdentificacion;

-- Direcciones de entrega por cliente con barrio y comuna
SELECT d.idDireccion, u.nombres AS cliente, d.ubicacion, b.nombreBarrio, b.comuna
FROM DireccionEntrega d
INNER JOIN Cliente c ON d.numeroIdentificacionCliente = c.numeroIdentificacion
INNER JOIN Usuario u ON c.numeroIdentificacion = u.numeroIdentificacion
INNER JOIN Barrio b ON d.idBarrio = b.idBarrio;

-- Establecimientos aliados con barrio y comuna
SELECT e.nombreComercial, e.tipoEstablecimiento, b.nombreBarrio, b.comuna
FROM EstablecimientoAliado e
INNER JOIN Barrio b ON e.idBarrio = b.idBarrio;

-- Solicitudes cuyo origen es un establecimiento aliado
SELECT s.numeroSolicitud, e.nombreComercial
FROM SolicitudDomicilio s
INNER JOIN EstablecimientoAliado e ON s.codigoEstablecimiento = e.codigoEstablecimiento;

-- Solicitudes con recogida externa y su barrio
SELECT s.numeroSolicitud, s.ubicacionRecogidaExterna, b.nombreBarrio, b.comuna
FROM SolicitudDomicilio s
INNER JOIN Barrio b ON s.idBarrioRecogidaExterna = b.idBarrio;

-- Incidentes detallados con solicitud y cliente
SELECT i.codigoIncidente, i.tipoIncidente, i.fechaHoraIncidente,
       s.numeroSolicitud, u.nombres AS cliente
FROM Incidente i
INNER JOIN SolicitudDomicilio s ON i.numeroSolicitud = s.numeroSolicitud
INNER JOIN Usuario u ON s.numeroIdentificacionCliente = u.numeroIdentificacion;

-- Todas las solicitudes incluyendo el domiciliario si está asignado (LEFT JOIN)
SELECT s.numeroSolicitud, s.estado,
       COALESCE(CONCAT(u.nombres, ' ', u.apellidoPaterno), 'Sin asignar') AS domiciliario
FROM SolicitudDomicilio s
LEFT JOIN Domiciliario d ON s.codigoDomiciliario = d.codigoDomiciliario
LEFT JOIN Usuario u ON d.numeroIdentificacion = u.numeroIdentificacion;

-- =============================================================================
-- 4. SUBCONSULTAS, AGREGACIÓN (GROUP BY / HAVING), ORDENAMIENTO Y BÚSQUEDA
-- =============================================================================

-- Usuarios que han realizado al menos una solicitud
SELECT nombres, apellidoPaterno
FROM Usuario
WHERE numeroIdentificacion IN (SELECT numeroIdentificacionCliente FROM SolicitudDomicilio);

-- Solicitud de mayor monto
SELECT * FROM SolicitudDomicilio
WHERE montoTotal = (SELECT MAX(montoTotal) FROM SolicitudDomicilio);

-- Solicitudes con monto superior al promedio general
SELECT numeroSolicitud, montoTotal
FROM SolicitudDomicilio
WHERE montoTotal > (SELECT AVG(montoTotal) FROM SolicitudDomicilio);

-- Domiciliarios que tuvieron incidentes en alguna solicitud asignada
SELECT d.codigoDomiciliario, d.medioTransporte
FROM Domiciliario d
WHERE d.codigoDomiciliario IN (
    SELECT s.codigoDomiciliario
    FROM SolicitudDomicilio s
    INNER JOIN Incidente i ON i.numeroSolicitud = s.numeroSolicitud
    WHERE s.codigoDomiciliario IS NOT NULL
);

-- Cantidad de solicitudes por cada estado
SELECT estado, COUNT(*) AS totalSolicitudes
FROM SolicitudDomicilio
GROUP BY estado;

-- Total gastado por cliente (HAVING > 30.000 COP)
SELECT u.nombres, u.apellidoPaterno, SUM(s.montoTotal) AS totalGastado
FROM SolicitudDomicilio s
INNER JOIN Usuario u ON s.numeroIdentificacionCliente = u.numeroIdentificacion
GROUP BY u.numeroIdentificacion, u.nombres, u.apellidoPaterno
HAVING SUM(s.montoTotal) > 30000;

-- Las 3 solicitudes de mayor valor registradas
SELECT numeroSolicitud, montoTotal, fechaHoraCreacion
FROM SolicitudDomicilio
ORDER BY montoTotal DESC
LIMIT 3;

-- Búsqueda por patrón LIKE
SELECT * FROM EstablecimientoAliado
WHERE nombreComercial LIKE '%Restaurante%' OR nombreComercial LIKE '%Central%';

-- =============================================================================
-- 5. CONSULTAS A VISTAS Y FUNCIONES PROCEDIMENTALES (ENTREGA 3)
-- =============================================================================

SELECT * FROM vw_solicitudes_activas_cali;
SELECT * FROM vw_resumen_domiciliarios;
SELECT * FROM vw_resumen_establecimientos;

-- Uso directo de las funciones almacenadas
SELECT s.numeroSolicitud,
       b.comuna,
       s.montoTotal,
       fn_calcular_tarifa_entrega(b.comuna, s.montoTotal) AS tarifaCalculada,
       fn_contar_incidentes_solicitud(s.numeroSolicitud) AS totalIncidentes
FROM SolicitudDomicilio s
INNER JOIN DireccionEntrega d ON s.idDireccion = d.idDireccion
INNER JOIN Barrio b ON d.idBarrio = b.idBarrio;

-- =============================================================================
-- 6. VERIFICACIÓN DE OBJETOS PROCEDIMENTALES Y AUDITORÍA
-- =============================================================================

SHOW FULL TABLES WHERE Table_type = 'VIEW';
SHOW FUNCTION STATUS WHERE Db = 'Sistema_gestion_operaciones_domicilios';
SHOW PROCEDURE STATUS WHERE Db = 'Sistema_gestion_operaciones_domicilios';
SHOW TRIGGERS FROM Sistema_gestion_operaciones_domicilios;

SELECT * FROM AuditoriaSistema ORDER BY idAuditoria DESC;

-- =============================================================================
-- 7. CASOS DE PRUEBA NEGATIVOS DE INTEGRIDAD (DESCOMENTAR UNO POR UNO)
-- =============================================================================

-- [CP-01] PK duplicada en Usuario -> Esperado: Error 1062 (Duplicate entry)
-- INSERT INTO Usuario VALUES ('1001', 'Duplicado', 'Test', NULL, '3000000000', 'dup@example.com');

-- [CP-02] RN-04 FK Compuesta: dirección 3 pertenece a cliente 1002, no a 1001 -> Esperado: Error 1452
-- INSERT INTO SolicitudDomicilio (fechaHoraCreacion, estado, descripcionRecogida, metodoPago, montoTotal,
--     numeroIdentificacionCliente, idDireccion, codigoEstablecimiento)
-- VALUES (NOW(), 'creada', 'Prueba direccion ajena', 'efectivo', 20000, '1001', 3, 101);

-- [CP-03] RN-03 Recogida doble (aliado Y dirección externa) -> Esperado: Error 3819 (ck_lugar_recogida)
-- INSERT INTO SolicitudDomicilio (fechaHoraCreacion, estado, descripcionRecogida, metodoPago, montoTotal,
--     numeroIdentificacionCliente, idDireccion, codigoEstablecimiento, ubicacionRecogidaExterna, idBarrioRecogidaExterna)
-- VALUES (NOW(), 'creada', 'Prueba doble origen', 'efectivo', 20000, '1001', 1, 101, 'Calle 10 # 10-10', 1);

-- [CP-04] RN-03 Recogida nula (ni aliado NI externa) -> Esperado: Error 3819 (ck_lugar_recogida)
-- INSERT INTO SolicitudDomicilio (fechaHoraCreacion, estado, descripcionRecogida, metodoPago, montoTotal,
--     numeroIdentificacionCliente, idDireccion)
-- VALUES (NOW(), 'creada', 'Prueba sin origen', 'efectivo', 20000, '1001', 1);

-- [CP-05] RN-06 Estado 'creada' con domiciliario asignado -> Esperado: Error 3819 (ck_estado_domiciliario)
-- INSERT INTO SolicitudDomicilio (fechaHoraCreacion, estado, descripcionRecogida, metodoPago, montoTotal,
--     numeroIdentificacionCliente, idDireccion, codigoDomiciliario, fechaHoraAsignacion, codigoEstablecimiento)
-- VALUES (NOW(), 'creada', 'Estado inconsistente', 'efectivo', 20000, '1001', 1, 1, NOW(), 101);

-- [CP-06] RN-05 Asignar solicitud 501 a domiciliario inactivo (#3 Julian Castro) -> Esperado: RECHAZADO + ROLLBACK
-- CALL sp_asignar_domiciliario(501, 3, @res_inactivo);
-- SELECT @res_inactivo AS Resultado_CP06;

-- [CP-07] Dominio ENUM comuna fuera de 1..22 -> Esperado: Error 1265 (Data truncated)
-- INSERT INTO Barrio (nombreBarrio, comuna) VALUES ('Barrio Invalido', '25');

-- [CP-08] Trigger trg_validar_incidente_fecha: fecha anterior a creación -> Esperado: Error 1644 (SQLSTATE 45000)
-- INSERT INTO Incidente (tipoIncidente, descripcion, fechaHoraIncidente, numeroSolicitud)
-- VALUES ('retraso', 'Fecha imposible', '2020-01-01 08:00:00', 501);
