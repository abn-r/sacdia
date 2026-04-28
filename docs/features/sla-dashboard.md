# SLA Dashboard

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El SLA Dashboard es un panel de analiticas operacionales que permite a coordinadores y administradores monitorear el estado de los procesos de aprobacion y validacion del sistema. Muestra metricas clave como aprobaciones pendientes, items vencidos, tiempos promedio de aprobacion, tasas de aprobacion y throughput semanal.

El dashboard cubre tres pipelines operacionales: (1) investiduras — envio, validacion y ceremonia, (2) validacion de clases y honores — revision de evidencias y progreso, y (3) inscripciones de camporees — aprobaciones de clubes, miembros y pagos. Las metricas estan scopeadas al contexto del coordinador (campo local) y se cachean durante 60 segundos para evitar carga excesiva en la base de datos.

## Que existe (verificado contra codigo)

### Backend (AnalyticsModule)
- **Modulo nuevo**: `src/analytics/`
- **1 endpoint**:
  - `GET /api/v1/admin/analytics/sla-dashboard` — Metricas SLA completas
- Respuesta incluye:
  - Conteos de pendientes por pipeline (investiture, validation, camporee)
  - Items overdue (pasados del deadline sin procesar)
  - Tiempos promedio de aprobacion (en horas)
  - Tasas de aprobacion (porcentaje)
  - Throughput de 12 semanas (aprobaciones por semana)
- Cache de 60 segundos para performance
- Scoped por campo local del coordinador
- Guards: JwtAuthGuard, GlobalRolesGuard (admin, coordinator)

### Admin (sacdia-admin)
- **Pagina dedicada**: `/dashboard/sla`
- **Componentes**: `src/components/sla/`
- **Tarjetas de resumen**: Pendientes, overdue, tiempos promedio, tasas de aprobacion
- **Grafico de throughput**: 12 semanas de tendencia de aprobaciones
- **Desglose por pipeline**: Metricas separadas para investiduras, validacion y camporees
- **Auto-refresh**: Actualizacion periodica alineada con el cache del backend

### Base de datos
- Sin cambios de schema — consultas agregadas sobre tablas existentes
- Queries optimizadas con indices existentes

## Requisitos funcionales

1. Coordinadores deben poder ver un resumen de todos los items pendientes de su gestion
2. Los items overdue deben ser claramente identificables
3. Los tiempos promedio de aprobacion deben calcularse por pipeline
4. La tasa de aprobacion debe mostrarse como porcentaje por pipeline
5. El throughput semanal debe cubrir las ultimas 12 semanas
6. Las metricas deben estar scopeadas al campo local del coordinador
7. El dashboard no debe impactar la performance del sistema (cache de 60s)

## Decisiones de diseno

- **Modulo independiente**: AnalyticsModule separado para evitar acoplar metricas a modulos operacionales
- **Cache de 60 segundos**: Balance entre frescura de datos y carga en base de datos
- **Coordinator-scoped**: Cada coordinador ve solo las metricas de su campo local
- **12 semanas de throughput**: Ventana suficiente para identificar tendencias sin sobrecargar la visualizacion
- **Endpoint unico**: Un solo endpoint que retorna todas las metricas, evitando multiples round-trips del frontend

## Gaps y pendientes

- Sin alertas configurables (ej: notificar cuando hay mas de X items overdue)
- Sin exportacion de metricas a CSV/PDF
- Sin comparativa entre periodos (este mes vs mes anterior)
- Sin drill-down desde las metricas a los items individuales

## Estado de implementacion

- Backend: AnalyticsModule con 1 endpoint y cache de 60s
- Admin: Dashboard con tarjetas, grafico de throughput y desglose por pipeline
