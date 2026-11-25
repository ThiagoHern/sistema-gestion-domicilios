package com.uao.domicilios;

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

    public Map<String, Object> obtenerCatalogos() {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("barrios", jdbc.queryForList(
            "SELECT idBarrio, nombreBarrio, comuna FROM Barrio ORDER BY nombreBarrio"
        ));
        data.put("clientes", jdbc.queryForList(
            "SELECT u.numeroIdentificacion, u.nombres, u.apellidoPaterno, u.apellidoMaterno, " +
            "u.telefono, u.correoElectronico " +
            "FROM Cliente c INNER JOIN Usuario u ON c.numeroIdentificacion = u.numeroIdentificacion " +
            "ORDER BY u.nombres"
        ));
        data.put("direcciones", jdbc.queryForList(
            "SELECT d.idDireccion, d.ubicacion, d.referenciaAdicional, d.numeroIdentificacionCliente, " +
            "b.idBarrio, b.nombreBarrio, b.comuna " +
            "FROM DireccionEntrega d INNER JOIN Barrio b ON d.idBarrio = b.idBarrio " +
            "ORDER BY d.idDireccion"
        ));
        data.put("domiciliarios", jdbc.queryForList(
            "SELECT d.codigoDomiciliario, d.numeroIdentificacion, " +
            "CONCAT(u.nombres, ' ', u.apellidoPaterno) AS nombreCompleto, " +
            "u.telefono, d.medioTransporte, d.estado " +
            "FROM Domiciliario d INNER JOIN Usuario u ON d.numeroIdentificacion = u.numeroIdentificacion " +
            "ORDER BY d.codigoDomiciliario"
        ));
        data.put("establecimientos", jdbc.queryForList(
            "SELECT e.codigoEstablecimiento, e.nombreComercial, e.tipoEstablecimiento, " +
            "e.ubicacion, b.nombreBarrio, b.comuna, e.telefono, e.correoElectronico " +
            "FROM EstablecimientoAliado e INNER JOIN Barrio b ON e.idBarrio = b.idBarrio " +
            "ORDER BY e.codigoEstablecimiento"
        ));
        return data;
    }

    public List> listarSolicitudes() {
        return jdbc.queryForList(
            "SELECT s.numeroSolicitud, s.fechaHoraCreacion, s.estado, s.descripcionRecogida, " +
            "s.metodoPago, s.montoTotal, s.numeroIdentificacionCliente, " +
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
            "INNER JOIN DireccionEntrega d ON s.idDireccion = d.idDireccion " +
            "INNER JOIN Barrio b ON d.idBarrio = b.idBarrio " +
            "LEFT JOIN EstablecimientoAliado e ON s.codigoEstablecimiento = e.codigoEstablecimiento " +
            "LEFT JOIN Domiciliario dom ON s.codigoDomiciliario = dom.codigoDomiciliario " +
            "LEFT JOIN Usuario ud ON dom.numeroIdentificacion = ud.numeroIdentificacion " +
            "ORDER BY s.numeroSolicitud DESC"
        );
    }

    public List> listarIncidentes() {
        return jdbc.queryForList(
            "SELECT i.codigoIncidente, i.numeroSolicitud, i.tipoIncidente, i.descripcion, " +
            "i.fechaHoraIncidente, s.estado AS estadoSolicitud " +
            "FROM Incidente i INNER JOIN SolicitudDomicilio s ON i.numeroSolicitud = s.numeroSolicitud " +
            "ORDER BY i.codigoIncidente DESC"
        );
    }

    public List> listarAuditoria() {
        return jdbc.queryForList("SELECT * FROM AuditoriaSistema ORDER BY idAuditoria DESC LIMIT 50");
    }

    public Map<String, Object> obtenerVistas() {
        Map<String, Object> vistas = new LinkedHashMap<>();
        vistas.put("activas", jdbc.queryForList("SELECT * FROM vw_solicitudes_activas_cali"));
        vistas.put("domiciliarios", jdbc.queryForList("SELECT * FROM vw_resumen_domiciliarios"));
        vistas.put("establecimientos", jdbc.queryForList("SELECT * FROM vw_resumen_establecimientos"));
        return vistas;
    }

    public Map<String, Object> registrarSolicitud(Map<String, Object> body) {
        return jdbc.execute((Connection conn) -> {
            try (CallableStatement cs = conn.prepareCall("{CALL sp_registrar_solicitud(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}")) {
                cs.setString(1, str(body.get("numeroIdentificacionCliente")));
                cs.setInt(2, toInt(body.get("idDireccion")));
                cs.setString(3, str(body.get("descripcionRecogida")));
                cs.setString(4, str(body.get("metodoPago")));
                cs.setBigDecimal(5, new BigDecimal(str(body.get("montoTotal"))));

                Integer codEst = toNullableInt(body.get("codigoEstablecimiento"));
                String ubiExt = str(body.get("ubicacionRecogidaExterna"));
                Integer barrioExt = toNullableInt(body.get("idBarrioRecogidaExterna"));

                if (codEst != null) cs.setInt(6, codEst); else cs.setNull(6, Types.INTEGER);
                if (ubiExt != null && !ubiExt.isBlank()) cs.setString(7, ubiExt); else cs.setNull(7, Types.VARCHAR);
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
                return Map.of(
                    "ok", resultado != null && resultado.startsWith("EXITOSO"),
                    "mensaje", resultado != null ? resultado : "Sin respuesta"
                );
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
                return Map.of(
                    "ok", resultado != null && resultado.startsWith("EXITOSO"),
                    "mensaje", resultado != null ? resultado : "Sin respuesta"
                );
            }
        });
    }

    @Transactional
    public void crearCliente(Map<String, Object> body) {
        String id = str(body.get("numeroIdentificacion"));
        jdbc.update(
            "INSERT INTO Usuario (numeroIdentificacion, nombres, apellidoPaterno, apellidoMaterno, telefono, correoElectronico) " +
            "VALUES (?, ?, ?, ?, ?, ?)",
            id, str(body.get("nombres")), str(body.get("apellidoPaterno")),
            blankToNull(body.get("apellidoMaterno")), str(body.get("telefono")), str(body.get("correoElectronico"))
        );
        jdbc.update("INSERT INTO Cliente (numeroIdentificacion) VALUES (?)", id);

        String ubicacion = str(body.get("ubicacion"));
        Integer idBarrio = toNullableInt(body.get("idBarrio"));
        if (ubicacion != null && !ubicacion.isBlank() && idBarrio != null) {
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
            str(body.get("ubicacion")), toInt(body.get("idBarrio")),
            blankToNull(body.get("referenciaAdicional")), str(body.get("numeroIdentificacionCliente"))
        );
    }

    @Transactional
    public void crearDomiciliario(Map<String, Object> body) {
        String id = str(body.get("numeroIdentificacion"));
        jdbc.update(
            "INSERT INTO Usuario (numeroIdentificacion, nombres, apellidoPaterno, apellidoMaterno, telefono, correoElectronico) " +
            "VALUES (?, ?, ?, ?, ?, ?)",
            id, str(body.get("nombres")), str(body.get("apellidoPaterno")),
            blankToNull(body.get("apellidoMaterno")), str(body.get("telefono")), str(body.get("correoElectronico"))
        );
        jdbc.update(
            "INSERT INTO Domiciliario (numeroIdentificacion, medioTransporte, estado) VALUES (?, ?, ?)",
            id, str(body.get("medioTransporte")), str(body.get("estado"))
        );
    }

    public void cambiarEstadoDomiciliario(int codigoDomiciliario, String estado) {
        jdbc.update("UPDATE Domiciliario SET estado = ? WHERE codigoDomiciliario = ?", estado, codigoDomiciliario);
    }

    public void crearEstablecimiento(Map<String, Object> body) {
        jdbc.update(
            "INSERT INTO EstablecimientoAliado (nombreComercial, tipoEstablecimiento, ubicacion, idBarrio, telefono, correoElectronico) " +
            "VALUES (?, ?, ?, ?, ?, ?)",
            str(body.get("nombreComercial")), str(body.get("tipoEstablecimiento")),
            str(body.get("ubicacion")), toInt(body.get("idBarrio")),
            str(body.get("telefono")), blankToNull(body.get("correoElectronico"))
        );
    }

    public void registrarIncidente(Map<String, Object> body) {
        String fecha = str(body.get("fechaHoraIncidente"));
        if (fecha != null && !fecha.isBlank()) {
            String fechaSql = fecha.replace("T", " ");
            if (fechaSql.length() == 16) fechaSql += ":00";
            jdbc.update(
                "INSERT INTO Incidente (tipoIncidente, descripcion, fechaHoraIncidente, numeroSolicitud) VALUES (?, ?, ?, ?)",
                str(body.get("tipoIncidente")), str(body.get("descripcion")),
                fechaSql, toInt(body.get("numeroSolicitud"))
            );
        } else {
            jdbc.update(
                "INSERT INTO Incidente (tipoIncidente, descripcion, fechaHoraIncidente, numeroSolicitud) VALUES (?, ?, NOW(), ?)",
                str(body.get("tipoIncidente")), str(body.get("descripcion")), toInt(body.get("numeroSolicitud"))
            );
        }
    }

    private String str(Object o) { return o == null ? null : o.toString().trim(); }
    private String blankToNull(Object o) { String s = str(o); return (s == null || s.isBlank()) ? null : s; }
    private int toInt(Object o) { return Integer.parseInt(o.toString().trim()); }
    private Integer toNullableInt(Object o) {
        if (o == null || o.toString().trim().isEmpty()) return null;
        return Integer.parseInt(o.toString().trim());
    }
}
