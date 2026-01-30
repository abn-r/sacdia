# Tasks - Sistema de Notificaciones

> **Estado**: In Progress  
> **Estimación Total**: 5 días

## Progreso: [███░░░] 30%

---

## Backend (3 días)

### T1: Setup Database
**Estado**: `[x]` Done | **Estimación**: 0.5 días

**Completado**:
- [x] Migración de tablas notifications y notification_preferences
- [x] Índices creados
- [x] Seeds de prueba

---

### T2: Crear Modelos y Servicios
**Estado**: `[/]` In Progress | **Estimación**: 1 día

**Checklist**:
- [x] Modelo Notification
- [x] Modelo NotificationPreference  
- [/] NotificationService con métodos CRUD
- [ ] Tests (coverage >80%)

**Archivos**:
- `src/models/Notification.ts`
- `src/services/notificationService.ts`

---

### T3: Implementar API Endpoints
**Estado**: `[ ]` Pendiente | **Estimación**: 1 día

**Checklist**:
- [ ] GET /notifications
- [ ] PATCH /notifications/:id/read
- [ ] GET /notification-preferences
- [ ] PUT /notification-preferences
- [ ] Integration tests

**Dependencias**: T2

---

### T4: Email Worker
**Estado**: `[ ]` Pendiente | **Estimación**: 0.5 días

**Checklist**:
- [ ] Configurar Redis queue
- [ ] Worker para procesar emails
- [ ] Integración con SendGrid
- [ ] Error handling y retries

**Dependencias**: T2

---

## Frontend (1.5 días)

### T5: Componente Notifications
**Estado**: `[ ]` | **Estimación**: 1 día

**Checklist**:
- [ ] NotificationBell component (header)
- [ ] NotificationPanel component
- [ ] NotificationItem component
- [ ] Estado con React Query
- [ ] Mark as read functionality

**Dependencias**: T3

---

### T6: Página de Preferencias
**Estado**: `[ ]` | **Estimación**: 0.5 días

**Checklist**:
- [ ] Settings page
- [ ] Toggle switches por tipo
- [ ] Save preferences

**Dependencias**: T3

---

## Testing (0.5 días)

### T7: E2E Tests
**Estado**: `[ ]` | **Estimación**: 0.5 días

**Checklist**:
- [ ] User receives notification
- [ ] User marks as read
- [ ] User changes preferences

**Dependencias**: T5, T6

---

## Notas para IA

Al implementar:
1. Lee requirements.md para criterios EARS
2. Sigue design.md para schemas y APIs
3. Usa tech stack de tech.md
4. Tests obligatorios por tarea
