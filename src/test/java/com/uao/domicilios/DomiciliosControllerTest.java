package com.uao.domicilios;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(DomiciliosController.class)
class DomiciliosControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private DomiciliosService service;

    @Test
    void healthDevuelveEstadoOk() throws Exception {
        when(service.verificarSalud()).thenReturn(Map.of("ok", true, "solicitudes", 6));

        mockMvc.perform(get("/api/health"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.ok").value(true))
            .andExpect(jsonPath("$.solicitudes").value(6));
    }

    @Test
    void crearSolicitudValidaDevuelve201() throws Exception {
        when(service.registrarSolicitud(any())).thenReturn(Map.of(
            "ok", true,
            "numeroSolicitud", 507,
            "mensaje", "EXITOSO: Solicitud #507 creada correctamente."
        ));

        mockMvc.perform(post("/api/solicitudes")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"numeroIdentificacionCliente\":\"1001\",\"idDireccion\":1,\"descripcionRecogida\":\"Almuerzo\",\"metodoPago\":\"efectivo\",\"montoTotal\":35000,\"codigoEstablecimiento\":101}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.ok").value(true))
            .andExpect(jsonPath("$.numeroSolicitud").value(507));
    }

    @Test
    void crearSolicitudRechazadaPorReglaNegocioDevuelve400() throws Exception {
        when(service.registrarSolicitud(any())).thenReturn(Map.of(
            "ok", false,
            "mensaje", "RECHAZADO: La dirección de entrega no pertenece al cliente indicado."
        ));

        mockMvc.perform(post("/api/solicitudes")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"numeroIdentificacionCliente\":\"1001\",\"idDireccion\":3,\"descripcionRecogida\":\"Test\",\"metodoPago\":\"efectivo\",\"montoTotal\":20000,\"codigoEstablecimiento\":101}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.ok").value(false));
    }

    @Test
    void obtenerSolicitudInexistenteDevuelve404() throws Exception {
        when(service.obtenerSolicitudPorId(999)).thenThrow(new NoSuchElementException("No existe la solicitud #999"));

        mockMvc.perform(get("/api/solicitudes/999"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.ok").value(false));
    }

    @Test
    void asignarDomiciliarioInactivoDevuelve400() throws Exception {
        when(service.asignarDomiciliario(anyInt(), anyInt())).thenReturn(Map.of(
            "ok", false,
            "mensaje", "RECHAZADO: El domiciliario se encuentra inactivo."
        ));

        mockMvc.perform(put("/api/solicitudes/501/asignar")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"codigoDomiciliario\":3}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.mensaje").value("RECHAZADO: El domiciliario se encuentra inactivo."));
    }

    @Test
    void clienteDuplicadoDevuelve409() throws Exception {
        doThrow(new DuplicateKeyException("El cliente con identificación 1001 ya está registrado."))
            .when(service).crearCliente(any());

        mockMvc.perform(post("/api/clientes")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"numeroIdentificacion\":\"1001\"}"))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.ok").value(false));
    }

    @Test
    void listarVistasDevuelveEstructuraCompleta() throws Exception {
        when(service.obtenerVistas()).thenReturn(Map.of(
            "activas", List.of(),
            "domiciliarios", List.of(),
            "establecimientos", List.of()
        ));

        mockMvc.perform(get("/api/vistas"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.activas").isArray())
            .andExpect(jsonPath("$.domiciliarios").isArray())
            .andExpect(jsonPath("$.establecimientos").isArray());
    }
}
