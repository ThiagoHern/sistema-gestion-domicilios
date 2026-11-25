package com.uao.domicilios;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Types;
import java.util.*;

@Service
public class DomiciliosService {

    private final JdbcTemplate jdbc;

    public DomiciliosService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Map<String, Object> verificarSalud() {
        Integer ping = jdbc.queryForObject("SELECT 1", Integer.class);
        Map<String, Object> resumen = new LinkedHashMap<>();
        resumen.put("ok", ping != null && ping == 1);
        resumen.put("servicio", "Sistema de Gestión de Operaciones de Domicilios - Cali");
        resumen.put("baseDatos", "Sistema_gestion_operaciones_domicilios");
        resumen.put("solicitudes", jdbc.queryForObject("SELECT COUNT(*) FROM SolicitudDomicilio", Integer.class));
        resumen.put("clientes", jdbc.queryForObject("SELECT COUNT(*) FROM Cliente", Integer.class));
        resumen.put("domiciliarios", jdbc.queryForObject("SELECT COUNT(*) FROM Domiciliario", Integer.class));
        resumen.put("incidentes", jdbc.queryForObject("SELECT COUNT(*) FROM Incidente", Integer.class));
        resumen.put("auditoria", jdbc.queryForObject("SELECT COUNT(*) FROM AuditoriaSistema", Integer.class));
        return resumen;
    }

    public Map<String, Object> obtenerCatalogos() {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("barrios", listarBarrios());
        data.put("clientes", listarClientes());
        data.put("direcciones", jdbc.queryForList(
            "SELECT d.idDireccion, d.ubicacion, d.referenciaAdicional, d.numeroIdentificacionCliente, " +
            "b.idBarrio, b.nombreBarrio, b.comuna " +
            "FROM DireccionEntrega d INNER JOIN Barrio b ON d.idBarrio = b.idBarrio " +
            "ORDER BY d.idDireccion"
        ));
        data.put("domiciliarios", listarDomiciliarios());
        data.put("establecimientos", listarEstablecimientos());
        return data;
    }

    public List<Map<String, Object>> listarBarrios() {
        return jdbc.queryForList(
            "SELECT idBarrio, nombreBarrio, comuna FROM Barrio ORDER BY nombreBarrio"
        );
    }

    public void crearBarrio(Map<String, Object> body) {
        jdbc.update(
            "INSERT INTO Barrio (nombreBarrio, comuna) VALUES (?, ?)",
            requireStr(body.get("nombreBarrio"), "nombreBarrio"),
            requireStr(body.get("comuna"), "comuna")
        );
    }

    public List<Map<String, Object>> listarClientes() {
        return jdbc.queryForList(
            "SELECT u.numeroIdentificacion, u.nombres, u.apellidoPaterno, u.apellidoMaterno, " +
            "u.telefono, u.correoElectronico, " +
            "(SELECT COUNT(*) FROM DireccionEntrega d WHERE d.numeroIdentificacionCliente = c.numeroIdentificacion) AS totalDirecciones " +
            "FROM Cliente c INNER JOIN Usuario u ON c.numeroIdentificacion = u.numeroIdentificacion " +
            "ORDER BY u.nombres, u.apellidoPaterno"
        );
    }

    public List<Map<String, Object>> listarDireccionesCliente(String numeroIdentificacion) {
        return jdbc.queryForList(
            "SELECT d.idDireccion, d.ubicacion, d.referenciaAdicional, d.numeroIdentificacionCliente, " +
            "b.idBarrio, b.nombreBarrio, b.comuna " +
            "FROM DireccionEntrega d INNER JOIN Barrio b ON d.idBarrio = b.idBarrio " +
            "WHERE d.numeroIdentificacionCliente = ? ORDER BY d.idDireccion",
            numeroIdentificacion
        );
    }

