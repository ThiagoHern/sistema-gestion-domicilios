package com.uao.domicilios;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class DomiciliosController {

    private final DomiciliosService service;

    public DomiciliosController(DomiciliosService service) {
        this.service = service;
    }

    @GetMapping("/catalogos")
    public Map<String, Object> catalogos() {
        return service.obtenerCatalogos();
    }

    @GetMapping("/solicitudes")
    public List> listarSolicitudes() {
        return service.listarSolicitudes();
    }

    @PostMapping("/solicitudes")
    public ResponseEntity> crearSolicitud(@RequestBody Map<String, Object> body) {
        Map<String, Object> res = service.registrarSolicitud(body);
        return Boolean.TRUE.equals(res.get("ok"))
            ? ResponseEntity.status(201).body(res)
            : ResponseEntity.badRequest().body(res);
    }

    @PutMapping("/solicitudes/{id}/asignar")
    public ResponseEntity> asignar(@PathVariable int id, @RequestBody Map<String, Object> body) {
        int codDom = Integer.parseInt(body.get("codigoDomiciliario").toString());
        Map<String, Object> res = service.asignarDomiciliario(id, codDom);
        return Boolean.TRUE.equals(res.get("ok"))
            ? ResponseEntity.ok(res)
            : ResponseEntity.badRequest().body(res);
    }

    @PutMapping("/solicitudes/{id}/estado")
    public ResponseEntity> cambiarEstado(@PathVariable int id, @RequestBody Map<String, Object> body) {
        String estado = body.get("estado").toString();
        Map<String, Object> res = service.actualizarEstadoSolicitud(id, estado);
        return Boolean.TRUE.equals(res.get("ok"))
            ? ResponseEntity.ok(res)
            : ResponseEntity.badRequest().body(res);
    }

    @GetMapping("/incidentes")
    public List> listarIncidentes() {
        return service.listarIncidentes();
    }

    @PostMapping("/incidentes")
    public ResponseEntity> crearIncidente(@RequestBody Map<String, Object> body) {
        service.registrarIncidente(body);
        return ResponseEntity.status(201).body(Map.of(
            "ok", true,
            "mensaje", "Incidente registrado y auditado automáticamente por el trigger."
        ));
    }

    @GetMapping("/auditoria")
    public List> auditoria() {
        return service.listarAuditoria();
    }

    @GetMapping("/vistas")
    public Map<String, Object> vistas() {
        return service.obtenerVistas();
    }

    @PostMapping("/clientes")
    public ResponseEntity> crearCliente(@RequestBody Map<String, Object> body) {
        service.crearCliente(body);
        return ResponseEntity.status(201).body(Map.of("ok", true, "mensaje", "Cliente registrado correctamente."));
    }

    @PostMapping("/direcciones")
    public ResponseEntity> crearDireccion(@RequestBody Map<String, Object> body) {
        service.crearDireccion(body);
        return ResponseEntity.status(201).body(Map.of("ok", true, "mensaje", "Dirección agregada al cliente."));
    }

    @PostMapping("/domiciliarios")
    public ResponseEntity> crearDomiciliario(@RequestBody Map<String, Object> body) {
        service.crearDomiciliario(body);
        return ResponseEntity.status(201).body(Map.of("ok", true, "mensaje", "Domiciliario registrado correctamente."));
    }

    @PutMapping("/domiciliarios/{codigo}/estado")
    public ResponseEntity> estadoDomiciliario(@PathVariable int codigo, @RequestBody Map<String, Object> body) {
        service.cambiarEstadoDomiciliario(codigo, body.get("estado").toString());
        return ResponseEntity.ok(Map.of("ok", true, "mensaje", "Estado del domiciliario actualizado."));
    }

    @PostMapping("/establecimientos")
    public ResponseEntity> crearEstablecimiento(@RequestBody Map<String, Object> body) {
        service.crearEstablecimiento(body);
        return ResponseEntity.status(201).body(Map.of("ok", true, "mensaje", "Establecimiento aliado registrado."));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity> manejarError(Exception ex) {
        Throwable root = ex;
        while (root.getCause() != null) root = root.getCause();
        return ResponseEntity.badRequest().body(Map.of(
            "ok", false,
            "mensaje", "Error en Base de Datos: " + root.getMessage()
        ));
    }
}
