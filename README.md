# SACDIA - Sistema de Administración de Clubes de Conquistadores y JDVA

Sistema integral de gestión para clubes de Conquistadores, Aventureros y JDVA, desarrollado con arquitectura moderna y escalable.

## 📋 Descripción

SACDIA es una plataforma completa que permite administrar:

- Clubes de Conquistadores, Aventureros y Guías Mayores
- Inscripciones anuales y períodos de membresía
- Gestión de miembros, roles y permisos (RBAC)
- Sistema de investidura y certificaciones
- Clases progresivas y especialidades
- Seguros y gestión financiera
- Campamentos y eventos (camporees)
- Control de inventario
- Sistema de carpetas de evidencias (portfolios)
- Notificaciones push y actualizaciones en tiempo real

## 📊 Estado del Proyecto

**Fase 1 (Backend):** ✅ **COMPLETADA**

- **105+ endpoints** REST implementados
- **17 módulos** funcionales
- **90%+ coverage** de tests
- **OAuth** con Google y Apple
- **Push Notifications** con Firebase FCM
- **WebSockets** para real-time
- **95% de implementación** completada

## 🏗️ Arquitectura - Multi-Repositorio

Este proyecto utiliza una arquitectura de **multi-repositorio** para mantener cada componente independiente:

### Repositorios del Proyecto

