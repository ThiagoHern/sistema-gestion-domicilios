# Sistema de Gestión de Operaciones de Domicilios (Cali)

Proyecto Integrador — **Bases de Datos 1** | Universidad Autónoma de Occidente.

## Ejecutar en 1 clic (sin descargar nada)

Haz clic en el siguiente botón para abrir el entorno completo en la nube (**MySQL 8 + datos cargados + Spring Boot + Interfaz Gráfica**):

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/TU_USUARIO/sistema-gestion-domicilios?quickstart=1)

> Al terminar de cargar (1–2 min), la interfaz web se abrirá automáticamente en el puerto `8080`. Si el navegador bloquea la ventana emergente, abre la pestaña **Ports** en la parte inferior y haz clic en el ícono de globo del puerto **8080**.

## Qué puedes probar desde la interfaz
1. **Crear solicitudes** validando origen exclusivo (aliado o dirección externa) mediante `sp_registrar_solicitud`.
2. **Asignar domiciliarios** con `sp_asignar_domiciliario` (prueba asignar a **#3 Julián Castro [inactivo]** para ver el rechazo transaccional con `ROLLBACK`).
3. **Avanzar estados** (`asignada` -> `en curso` -> `finalizada`) y ver el registro automático en `AuditoriaSistema`.
4. **Reportar incidentes** disparando `trg_validar_incidente_fecha` y `trg_auditar_incidente`.
5. **Consultar las 3 vistas analíticas** (`vw_solicitudes_activas_cali`, `vw_resumen_domiciliarios`, `vw_resumen_establecimientos`).

## Documentación técnica
Consulta la **[GitHub Wiki](https://github.com/TU_USUARIO/sistema-gestion-domicilios/wiki)** para ver la arquitectura, el catálogo de endpoints REST y los casos de prueba para Postman.