    public List<Map<String, Object>> listarDomiciliarios() {
        return jdbc.queryForList(
            "SELECT d.codigoDomiciliario, d.numeroIdentificacion, " +
            "CONCAT(u.nombres, ' ', u.apellidoPaterno, IFNULL(CONCAT(' ', u.apellidoMaterno), '')) AS nombreCompleto, " +
            "u.telefono, u.correoElectronico, d.medioTransporte, d.estado " +
            "FROM Domiciliario d INNER JOIN Usuario u ON d.numeroIdentificacion = u.numeroIdentificacion " +
            "ORDER BY d.codigoDomiciliario"
        );
    }

    public List<Map<String, Object>> listarEstablecimientos() {
        return jdbc.queryForList(
            "SELECT e.codigoEstablecimiento, e.nombreComercial, e.tipoEstablecimiento, " +
            "e.ubicacion, e.idBarrio, b.nombreBarrio, b.comuna, e.telefono, e.correoElectronico " +
            "FROM EstablecimientoAliado e INNER JOIN Barrio b ON e.idBarrio = b.idBarrio " +
            "ORDER BY e.codigoEstablecimiento"
        );
    }

    public List<Map<String, Object>> listarSolicitudes(String estado, String cliente) {
        StringBuilder sql = new StringBuilder(
            "SELECT s.numeroSolicitud, s.fechaHoraCreacion, s.estado, s.descripcionRecogida, " +
            "s.metodoPago, s.montoTotal, s.numeroIdentificacionCliente, s.idDireccion, " +
            "CONCAT(u.nombres, ' ', u.apellidoPaterno) AS clienteNombre, " +
            "COALESCE(e.nombreComercial, s.ubicacionRecogidaExterna) AS puntoRecogida, " +
            "CASE WHEN s.codigoEstablecimiento IS NOT NULL THEN 'Aliado' ELSE 'Externa' END AS tipoOrigen, " +
            "d.ubicacion AS direccionEntrega, b.nombreBarrio, b.comuna, " +
            "s.codigoDomiciliario, CONCAT(ud.nombres, ' ', ud.apellidoPaterno) AS domiciliarioNombre, " +
            "s.fechaHoraAsignacion, " +
            "fn_calcular_tarifa_entrega(b.comuna, s.montoTotal) AS tarifaDomicilio, " +
            "fn_contar_incidentes_solicitud(s.numeroSolicitud) AS totalIncidentes " +
            "FROM SolicitudDomicilio s " +
            "INNER JOIN Usuario u ON s.numeroIdentificacionCliente = u.numeroIdentificacion " +
            "INNER JOIN DireccionEntrega d ON s.idDireccion = d.idDireccion AND s.numeroIdentificacionCliente = d.numeroIdentificacionCliente " +
            "INNER JOIN Barrio b ON d.idBarrio = b.idBarrio " +
            "LEFT JOIN EstablecimientoAliado e ON s.codigoEstablecimiento = e.codigoEstablecimiento " +
            "LEFT JOIN Domiciliario dom ON s.codigoDomiciliario = dom.codigoDomiciliario " +
            "LEFT JOIN Usuario ud ON dom.numeroIdentificacion = ud.numeroIdentificacion " +
            "WHERE 1=1 "
        );
        List<Object> params = new ArrayList<>();
        if (estado != null && !estado.isBlank()) {
            sql.append("AND s.estado = ? ");
            params.add(estado.trim());
        }
        if (cliente != null && !cliente.isBlank()) {
            sql.append("AND s.numeroIdentificacionCliente = ? ");
            params.add(cliente.trim());
        }
        sql.append("ORDER BY s.numeroSolicitud DESC");
        return jdbc.queryForList(sql.toString(), params.toArray());
    }

