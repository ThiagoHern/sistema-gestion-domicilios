-- =============================================================================
-- PROYECTO INTEGRADOR - BASES DE DATOS 1
-- Sistema de Gestión de Operaciones de Domicilios (Santiago de Cali)
-- Motor: MySQL 8.0+ (InnoDB / utf8mb4_unicode_ci)
-- Ejecutar completo en MySQL Workbench (Ctrl+Shift+Enter) o CLI mysql
-- =============================================================================

DROP DATABASE IF EXISTS Sistema_gestion_operaciones_domicilios;
CREATE DATABASE Sistema_gestion_operaciones_domicilios
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE Sistema_gestion_operaciones_domicilios;

-- =============================================================================
-- 1. DEFINICIÓN DE ESTRUCTURA (DDL - 9 TABLAS NORMALIZADAS 3FN/BCNF)
-- =============================================================================

CREATE TABLE Usuario (
    numeroIdentificacion VARCHAR(20)  PRIMARY KEY,
    nombres              VARCHAR(60)  NOT NULL,
    apellidoPaterno      VARCHAR(45)  NOT NULL,
    apellidoMaterno      VARCHAR(45)  NULL,
    telefono             VARCHAR(20)  NOT NULL,
    correoElectronico    VARCHAR(254) NOT NULL,
    CONSTRAINT uq_usuario_correo UNIQUE (correoElectronico)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Cliente (
    numeroIdentificacion VARCHAR(20) PRIMARY KEY,
    CONSTRAINT fk_cliente_usuario
        FOREIGN KEY (numeroIdentificacion)
        REFERENCES Usuario (numeroIdentificacion)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Domiciliario (
    codigoDomiciliario   INT PRIMARY KEY AUTO_INCREMENT,
    numeroIdentificacion VARCHAR(20) NOT NULL,
    medioTransporte      ENUM('bicicleta', 'motocicleta', 'automóvil') NOT NULL,
    estado               ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo',
    CONSTRAINT uq_domiciliario_usuario UNIQUE (numeroIdentificacion),
    CONSTRAINT fk_domiciliario_usuario
        FOREIGN KEY (numeroIdentificacion)
        REFERENCES Usuario (numeroIdentificacion)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Barrio (
    idBarrio     INT PRIMARY KEY AUTO_INCREMENT,
    nombreBarrio VARCHAR(100) NOT NULL,
    comuna       ENUM(
        '1','2','3','4','5','6','7','8','9','10','11',
        '12','13','14','15','16','17','18','19','20','21','22'
    ) NOT NULL,
    CONSTRAINT uq_barrio_comuna UNIQUE (nombreBarrio, comuna)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE DireccionEntrega (
    idDireccion                 INT PRIMARY KEY AUTO_INCREMENT,
    ubicacion                   VARCHAR(200) NOT NULL,
    idBarrio                    INT NOT NULL,
    referenciaAdicional         VARCHAR(200) NULL,
    numeroIdentificacionCliente VARCHAR(20)  NOT NULL,
    CONSTRAINT uq_direccion_cliente UNIQUE (idDireccion, numeroIdentificacionCliente),
    CONSTRAINT fk_direccion_barrio
        FOREIGN KEY (idBarrio)
        REFERENCES Barrio (idBarrio)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_direccion_cliente
        FOREIGN KEY (numeroIdentificacionCliente)
        REFERENCES Cliente (numeroIdentificacion)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE EstablecimientoAliado (
    codigoEstablecimiento INT PRIMARY KEY AUTO_INCREMENT,
    nombreComercial       VARCHAR(150) NOT NULL,
    tipoEstablecimiento   ENUM('restaurante', 'farmacia', 'supermercado', 'tienda especializada') NOT NULL,
    ubicacion             VARCHAR(200) NOT NULL,
    idBarrio              INT NOT NULL,
    telefono              VARCHAR(20)  NOT NULL,
    correoElectronico     VARCHAR(254) NULL,
    CONSTRAINT fk_establecimiento_barrio
        FOREIGN KEY (idBarrio)
        REFERENCES Barrio (idBarrio)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE SolicitudDomicilio (
    numeroSolicitud             INT PRIMARY KEY AUTO_INCREMENT,
    fechaHoraCreacion           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado                      ENUM('creada', 'asignada', 'en curso', 'finalizada', 'cancelada') NOT NULL DEFAULT 'creada',
    descripcionRecogida         VARCHAR(500) NOT NULL,
    metodoPago                  ENUM('efectivo', 'electrónico', 'ninguno') NOT NULL,
    montoTotal                  DECIMAL(10,2) NOT NULL,
    numeroIdentificacionCliente VARCHAR(20)  NOT NULL,
    idDireccion                 INT NOT NULL,
    codigoDomiciliario          INT NULL,
    fechaHoraAsignacion         DATETIME NULL,
    codigoEstablecimiento       INT NULL,
    ubicacionRecogidaExterna    VARCHAR(200) NULL,
    idBarrioRecogidaExterna     INT NULL,

    -- Restricción de dominio monetario
    CONSTRAINT ck_monto_no_negativo CHECK (montoTotal >= 0),

    -- RN-03: Exclusividad mutua del punto de recogida (establecimiento aliado O dirección externa)
    CONSTRAINT ck_lugar_recogida CHECK (
        (codigoEstablecimiento IS NOT NULL AND ubicacionRecogidaExterna IS NULL AND idBarrioRecogidaExterna IS NULL)
        OR
        (codigoEstablecimiento IS NULL AND ubicacionRecogidaExterna IS NOT NULL AND idBarrioRecogidaExterna IS NOT NULL)
    ),

    -- RN-05: Asignación atómica domiciliario + fechaHoraAsignacion
    CONSTRAINT ck_asignacion CHECK (
        (codigoDomiciliario IS NULL AND fechaHoraAsignacion IS NULL)
        OR
        (codigoDomiciliario IS NOT NULL AND fechaHoraAsignacion IS NOT NULL)
    ),

    -- RN-06: Coherencia del estado con la asignación
    CONSTRAINT ck_estado_domiciliario CHECK (
        (estado = 'creada' AND codigoDomiciliario IS NULL)
        OR
        (estado IN ('asignada', 'en curso', 'finalizada') AND codigoDomiciliario IS NOT NULL)
        OR
        (estado = 'cancelada')
    ),

    -- RN-04: FK compuesta que garantiza que la dirección pertenezca al cliente solicitante
    CONSTRAINT fk_solicitud_cliente_direccion
        FOREIGN KEY (idDireccion, numeroIdentificacionCliente)
        REFERENCES DireccionEntrega (idDireccion, numeroIdentificacionCliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_solicitud_domiciliario
        FOREIGN KEY (codigoDomiciliario)
        REFERENCES Domiciliario (codigoDomiciliario)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT fk_solicitud_establecimiento
        FOREIGN KEY (codigoEstablecimiento)
        REFERENCES EstablecimientoAliado (codigoEstablecimiento)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT fk_solicitud_barrio_externo
        FOREIGN KEY (idBarrioRecogidaExterna)
        REFERENCES Barrio (idBarrio)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Incidente (
    codigoIncidente    INT PRIMARY KEY AUTO_INCREMENT,
    tipoIncidente      ENUM('retraso', 'dirección incorrecta', 'cliente no responde', 'establecimiento no entrega') NOT NULL,
    descripcion        TEXT NOT NULL,
    fechaHoraIncidente DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    numeroSolicitud    INT NOT NULL,
    CONSTRAINT fk_incidente_solicitud
        FOREIGN KEY (numeroSolicitud)
        REFERENCES SolicitudDomicilio (numeroSolicitud)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE AuditoriaSistema (
    idAuditoria       INT PRIMARY KEY AUTO_INCREMENT,
    tablaAfectada     VARCHAR(60)  NOT NULL,
    accion            VARCHAR(30)  NOT NULL,
    registroId        INT          NOT NULL,
    detalle           TEXT         NOT NULL,
    fechaHoraRegistro DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuarioBD         VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Índices secundarios para optimización de consultas operativas
CREATE INDEX idx_solicitud_cliente   ON SolicitudDomicilio (numeroIdentificacionCliente);
CREATE INDEX idx_solicitud_estado    ON SolicitudDomicilio (estado);
CREATE INDEX idx_solicitud_fecha     ON SolicitudDomicilio (fechaHoraCreacion);
CREATE INDEX idx_incidente_solicitud ON Incidente (numeroSolicitud);
CREATE INDEX idx_domiciliario_estado ON Domiciliario (estado);

-- =============================================================================
-- 2. FUNCIONES ALMACENADAS (DECLARADAS ANTES DE LAS VISTAS)
-- =============================================================================

DELIMITER //

CREATE FUNCTION fn_calcular_tarifa_entrega(
    p_comuna VARCHAR(2),
    p_montoTotal DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_tarifaBase DECIMAL(10,2);

    IF p_comuna IN ('2', '3', '17', '19') THEN
        SET v_tarifaBase = 5500.00;
    ELSEIF p_comuna IN ('10', '11', '18', '22') THEN
        SET v_tarifaBase = 7500.00;
    ELSE
        SET v_tarifaBase = 6500.00;
    END IF;

    IF p_montoTotal >= 80000.00 THEN
        SET v_tarifaBase = ROUND(v_tarifaBase * 0.50, 2);
    END IF;

    RETURN v_tarifaBase;
END //

CREATE FUNCTION fn_contar_incidentes_solicitud(p_numeroSolicitud INT)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COUNT(*)
      INTO v_total
      FROM Incidente
     WHERE numeroSolicitud = p_numeroSolicitud;

    RETURN v_total;
END //

DELIMITER ;

-- =============================================================================
-- 3. VISTAS ANALÍTICAS (VIEWS)
-- =============================================================================

CREATE OR REPLACE VIEW vw_solicitudes_activas_cali AS
SELECT
    s.numeroSolicitud,
    s.fechaHoraCreacion,
    s.estado,
    s.descripcionRecogida,
    s.metodoPago,
    s.montoTotal,
    fn_calcular_tarifa_entrega(b_ent.comuna, s.montoTotal) AS tarifaDomicilio,
    fn_contar_incidentes_solicitud(s.numeroSolicitud) AS totalIncidentes,
    u_cli.numeroIdentificacion AS clienteIdentificacion,
    CONCAT(u_cli.nombres, ' ', u_cli.apellidoPaterno, IFNULL(CONCAT(' ', u_cli.apellidoMaterno), '')) AS clienteNombre,
    u_cli.telefono AS clienteTelefono,
    CASE
        WHEN s.codigoEstablecimiento IS NOT NULL THEN 'Establecimiento Aliado'
        ELSE 'Recogida Externa'
    END AS tipoOrigen,
    COALESCE(e.nombreComercial, s.ubicacionRecogidaExterna) AS puntoRecogida,
    COALESCE(b_est.nombreBarrio, b_ext.nombreBarrio) AS barrioRecogida,
    d_ent.ubicacion AS direccionDestino,
    b_ent.nombreBarrio AS barrioDestino,
    b_ent.comuna AS comunaDestino,
    d_dom.codigoDomiciliario,
    CONCAT(u_dom.nombres, ' ', u_dom.apellidoPaterno) AS domiciliarioNombre,
    d_dom.medioTransporte,
    s.fechaHoraAsignacion
FROM SolicitudDomicilio s
INNER JOIN Usuario u_cli          ON s.numeroIdentificacionCliente = u_cli.numeroIdentificacion
INNER JOIN DireccionEntrega d_ent ON s.idDireccion = d_ent.idDireccion
                                 AND s.numeroIdentificacionCliente = d_ent.numeroIdentificacionCliente
INNER JOIN Barrio b_ent           ON d_ent.idBarrio = b_ent.idBarrio
LEFT JOIN EstablecimientoAliado e ON s.codigoEstablecimiento = e.codigoEstablecimiento
LEFT JOIN Barrio b_est            ON e.idBarrio = b_est.idBarrio
LEFT JOIN Barrio b_ext            ON s.idBarrioRecogidaExterna = b_ext.idBarrio
LEFT JOIN Domiciliario d_dom      ON s.codigoDomiciliario = d_dom.codigoDomiciliario
LEFT JOIN Usuario u_dom           ON d_dom.numeroIdentificacion = u_dom.numeroIdentificacion
WHERE s.estado IN ('creada', 'asignada', 'en curso');

CREATE OR REPLACE VIEW vw_resumen_domiciliarios AS
SELECT
    d.codigoDomiciliario,
    CONCAT(u.nombres, ' ', u.apellidoPaterno, IFNULL(CONCAT(' ', u.apellidoMaterno), '')) AS nombreDomiciliario,
    d.medioTransporte,
    d.estado,
    COUNT(s.numeroSolicitud) AS totalSolicitudesAsignadas,
    SUM(CASE WHEN s.estado = 'finalizada' THEN 1 ELSE 0 END) AS solicitudesFinalizadas,
    COALESCE(SUM(CASE WHEN s.estado = 'finalizada' THEN s.montoTotal ELSE 0 END), 0.00) AS montoFinalizado,
    (
        SELECT COUNT(*)
        FROM Incidente i
        INNER JOIN SolicitudDomicilio s2 ON i.numeroSolicitud = s2.numeroSolicitud
        WHERE s2.codigoDomiciliario = d.codigoDomiciliario
    ) AS totalIncidentes
FROM Domiciliario d
INNER JOIN Usuario u ON d.numeroIdentificacion = u.numeroIdentificacion
LEFT JOIN SolicitudDomicilio s ON d.codigoDomiciliario = s.codigoDomiciliario
GROUP BY
    d.codigoDomiciliario,
    u.nombres,
    u.apellidoPaterno,
    u.apellidoMaterno,
    d.medioTransporte,
    d.estado;

CREATE OR REPLACE VIEW vw_resumen_establecimientos AS
SELECT
    e.codigoEstablecimiento,
    e.nombreComercial,
    e.tipoEstablecimiento,
    b.nombreBarrio,
    b.comuna,
    COUNT(s.numeroSolicitud) AS totalSolicitudes,
    COALESCE(SUM(CASE WHEN s.estado <> 'cancelada' THEN s.montoTotal ELSE 0 END), 0.00) AS montoFacturado
FROM EstablecimientoAliado e
INNER JOIN Barrio b ON e.idBarrio = b.idBarrio
LEFT JOIN SolicitudDomicilio s ON e.codigoEstablecimiento = s.codigoEstablecimiento
GROUP BY
    e.codigoEstablecimiento,
    e.nombreComercial,
    e.tipoEstablecimiento,
    b.nombreBarrio,
    b.comuna;

-- =============================================================================
-- 4. DISPARADORES DE VALIDACIÓN Y AUDITORÍA (TRIGGERS)
-- =============================================================================

DELIMITER //

CREATE TRIGGER trg_validar_incidente_fecha
BEFORE INSERT ON Incidente
FOR EACH ROW
BEGIN
    DECLARE v_fechaCreacion DATETIME;

    SELECT fechaHoraCreacion
      INTO v_fechaCreacion
      FROM SolicitudDomicilio
     WHERE numeroSolicitud = NEW.numeroSolicitud;

    IF NEW.fechaHoraIncidente < v_fechaCreacion THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR: La fecha del incidente no puede ser anterior a la creación de la solicitud.';
    END IF;
END //

CREATE TRIGGER trg_validar_domiciliario_activo_ins
BEFORE INSERT ON SolicitudDomicilio
FOR EACH ROW
BEGIN
    DECLARE v_estadoDom VARCHAR(10);

    IF NEW.codigoDomiciliario IS NOT NULL THEN
        SELECT estado
          INTO v_estadoDom
          FROM Domiciliario
         WHERE codigoDomiciliario = NEW.codigoDomiciliario;

        IF v_estadoDom <> 'activo' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'ERROR (RN-05): No se puede asignar una solicitud a un domiciliario inactivo.';
        END IF;
    END IF;
END //

CREATE TRIGGER trg_validar_domiciliario_activo_upd
BEFORE UPDATE ON SolicitudDomicilio
FOR EACH ROW
BEGIN
    DECLARE v_estadoDom VARCHAR(10);

    IF NEW.codigoDomiciliario IS NOT NULL
       AND (OLD.codigoDomiciliario IS NULL OR NEW.codigoDomiciliario <> OLD.codigoDomiciliario) THEN
        SELECT estado
          INTO v_estadoDom
          FROM Domiciliario
         WHERE codigoDomiciliario = NEW.codigoDomiciliario;

        IF v_estadoDom <> 'activo' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'ERROR (RN-05): No se puede asignar una solicitud a un domiciliario inactivo.';
        END IF;
    END IF;
END //

CREATE TRIGGER trg_auditar_incidente
AFTER INSERT ON Incidente
FOR EACH ROW
BEGIN
    INSERT INTO AuditoriaSistema (tablaAfectada, accion, registroId, detalle, usuarioBD)
    VALUES (
        'Incidente',
        'INSERT',
        NEW.codigoIncidente,
        CONCAT('Incidente [', NEW.tipoIncidente, '] en solicitud #', NEW.numeroSolicitud, ': ', NEW.descripcion),
        USER()
    );
END //

CREATE TRIGGER trg_auditar_cambio_estado_solicitud
AFTER UPDATE ON SolicitudDomicilio
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado THEN
        INSERT INTO AuditoriaSistema (tablaAfectada, accion, registroId, detalle, usuarioBD)
        VALUES (
            'SolicitudDomicilio',
            'UPDATE_ESTADO',
            NEW.numeroSolicitud,
            CONCAT(
                'Estado cambiado de "', OLD.estado, '" a "', NEW.estado, '"',
                IF(NEW.codigoDomiciliario IS NOT NULL,
                   CONCAT(' | Domiciliario #', NEW.codigoDomiciliario),
                   ' | Sin domiciliario')
            ),
            USER()
        );
    END IF;
END //

DELIMITER ;

-- =============================================================================
-- 5. PROCEDIMIENTOS ALMACENADOS TRANSACCIONALES (STORED PROCEDURES - ACID)
-- =============================================================================

DELIMITER //

CREATE PROCEDURE sp_asignar_domiciliario(
    IN  p_numeroSolicitud    INT,
    IN  p_codigoDomiciliario INT,
    OUT p_resultado          VARCHAR(150)
)
BEGIN
    DECLARE v_estadoDomiciliario VARCHAR(10) DEFAULT NULL;
    DECLARE v_estadoSolicitud    VARCHAR(20) DEFAULT NULL;
    DECLARE v_noEncontrado       TINYINT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_noEncontrado = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: Fallo transaccional al asignar el domiciliario.';
    END;

    START TRANSACTION;

    SELECT estado
      INTO v_estadoDomiciliario
      FROM Domiciliario
     WHERE codigoDomiciliario = p_codigoDomiciliario
       FOR UPDATE;

    SET v_noEncontrado = 0;

    SELECT estado
      INTO v_estadoSolicitud
      FROM SolicitudDomicilio
     WHERE numeroSolicitud = p_numeroSolicitud
       FOR UPDATE;

    IF v_estadoDomiciliario IS NULL THEN
        SET p_resultado = 'RECHAZADO: El domiciliario especificado no existe.';
        ROLLBACK;
    ELSEIF v_estadoDomiciliario <> 'activo' THEN
        SET p_resultado = 'RECHAZADO: El domiciliario se encuentra inactivo.';
        ROLLBACK;
    ELSEIF v_estadoSolicitud IS NULL THEN
        SET p_resultado = 'RECHAZADO: La solicitud especificada no existe.';
        ROLLBACK;
    ELSEIF v_estadoSolicitud <> 'creada' THEN
        SET p_resultado = CONCAT('RECHAZADO: La solicitud está en estado "', v_estadoSolicitud, '" y no puede asignarse.');
        ROLLBACK;
    ELSE
        UPDATE SolicitudDomicilio
           SET codigoDomiciliario  = p_codigoDomiciliario,
               fechaHoraAsignacion = NOW(),
               estado              = 'asignada'
         WHERE numeroSolicitud = p_numeroSolicitud;

        COMMIT;
        SET p_resultado = 'EXITOSO: Domiciliario asignado correctamente.';
    END IF;
END //

CREATE PROCEDURE sp_registrar_solicitud(
    IN  p_numeroIdentificacionCliente VARCHAR(20),
    IN  p_idDireccion                 INT,
    IN  p_descripcionRecogida         VARCHAR(500),
    IN  p_metodoPago                  ENUM('efectivo', 'electrónico', 'ninguno'),
    IN  p_montoTotal                  DECIMAL(10,2),
    IN  p_codigoEstablecimiento       INT,
    IN  p_ubicacionRecogidaExterna    VARCHAR(200),
    IN  p_idBarrioRecogidaExterna     INT,
    OUT p_numeroSolicitudGenerado     INT,
    OUT p_resultado                   VARCHAR(150)
)
BEGIN
    DECLARE v_dirValida    INT DEFAULT 0;
    DECLARE v_estValido    INT DEFAULT 0;
    DECLARE v_barrioValido INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_numeroSolicitudGenerado = NULL;
        SET p_resultado = 'ERROR: No se pudo registrar la solicitud (verifique restricciones de integridad).';
    END;

    START TRANSACTION;

    SELECT COUNT(*)
      INTO v_dirValida
      FROM DireccionEntrega
     WHERE idDireccion = p_idDireccion
       AND numeroIdentificacionCliente = p_numeroIdentificacionCliente;

    IF v_dirValida = 0 THEN
        SET p_numeroSolicitudGenerado = NULL;
        SET p_resultado = 'RECHAZADO: La dirección de entrega no pertenece al cliente indicado.';
        ROLLBACK;
    ELSEIF p_montoTotal IS NULL OR p_montoTotal < 0 THEN
        SET p_numeroSolicitudGenerado = NULL;
        SET p_resultado = 'RECHAZADO: El monto total no puede ser negativo.';
        ROLLBACK;
    ELSEIF NOT (
        (p_codigoEstablecimiento IS NOT NULL AND p_ubicacionRecogidaExterna IS NULL AND p_idBarrioRecogidaExterna IS NULL)
        OR
        (p_codigoEstablecimiento IS NULL AND p_ubicacionRecogidaExterna IS NOT NULL AND p_idBarrioRecogidaExterna IS NOT NULL)
    ) THEN
        SET p_numeroSolicitudGenerado = NULL;
        SET p_resultado = 'RECHAZADO: Debe indicar exclusivamente un establecimiento aliado O una dirección externa.';
        ROLLBACK;
    ELSE
        IF p_codigoEstablecimiento IS NOT NULL THEN
            SELECT COUNT(*)
              INTO v_estValido
              FROM EstablecimientoAliado
             WHERE codigoEstablecimiento = p_codigoEstablecimiento;

            IF v_estValido = 0 THEN
                SET p_numeroSolicitudGenerado = NULL;
                SET p_resultado = 'RECHAZADO: El establecimiento aliado especificado no existe.';
                ROLLBACK;
            ELSE
                INSERT INTO SolicitudDomicilio (
                    fechaHoraCreacion, estado, descripcionRecogida, metodoPago, montoTotal,
                    numeroIdentificacionCliente, idDireccion,
                    codigoDomiciliario, fechaHoraAsignacion,
                    codigoEstablecimiento, ubicacionRecogidaExterna, idBarrioRecogidaExterna
                ) VALUES (
                    NOW(), 'creada', p_descripcionRecogida, p_metodoPago, p_montoTotal,
                    p_numeroIdentificacionCliente, p_idDireccion,
                    NULL, NULL,
                    p_codigoEstablecimiento, NULL, NULL
                );

                SET p_numeroSolicitudGenerado = LAST_INSERT_ID();
                COMMIT;
                SET p_resultado = CONCAT('EXITOSO: Solicitud #', p_numeroSolicitudGenerado, ' creada correctamente.');
            END IF;
        ELSE
            SELECT COUNT(*)
              INTO v_barrioValido
              FROM Barrio
             WHERE idBarrio = p_idBarrioRecogidaExterna;

            IF v_barrioValido = 0 THEN
                SET p_numeroSolicitudGenerado = NULL;
                SET p_resultado = 'RECHAZADO: El barrio de recogida externa especificado no existe.';
                ROLLBACK;
            ELSE
                INSERT INTO SolicitudDomicilio (
                    fechaHoraCreacion, estado, descripcionRecogida, metodoPago, montoTotal,
                    numeroIdentificacionCliente, idDireccion,
                    codigoDomiciliario, fechaHoraAsignacion,
                    codigoEstablecimiento, ubicacionRecogidaExterna, idBarrioRecogidaExterna
                ) VALUES (
                    NOW(), 'creada', p_descripcionRecogida, p_metodoPago, p_montoTotal,
                    p_numeroIdentificacionCliente, p_idDireccion,
                    NULL, NULL,
                    NULL, p_ubicacionRecogidaExterna, p_idBarrioRecogidaExterna
                );

                SET p_numeroSolicitudGenerado = LAST_INSERT_ID();
                COMMIT;
                SET p_resultado = CONCAT('EXITOSO: Solicitud #', p_numeroSolicitudGenerado, ' creada correctamente.');
            END IF;
        END IF;
    END IF;
END //

CREATE PROCEDURE sp_actualizar_estado_solicitud(
    IN  p_numeroSolicitud INT,
    IN  p_nuevoEstado     ENUM('en curso', 'finalizada', 'cancelada'),
    OUT p_resultado       VARCHAR(150)
)
BEGIN
    DECLARE v_estadoActual VARCHAR(20) DEFAULT NULL;
    DECLARE v_noEncontrado TINYINT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_noEncontrado = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: Fallo transaccional al actualizar el estado.';
    END;

    START TRANSACTION;

    SELECT estado
      INTO v_estadoActual
      FROM SolicitudDomicilio
     WHERE numeroSolicitud = p_numeroSolicitud
       FOR UPDATE;

    IF v_estadoActual IS NULL THEN
        SET p_resultado = 'RECHAZADO: La solicitud no existe.';
        ROLLBACK;
    ELSEIF v_estadoActual IN ('finalizada', 'cancelada') THEN
        SET p_resultado = CONCAT('RECHAZADO: Una solicitud "', v_estadoActual, '" no puede cambiar de estado.');
        ROLLBACK;
    ELSEIF p_nuevoEstado = 'en curso' AND v_estadoActual <> 'asignada' THEN
        SET p_resultado = 'RECHAZADO: Solo una solicitud "asignada" puede pasar a "en curso".';
        ROLLBACK;
    ELSEIF p_nuevoEstado = 'finalizada' AND v_estadoActual <> 'en curso' THEN
        SET p_resultado = 'RECHAZADO: Solo una solicitud "en curso" puede pasar a "finalizada".';
        ROLLBACK;
    ELSE
        UPDATE SolicitudDomicilio
           SET estado = p_nuevoEstado
         WHERE numeroSolicitud = p_numeroSolicitud;

        COMMIT;
        SET p_resultado = CONCAT('EXITOSO: Solicitud #', p_numeroSolicitud, ' actualizada a "', p_nuevoEstado, '".');
    END IF;
END //

DELIMITER ;

-- =============================================================================
-- 6. CARGA DE DATOS DE PRUEBA EN CALI (DML)
-- =============================================================================

INSERT INTO Usuario
(numeroIdentificacion, nombres, apellidoPaterno, apellidoMaterno, telefono, correoElectronico)
VALUES
('1001', 'Santiago', 'Hernandez', 'Arroyave', '3001111111', 'santiago@example.com'),
('1002', 'Laura',    'Gomez',     'Lopez',    '3002222222', 'laura@example.com'),
('1003', 'Carlos',   'Perez',     'Rojas',    '3003333333', 'carlos@example.com'),
('1004', 'Maria',    'Torres',    'Diaz',     '3004444444', 'maria@example.com'),
('1005', 'Andres',   'Ramirez',   'Vargas',   '3005555555', 'andres@example.com'),
('1006', 'Julian',   'Castro',    'Mendoza',  '3006666666', 'julian@example.com');

INSERT INTO Cliente (numeroIdentificacion)
VALUES
('1001'),
('1002'),
('1003');

INSERT INTO Domiciliario
(codigoDomiciliario, numeroIdentificacion, medioTransporte, estado)
VALUES
(1, '1004', 'motocicleta', 'activo'),
(2, '1005', 'bicicleta',   'activo'),
(3, '1006', 'automóvil',   'inactivo');

INSERT INTO Barrio (idBarrio, nombreBarrio, comuna)
VALUES
(1,  'San Fernando',  '19'),
(2,  'El Ingenio',    '17'),
(3,  'Granada',       '2'),
(4,  'San Antonio',   '3'),
(5,  'Ciudad Jardin', '22'),
(6,  'Pance',         '22'),
(7,  'El Peñón',      '3'),
(8,  'Versalles',     '2'),
(9,  'Tequendama',    '19'),
(10, 'Limonar',       '17');

INSERT INTO DireccionEntrega
(idDireccion, ubicacion, idBarrio, referenciaAdicional, numeroIdentificacionCliente)
VALUES
(1, 'Calle 5 # 20-10',     1, 'Casa de dos pisos', '1001'),
(2, 'Carrera 80 # 13-50',  2, 'Apartamento 301',   '1001'),
(3, 'Avenida 9N # 15-20',  3, NULL,                '1002'),
(4, 'Calle 3 # 10-25',     4, 'Porton blanco',     '1002'),
(5, 'Carrera 100 # 15-60', 5, NULL,                '1003');

INSERT INTO EstablecimientoAliado
(codigoEstablecimiento, nombreComercial, tipoEstablecimiento, ubicacion, idBarrio, telefono, correoElectronico)
VALUES
(101, 'Restaurante El Buen Sabor',  'restaurante',          'Calle 9 # 25-30',     1, '6025550101', 'buensabor@example.com'),
(102, 'Farmacia Salud',             'farmacia',             'Carrera 80 # 12-40',  2, '6025550102', NULL),
(103, 'Supermercado Central',       'supermercado',         'Avenida 6N # 20-15',  3, '6025550103', 'central@example.com'),
(104, 'Tienda Especializada Norte', 'tienda especializada', 'Calle 4 # 8-20',      4, '6025550104', NULL),
(105, 'Restaurante La Esquina',     'restaurante',          'Carrera 100 # 16-10', 5, '6025550105', 'esquina@example.com');

INSERT INTO SolicitudDomicilio
(numeroSolicitud, fechaHoraCreacion, estado, descripcionRecogida, metodoPago, montoTotal,
 numeroIdentificacionCliente, idDireccion, codigoDomiciliario, fechaHoraAsignacion,
 codigoEstablecimiento, ubicacionRecogidaExterna, idBarrioRecogidaExterna)
VALUES
(501, '2026-10-17 09:00:00', 'creada',     'Pedido de alimentos',             'efectivo',    45000.00, '1001', 1, NULL, NULL,                  101,  NULL,                 NULL),
(502, '2026-10-17 09:30:00', 'asignada',   'Recoger medicamentos',            'electrónico', 32000.00, '1002', 3, 1,    '2026-10-17 09:35:00', 102,  NULL,                 NULL),
(503, '2026-10-17 10:00:00', 'en curso',   'Recoger compra de supermercado',  'electrónico', 85000.00, '1003', 5, 2,    '2026-10-17 10:05:00', NULL, 'Calle 15 # 30-40',   1),
(504, '2026-10-17 10:30:00', 'cancelada',  'Recoger producto especializado',  'ninguno',         0.00, '1001', 2, NULL, NULL,                  NULL, 'Carrera 50 # 12-15', 2),
(505, '2026-10-17 11:00:00', 'finalizada', 'Entrega de alimentos preparados', 'efectivo',    27000.00, '1002', 4, 1,    '2026-10-17 11:05:00', 105,  NULL,                 NULL),
(506, '2026-10-17 11:30:00', 'creada',     'Compra mercado semanal',          'electrónico', 92000.00, '1003', 5, NULL, NULL,                  103,  NULL,                 NULL);

INSERT INTO Incidente
(codigoIncidente, tipoIncidente, descripcion, fechaHoraIncidente, numeroSolicitud)
VALUES
(1, 'retraso',                    'El pedido se retraso por trafico.',            '2026-10-17 10:15:00', 503),
(2, 'dirección incorrecta',       'Se tuvo que confirmar la ubicacion.',          '2026-10-17 10:20:00', 503),
(3, 'cliente no responde',        'No se obtuvo respuesta al contactar cliente.', '2026-10-17 11:10:00', 505),
(4, 'establecimiento no entrega', 'El pedido no estaba listo.',                   '2026-10-17 09:40:00', 502),
(5, 'retraso',                    'La entrega tardo mas de lo esperado.',         '2026-10-17 11:20:00', 505);