| Componente           | Repositorio                                               | Descripción                   | Tecnología                   |
| -------------------- | --------------------------------------------------------- | ----------------------------- | ---------------------------- |
| 📚 **Documentación** | [sacdia](https://github.com/abn-r/sacdia)                 | Specs y documentación central | Markdown                     |
| 🔧 **Backend**       | [sacdia-backend](https://github.com/abn-r/sacdia-backend) | API REST y lógica de negocio  | NestJS + Prisma + Supabase   |
| 📱 **App Móvil**     | [sandia-app](https://github.com/abn-r/sandia-app)         | Aplicación móvil iOS/Android  | Flutter + Clean Architecture |
| 💻 **Panel Admin**   | [sandia-admin](https://github.com/abn-r/sandia-admin)     | Panel de administración web   | Next.js 16 + shadcn/ui       |

## 📁 Contenido de Este Repositorio

Este repositorio contiene **únicamente la documentación y especificaciones** del proyecto:

```
sacdia/
├── .specs/              # Especificaciones técnicas del proyecto
│   ├── _steering/       # Documentos de dirección (tech stack, roadmap)
│   ├── architecture/    # Diagramas y arquitectura
│   └── features/        # Especificaciones de features
├── docs/                # Documentación técnica y de producto
│   ├── database/        # Schema, migraciones, relaciones
│   ├── api/             # Documentación de API
│   └── guides/          # Guías de desarrollo
└── README.md           # Este archivo
```

## 🚀 Quick Start

### Para Desarrolladores

1. **Clona todos los repositorios:**

```bash
# Crear carpeta del proyecto
mkdir sacdia && cd sacdia

# Clonar documentación
git clone https://github.com/abn-r/sacdia.git .

# Clonar backend
git clone https://github.com/abn-r/sacdia-backend.git

# Clonar app móvil
git clone https://github.com/abn-r/sandia-app.git sacdia-app

# Clonar panel admin
git clone https://github.com/abn-r/sandia-admin.git sacdia-admin
```

2. **Configurar cada proyecto:**

```bash
# Backend
cd sacdia-backend
cp .env.example .env
pnpm install
pnpm prisma migrate dev

# Admin Panel
cd ../sacdia-admin
cp .env.local.example .env.local
pnpm install
pnpm dev

# App Móvil
cd ../sacdia-app
flutter pub get
flutter run
```

## 🛠️ Tech Stack

### Backend

- **Framework:** NestJS 10
- **Database:** PostgreSQL (Supabase)
- **ORM:** Prisma
- **Auth:** Supabase Auth (JWT + OAuth)
- **Validation:** class-validator + class-transformer
- **Push Notifications:** Firebase Cloud Messaging
- **Real-time:** Socket.io (WebSockets)
- **Storage:** Supabase Storage
- **Testing:** Jest + Supertest (90%+ coverage)

### Frontend Admin

- **Framework:** Next.js 16 (App Router)
- **Language:** TypeScript
- **Styling:** Tailwind CSS v4
- **UI:** shadcn/ui
- **Forms:** React Hook Form + Zod

### Mobile App

- **Framework:** Flutter 3.x
- **Architecture:** Clean Architecture
- **State Management:** Riverpod
- **HTTP Client:** Dio
- **Storage:** Hive

### Deployment

- **Backend:** Railway / Vercel Serverless
- **Admin:** Vercel
- **Database:** Supabase (Free tier)
- **Storage:** Supabase Storage
- **Mobile:** App Store + Google Play

## ✅ Features Implementadas

### Backend (API REST v2.2)

#### Autenticación y Autorización
- [x] Registro y Login con Supabase Auth
- [x] Sistema RBAC con roles globales y de club
- [x] 2FA (Two-Factor Authentication)
- [x] Session Management con límites
- [x] Token Blacklist
- [x] IP Whitelist para administradores
- [x] OAuth con Google y Apple
- [x] Reset Password completo

#### Post-Registro y Usuarios
- [x] Upload de fotografía de perfil
- [x] Información personal completa
- [x] Contactos de emergencia (máximo 5)
- [x] Alergias y enfermedades
- [x] Representantes legales (menores de 18)
- [x] Tracking granular de progreso

#### Gestión de Clubes
- [x] CRUD de clubes e instancias (Aventureros, Conquistadores, GM)
- [x] Gestión de miembros por año eclesiástico
- [x] Asignación de roles de club (Director, Subdirector, Consejero, etc.)
- [x] Permisos por rol con guards personalizados

#### Clases Progresivas
- [x] Catálogo de clases por tipo de club
- [x] Sistema de módulos y secciones
- [x] Inscripción y tracking de progreso
- [x] Validación de investiduras
- [x] Cálculo de porcentaje de avance

#### Certificaciones
- [x] Sistema exclusivo para Guías Mayores investidos
- [x] Inscripción múltiple paralela
- [x] Progreso por módulos y secciones
- [x] Validación automática de elegibilidad

#### Honores y Especialidades
- [x] Catálogo de honores por categoría
- [x] Niveles de habilidad (Básico, Intermedio, Avanzado)
- [x] Progreso de honores por usuario
- [x] Validación de instructor
- [x] Estadísticas de honores completados

#### Actividades y Eventos
- [x] Creación y gestión de actividades de club
- [x] Registro de asistencia
- [x] Geolocalización de eventos
- [x] Tipos de actividad (Reunión, Campamento, Servicio, etc.)
- [x] Historial de participación

#### Campamentos (Camporees)
- [x] Gestión de campamentos locales y de unión
- [x] Registro de participantes
- [x] Validación automática de seguros activos
- [x] Control de seguros tipo CAMPOREE
- [x] Tracking de participación por club

#### Carpetas de Evidencias (Folders/Portfolios)
- [x] Templates de carpetas por tipo de club
- [x] Sistema de módulos y secciones
- [x] Tracking de puntos y progreso
- [x] Almacenamiento de evidencias (JSON)
- [x] Cálculo de porcentaje de completitud

#### Finanzas
- [x] Control de ingresos y egresos por club
- [x] Categorías financieras
- [x] Resúmenes mensuales y anuales
- [x] Reportes por año eclesiástico
- [x] Permisos de tesorero

#### Inventario
- [x] Control de inventario por instancia de club
- [x] Categorías de inventario
- [x] Gestión de cantidades
- [x] Permisos por rol

#### Push Notifications
- [x] Sistema de notificaciones push con FCM
- [x] Gestión de tokens por dispositivo (iOS, Android, Web)
- [x] Envío a usuarios individuales
- [x] Envío masivo a clubs
- [x] Auto-cleanup de tokens expirados

#### WebSockets (Real-time)
- [x] Gateway de WebSockets
- [x] Rooms por club
- [x] Eventos de progreso de clases
- [x] Eventos de actividades
- [x] Autenticación con WsJwtGuard

#### Catálogos
- [x] Países, Uniones, Campos Locales
- [x] Distritos e Iglesias
- [x] Tipos de club e ideales
- [x] Roles y permisos
- [x] Años eclesiásticos
- [x] Relaciones familiares
- [x] Categorías de inventario

#### Seguridad
- [x] Helmet para headers HTTP seguros
- [x] CORS configurado
- [x] Rate limiting (Throttler)
- [x] Validación con class-validator
- [x] Guards personalizados (JWT, Roles, IP Whitelist)

### Frontend Admin (En desarrollo)
- [ ] Dashboard con estadísticas
- [ ] Gestión de clubes y miembros
- [ ] Aprobación de miembros pendientes
- [ ] Asignación de roles
- [ ] Validación de investiduras

### App Móvil (Próximamente)
- [ ] Login y registro
- [ ] Post-registro completo
- [ ] Dashboard principal
- [ ] Perfil de usuario
- [ ] Progreso de clases
- [ ] Listado de honores

## 📖 Documentación

### Documentación de API
- **[API Specification](docs/api/API-SPECIFICATION.md)** - Especificación completa de la API v2.2
- **[Endpoints Reference](docs/api/ENDPOINTS-REFERENCE.md)** - Referencia de 105+ endpoints
- **[Security Guide](docs/api/SECURITY-GUIDE.md)** - Guía de seguridad avanzada
- **[API Versioning](docs/api/API-VERSIONING.md)** - Estrategia de versionamiento

### Walkthroughs
- **[Auth Module](docs/api/walkthrough-auth-module.md)** - Autenticación y autorización
- **[Camporees](docs/api/walkthrough-camporees.md)** - Gestión de campamentos
- **[Security](docs/api/walkthrough-security.md)** - Seguridad avanzada
- **[Catalogs, Clubs & Classes](docs/api/walkthrough-catalogs-clubs-classes.md)** - Catálogos y gestión

### Documentación Técnica
- **[Tech Stack](.specs/_steering/tech.md)** - Stack tecnológico completo
- **[Database Schema](docs/database/SCHEMA-REFERENCE.md)** - 67 modelos de base de datos
- **[Implementation Roadmap](docs/03-IMPLEMENTATION-ROADMAP.md)** - Roadmap de implementación
- **[Architecture Decisions](docs/api/ARCHITECTURE-DECISIONS.md)** - Decisiones de arquitectura

## 🤝 Guidelines de Desarrollo

### Workflow de Git

Cada repositorio es independiente. Para hacer cambios:

1. Trabaja en tu repositorio correspondiente
2. Crea una branch feature: `git checkout -b feature/nombre-feature`
3. Commit con mensajes descriptivos: `git commit -m "feat: descripción"`
4. Push y crea un Pull Request

### Convenciones

- **Commits:** Usar [Conventional Commits](https://www.conventionalcommits.org/)
  - `feat:` - Nueva funcionalidad
  - `fix:` - Corrección de bugs
  - `docs:` - Cambios en documentación
  - `refactor:` - Refactorización de código
  - `test:` - Agregar/modificar tests

## 👥 Equipo

- **Project Lead:** [Tu nombre]
- **Backend:** [Tu nombre]
- **Frontend:** [Tu nombre]
- **Mobile:** [Tu nombre]

## 📄 Licencia

[Definir licencia]

## 📞 Contacto

Para preguntas o colaboración, contacta a [tu email/contacto]

## 📈 Métricas del Proyecto

### Backend (API v2.2)
- **Endpoints REST**: 105+
- **Módulos**: 17
- **Modelos de BD**: 67
- **Tests E2E**: 17 suites
- **Coverage**: 90%+
- **Documentación**: 95%
- **Estado**: ✅ Producción

### Líneas de Código (Aproximado)
- Backend (TypeScript): ~15,000 LOC
- Documentación (Markdown): ~8,000 líneas
- Tests: ~3,000 LOC

---

**Creado:** Enero 2026
**Última actualización:** Febrero 2026
**Versión Backend:** v2.2.0
**Estado:** Fase 1 Completada ✅
