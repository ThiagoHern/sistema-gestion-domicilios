package com.uao.domicilios;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class DomiciliosController {

    private final DomiciliosService service;

    public DomiciliosController(DomiciliosService service) {
        this.service = service;
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        return service.verificarSalud();
    }

    @GetMapping("/catalogos")
    public Map<String, Object> catalogos() {
        return service.obtenerCatalogos();
    }

    @GetMapping("/barrios")
    public List<Map<String, Object>> listarBarrios() {
        return service.listarBarrios();
    }

    @PostMapping("/barrios")
    public ResponseEntity<Map<String, Object>> crearBarrio(@RequestBody Map<String, Object> body) {
        service.crearBarrio(body);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(Map.of("ok", true, "mensaje", "Barrio registrado correctamente."));
    }

    @GetMapping("/solicitudes")
    public List<Map<String, Object>> listarSolicitudes(
            @RequestParam(required = false) String estado,
            @RequestParam(required = false) String cliente) {
        return service.listarSolicitudes(estado, cliente);
    }

    @GetMapping("/solicitudes/{id}")
    public Map<String, Object> obtenerSolicitud(@PathVariable int id) {
        return service.obtenerSolicitudPorId(id);
    }

    @PostMapping("/solicitudes")
    public ResponseEntity<Map<String, Object>> crearSolicitud(@RequestBody Map<String, Object> body) {
        Map<String, Object> res = service.registrarSolicitud(body);
        return Boolean.TRUE.equals(res.get("ok"))
            ? ResponseEntity.status(HttpStatus.CREATED).body(res)
            : ResponseEntity.badRequest().body(res);
    }

    @PutMapping("/solicitudes/{id}/asignar")
    public ResponseEntity<Map<String, Object>> asignar(@PathVariable int id, @RequestBody Map<String, Object> body) {
        if (body.get("codigoDomiciliario") == null) {
            return ResponseEntity.badRequest().body(Map.of("ok", false, "mensaje", "El campo 'codigoDomiciliario' es obligatorio."));
        }
        int codDom = Integer.parseInt(body.get("codigoDomiciliario").toString().trim());
        Map<String, Object> res = service.asignarDomiciliario(id, codDom);
        return Boolean.TRUE.equals(res.get("ok"))
            ? ResponseEntity.ok(res)
            : ResponseEntity.badRequest().body(res);
    }

    @PutMapping("/solicitudes/{id}/estado")
    public ResponseEntity<Map<String, Object>> cambiarEstado(@PathVariable int id, @RequestBody Map<String, Object> body) {
        if (body.get("estado") == null) {
            return ResponseEntity.badRequest().body(Map.of("ok", false, "mensaje", "El campo 'estado' es obligatorio."));
        }
        String estado = body.get("estado").toString().trim();
        Map<String, Object> res = service.actualizarEstadoSolicitud(id, estado);
        return Boolean.TRUE.equals(res.get("ok"))
            ? ResponseEntity.ok(res)
            : ResponseEntity.badRequest().body(res);
    }

    @GetMapping("/incidentes")
    public List<Map<String, Object>> listarIncidentes(@RequestParam(required = false) Integer solicitud) {
        return service.listarIncidentes(solicitud);
    }

    @PostMapping("/incidentes")
    public ResponseEntity<Map<String, Object>> crearIncidente(@RequestBody Map<String, Object> body) {
        service.registrarIncidente(body);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
            "ok", true,
            "mensaje", "Incidente registrado y auditado automáticamente por el trigger."
        ));
    }

    @GetMapping("/auditoria")
    public List<Map<String, Object>> auditoria() {
        return service.listarAuditoria();
    }

    @GetMapping("/vistas")
    public Map<String, Object> vistas() {
        return service.obtenerVistas();
    }

    @GetMapping("/vistas/activas")
    public List<Map<String, Object>> vistaActivas() {
        return service.obtenerVistaActivas();
    }

    @GetMapping("/vistas/domiciliarios")
    public List<Map<String, Object>> vistaDomiciliarios() {
        return service.obtenerVistaDomiciliarios();
    }

    @GetMapping("/vistas/establecimientos")
    public List<Map<String, Object>> vistaEstablecimientos() {
        return service.obtenerVistaEstablecimientos();
    }

    @GetMapping("/clientes")
    public List<Map<String, Object>> listarClientes() {
        return service.listarClientes();
    }

    @PostMapping("/clientes")
    public ResponseEntity<Map<String, Object>> crearCliente(@RequestBody Map<String, Object> body) {
        service.crearCliente(body);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(Map.of("ok", true, "mensaje", "Cliente registrado correctamente."));
    }

    @GetMapping("/clientes/{id}/direcciones")
    public List<Map<String, Object>> listarDireccionesCliente(@PathVariable String id) {
        return service.listarDireccionesCliente(id);
    }

    @PostMapping("/direcciones")
    public ResponseEntity<Map<String, Object>> crearDireccion(@RequestBody Map<String, Object> body) {
        service.crearDireccion(body);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(Map.of("ok", true, "mensaje", "Dirección agregada al cliente."));
    }

    @GetMapping("/domiciliarios")
    public List<Map<String, Object>> listarDomiciliarios() {
        return service.listarDomiciliarios();
    }

    @PostMapping("/domiciliarios")
    public ResponseEntity<Map<String, Object>> crearDomiciliario(@RequestBody Map<String, Object> body) {
        service.crearDomiciliario(body);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(Map.of("ok", true, "mensaje", "Domiciliario registrado correctamente."));
    }

    @PutMapping("/domiciliarios/{codigo}/estado")
    public ResponseEntity<Map<String, Object>> estadoDomiciliario(@PathVariable int codigo, @RequestBody Map<String, Object> body) {
        if (body.get("estado") == null) {
            return ResponseEntity.badRequest().body(Map.of("ok", false, "mensaje", "El campo 'estado' es obligatorio."));
        }
        service.cambiarEstadoDomiciliario(codigo, body.get("estado").toString().trim());
        return ResponseEntity.ok(Map.of("ok", true, "mensaje", "Estado del domiciliario actualizado."));
    }

    @GetMapping("/establecimientos")
    public List<Map<String, Object>> listarEstablecimientos() {
        return service.listarEstablecimientos();
    }

    @PostMapping("/establecimientos")
    public ResponseEntity<Map<String, Object>> crearEstablecimiento(@RequestBody Map<String, Object> body) {
        service.crearEstablecimiento(body);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(Map.of("ok", true, "mensaje", "Establecimiento aliado registrado."));
    }

    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<Map<String, Object>> manejarNoEncontrado(NoSuchElementException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("ok", false);
        body.put("mensaje", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(body);
    }

    @ExceptionHandler(DuplicateKeyException.class)
    public ResponseEntity<Map<String, Object>> manejarDuplicado(DuplicateKeyException ex) {
        Throwable root = rootCause(ex);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("ok", false);
        body.put("mensaje", "Registro duplicado: " + root.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT).body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> manejarError(Exception ex) {
        Throwable root = rootCause(ex);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("ok", false);
        body.put("mensaje", "Error en Base de Datos: " + root.getMessage());
        return ResponseEntity.badRequest().body(body);
    }

    private Throwable rootCause(Throwable ex) {
        Throwable root = ex;
        while (root.getCause() != null) {
            root = root.getCause();
        }
        return root;
    }
}