    public Map<String, Object> obtenerSolicitudPorId(int numeroSolicitud) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT s.numeroSolicitud, s.fechaHoraCreacion, s.estado, s.descripcionRecogida, " +
            "s.metodoPago, s.montoTotal, s.numeroIdentificacionCliente, s.idDireccion, " +
            "CONCAT(u.nombres, ' ', u.apellidoPaterno, IFNULL(CONCAT(' ', u.apellidoMaterno), '')) AS clienteNombre, " +
            "u.telefono AS clienteTelefono, " +
            "s.codigoEstablecimiento, e.nombreComercial AS establecimientoNombre, " +
            "s.ubicacionRecogidaExterna, s.idBarrioRecogidaExterna, bext.nombreBarrio AS barrioRecogidaExterna, " +
            "COALESCE(e.nombreComercial, s.ubicacionRecogidaExterna) AS puntoRecogida, " +
            "CASE WHEN s.codigoEstablecimiento IS NOT NULL THEN 'Aliado' ELSE 'Externa' END AS tipoOrigen, " +
            "d.ubicacion AS direccionEntrega, d.referenciaAdicional, b.nombreBarrio, b.comuna, " +
            "s.codigoDomiciliario, CONCAT(ud.nombres, ' ', ud.apellidoPaterno) AS domiciliarioNombre, " +
            "dom.medioTransporte, s.fechaHoraAsignacion, " +
            "fn_calcular_tarifa_entrega(b.comuna, s.montoTotal) AS tarifaDomicilio, " +
            "fn_contar_incidentes_solicitud(s.numeroSolicitud) AS totalIncidentes " +
            "FROM SolicitudDomicilio s " +
            "INNER JOIN Usuario u ON s.numeroIdentificacionCliente = u.numeroIdentificacion " +
            "INNER JOIN DireccionEntrega d ON s.idDireccion = d.idDireccion AND s.numeroIdentificacionCliente = d.numeroIdentificacionCliente " +
            "INNER JOIN Barrio b ON d.idBarrio = b.idBarrio " +
            "LEFT JOIN EstablecimientoAliado e ON s.codigoEstablecimiento = e.codigoEstablecimiento " +
            "LEFT JOIN Barrio bext ON s.idBarrioRecogidaExterna = bext.idBarrio " +
            "LEFT JOIN Domiciliario dom ON s.codigoDomiciliario = dom.codigoDomiciliario " +
            "LEFT JOIN Usuario ud ON dom.numeroIdentificacion = ud.numeroIdentificacion " +
            "WHERE s.numeroSolicitud = ?",
            numeroSolicitud
        );
        if (rows.isEmpty()) {
            throw new NoSuchElementException("No existe la solicitud #" + numeroSolicitud);
        }
        Map<String, Object> solicitud = new LinkedHashMap<>(rows.get(0));
        solicitud.put("incidentes", listarIncidentes(numeroSolicitud));
        return solicitud;
    }

    public List<Map<String, Object>> listarIncidentes(Integer numeroSolicitud) {
        if (numeroSolicitud != null) {
            return jdbc.queryForList(
                "SELECT i.codigoIncidente, i.numeroSolicitud, i.tipoIncidente, i.descripcion, " +
                "i.fechaHoraIncidente, s.estado AS estadoSolicitud " +
                "FROM Incidente i INNER JOIN SolicitudDomicilio s ON i.numeroSolicitud = s.numeroSolicitud " +
                "WHERE i.numeroSolicitud = ? ORDER BY i.codigoIncidente DESC",
                numeroSolicitud
            );
        }
        return jdbc.queryForList(
            "SELECT i.codigoIncidente, i.numeroSolicitud, i.tipoIncidente, i.descripcion, " +
            "i.fechaHoraIncidente, s.estado AS estadoSolicitud " +
            "FROM Incidente i INNER JOIN SolicitudDomicilio s ON i.numeroSolicitud = s.numeroSolicitud " +
            "ORDER BY i.codigoIncidente DESC"
        );
    }

    public List<Map<String, Object>> listarAuditoria() {
        return jdbc.queryForList("SELECT * FROM AuditoriaSistema ORDER BY idAuditoria DESC LIMIT 50");
    }

    public Map<String, Object> obtenerVistas() {
        Map<String, Object> vistas = new LinkedHashMap<>();
        vistas.put("activas", obtenerVistaActivas());
        vistas.put("domiciliarios", obtenerVistaDomiciliarios());
        vistas.put("establecimientos", obtenerVistaEstablecimientos());
        return vistas;
    }

    public List<Map<String, Object>> obtenerVistaActivas() {
        return jdbc.queryForList("SELECT * FROM vw_solicitudes_activas_cali");
    }

    public List<Map<String, Object>> obtenerVistaDomiciliarios() {
        return jdbc.queryForList("SELECT * FROM vw_resumen_domiciliarios");
    }

    public List<Map<String, Object>> obtenerVistaEstablecimientos() {
        return jdbc.queryForList("SELECT * FROM vw_resumen_establecimientos");
    }

    public Map<String, Object> registrarSolicitud(Map<String, Object> body) {
        return jdbc.execute((Connection conn) -> {
            try (CallableStatement cs = conn.prepareCall("{CALL sp_registrar_solicitud(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}")) {
                cs.setString(1, requireStr(body.get("numeroIdentificacionCliente"), "numeroIdentificacionCliente"));
                cs.setInt(2, toInt(body.get("idDireccion"), "idDireccion"));
                cs.setString(3, requireStr(body.get("descripcionRecogida"), "descripcionRecogida"));
                cs.setString(4, requireStr(body.get("metodoPago"), "metodoPago"));
                cs.setBigDecimal(5, new BigDecimal(requireStr(body.get("montoTotal"), "montoTotal")));

                Integer codEst = toNullableInt(body.get("codigoEstablecimiento"));
                String ubiExt = blankToNull(body.get("ubicacionRecogidaExterna"));
                Integer barrioExt = toNullableInt(body.get("idBarrioRecogidaExterna"));

                if (codEst != null) cs.setInt(6, codEst); else cs.setNull(6, Types.INTEGER);
                if (ubiExt != null) cs.setString(7, ubiExt); else cs.setNull(7, Types.VARCHAR);
                if (barrioExt != null) cs.setInt(8, barrioExt); else cs.setNull(8, Types.INTEGER);

                cs.registerOutParameter(9, Types.INTEGER);
                cs.registerOutParameter(10, Types.VARCHAR);
                cs.execute();

                Object rawId = cs.getObject(9);
                Integer idGenerado = (rawId instanceof Number n) ? n.intValue() : null;
                String resultado = cs.getString(10);
                Map<String, Object> res = new LinkedHashMap<>();
                res.put("ok", resultado != null && resultado.startsWith("EXITOSO"));
                res.put("numeroSolicitud", idGenerado);
                res.put("mensaje", resultado);
                return res;
            }
        });
    }

    public Map<String, Object> asignarDomiciliario(int numeroSolicitud, int codigoDomiciliario) {
        return jdbc.execute((Connection conn) -> {
            try (CallableStatement cs = conn.prepareCall("{CALL sp_asignar_domiciliario(?, ?, ?)}")) {
                cs.setInt(1, numeroSolicitud);
                cs.setInt(2, codigoDomiciliario);
                cs.registerOutParameter(3, Types.VARCHAR);
                cs.execute();

                String resultado = cs.getString(3);
                Map<String, Object> res = new LinkedHashMap<>();
                res.put("ok", resultado != null && resultado.startsWith("EXITOSO"));
                res.put("mensaje", resultado != null ? resultado : "Sin respuesta");
                return res;
            }
        });
    }

    public Map<String, Object> actualizarEstadoSolicitud(int numeroSolicitud, String nuevoEstado) {
        return jdbc.execute((Connection conn) -> {
            try (CallableStatement cs = conn.prepareCall("{CALL sp_actualizar_estado_solicitud(?, ?, ?)}")) {
                cs.setInt(1, numeroSolicitud);
                cs.setString(2, nuevoEstado);
                cs.registerOutParameter(3, Types.VARCHAR);
                cs.execute();

                String resultado = cs.getString(3);
                Map<String, Object> res = new LinkedHashMap<>();
                res.put("ok", resultado != null && resultado.startsWith("EXITOSO"));
                res.put("mensaje", resultado != null ? resultado : "Sin respuesta");
                return res;
            }
        });
    }

    @Transactional
    public void crearCliente(Map<String, Object> body) {
        String id = requireStr(body.get("numeroIdentificacion"), "numeroIdentificacion");
        Integer existeUsuario = jdbc.queryForObject(
            "SELECT COUNT(*) FROM Usuario WHERE numeroIdentificacion = ?", Integer.class, id
        );
        Integer yaEsCliente = jdbc.queryForObject(
            "SELECT COUNT(*) FROM Cliente WHERE numeroIdentificacion = ?", Integer.class, id
        );

        if (yaEsCliente != null && yaEsCliente > 0) {
            throw new DuplicateKeyException("El cliente con identificación " + id + " ya está registrado.");
        }

        // RN-01: Herencia solapada — si ya existe como Usuario (ej. Domiciliario), se reutiliza su registro base
        if (existeUsuario == null || existeUsuario == 0) {
            jdbc.update(
                "INSERT INTO Usuario (numeroIdentificacion, nombres, apellidoPaterno, apellidoMaterno, telefono, correoElectronico) " +
                "VALUES (?, ?, ?, ?, ?, ?)",
                id,
                requireStr(body.get("nombres"), "nombres"),
                requireStr(body.get("apellidoPaterno"), "apellidoPaterno"),
                blankToNull(body.get("apellidoMaterno")),
                requireStr(body.get("telefono"), "telefono"),
                requireStr(body.get("correoElectronico"), "correoElectronico")
            );
        }
        jdbc.update("INSERT INTO Cliente (numeroIdentificacion) VALUES (?)", id);

        String ubicacion = blankToNull(body.get("ubicacion"));
        Integer idBarrio = toNullableInt(body.get("idBarrio"));
        if (ubicacion != null && idBarrio != null) {
            jdbc.update(
                "INSERT INTO DireccionEntrega (ubicacion, idBarrio, referenciaAdicional, numeroIdentificacionCliente) " +
                "VALUES (?, ?, ?, ?)",
                ubicacion, idBarrio, blankToNull(body.get("referenciaAdicional")), id
            );
        }
    }

    public void crearDireccion(Map<String, Object> body) {
        jdbc.update(
            "INSERT INTO DireccionEntrega (ubicacion, idBarrio, referenciaAdicional, numeroIdentificacionCliente) " +
            "VALUES (?, ?, ?, ?)",
            requireStr(body.get("ubicacion"), "ubicacion"),
            toInt(body.get("idBarrio"), "idBarrio"),
            blankToNull(body.get("referenciaAdicional")),
            requireStr(body.get("numeroIdentificacionCliente"), "numeroIdentificacionCliente")
        );
    }

    @Transactional
    public void crearDomiciliario(Map<String, Object> body) {
        String id = requireStr(body.get("numeroIdentificacion"), "numeroIdentificacion");
        Integer existeUsuario = jdbc.queryForObject(
            "SELECT COUNT(*) FROM Usuario WHERE numeroIdentificacion = ?", Integer.class, id
        );
        Integer yaEsDomiciliario = jdbc.queryForObject(
            "SELECT COUNT(*) FROM Domiciliario WHERE numeroIdentificacion = ?", Integer.class, id
        );

        if (yaEsDomiciliario != null && yaEsDomiciliario > 0) {
            throw new DuplicateKeyException("El domiciliario con identificación " + id + " ya está registrado.");
        }

        // RN-01: Herencia solapada — si ya existe como Usuario (ej. Cliente), se reutiliza su registro base
        if (existeUsuario == null || existeUsuario == 0) {
            jdbc.update(
                "INSERT INTO Usuario (numeroIdentificacion, nombres, apellidoPaterno, apellidoMaterno, telefono, correoElectronico) " +
                "VALUES (?, ?, ?, ?, ?, ?)",
                id,
                requireStr(body.get("nombres"), "nombres"),
                requireStr(body.get("apellidoPaterno"), "apellidoPaterno"),
                blankToNull(body.get("apellidoMaterno")),
                requireStr(body.get("telefono"), "telefono"),
                requireStr(body.get("correoElectronico"), "correoElectronico")
            );
        }
        String estado = blankToNull(body.get("estado"));
        jdbc.update(
            "INSERT INTO Domiciliario (numeroIdentificacion, medioTransporte, estado) VALUES (?, ?, ?)",
            id,
            requireStr(body.get("medioTransporte"), "medioTransporte"),
            estado != null ? estado : "activo"
        );
    }

    public void cambiarEstadoDomiciliario(int codigoDomiciliario, String estado) {
        int updated = jdbc.update(
            "UPDATE Domiciliario SET estado = ? WHERE codigoDomiciliario = ?",
            estado, codigoDomiciliario
        );
        if (updated == 0) {
            throw new NoSuchElementException("No existe el domiciliario #" + codigoDomiciliario);
        }
    }

    public void crearEstablecimiento(Map<String, Object> body) {
        jdbc.update(
            "INSERT INTO EstablecimientoAliado (nombreComercial, tipoEstablecimiento, ubicacion, idBarrio, telefono, correoElectronico) " +
            "VALUES (?, ?, ?, ?, ?, ?)",
            requireStr(body.get("nombreComercial"), "nombreComercial"),
            requireStr(body.get("tipoEstablecimiento"), "tipoEstablecimiento"),
            requireStr(body.get("ubicacion"), "ubicacion"),
            toInt(body.get("idBarrio"), "idBarrio"),
            requireStr(body.get("telefono"), "telefono"),
            blankToNull(body.get("correoElectronico"))
        );
    }

    public void registrarIncidente(Map<String, Object> body) {
        String fecha = blankToNull(body.get("fechaHoraIncidente"));
        if (fecha != null) {
            String fechaSql = fecha.replace("T", " ");
            if (fechaSql.length() == 16) fechaSql += ":00";
            jdbc.update(
                "INSERT INTO Incidente (tipoIncidente, descripcion, fechaHoraIncidente, numeroSolicitud) VALUES (?, ?, ?, ?)",
                requireStr(body.get("tipoIncidente"), "tipoIncidente"),
                requireStr(body.get("descripcion"), "descripcion"),
                fechaSql,
                toInt(body.get("numeroSolicitud"), "numeroSolicitud")
            );
        } else {
            jdbc.update(
                "INSERT INTO Incidente (tipoIncidente, descripcion, fechaHoraIncidente, numeroSolicitud) VALUES (?, ?, NOW(), ?)",
                requireStr(body.get("tipoIncidente"), "tipoIncidente"),
                requireStr(body.get("descripcion"), "descripcion"),
                toInt(body.get("numeroSolicitud"), "numeroSolicitud")
            );
        }
    }

    private String str(Object o) { return o == null ? null : o.toString().trim(); }
    private String blankToNull(Object o) { String s = str(o); return (s == null || s.isBlank()) ? null : s; }
    private String requireStr(Object o, String campo) {
        String s = blankToNull(o);
        if (s == null) throw new IllegalArgumentException("El campo '" + campo + "' es obligatorio.");
        return s;
    }
    private int toInt(Object o, String campo) {
        String s = requireStr(o, campo);
        return Integer.parseInt(s);
    }
    private Integer toNullableInt(Object o) {
        String s = blankToNull(o);
        return s == null ? null : Integer.parseInt(s);
    }
}
