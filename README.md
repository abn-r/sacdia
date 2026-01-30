# SACDIA - Sistema de Administración de Clubes de Conquistadores y JDVA

Sistema integral de gestión para clubes de Conquistadores, Aventureros y JDVA, desarrollado con arquitectura moderna y escalable.

## 📋 Descripción

SACDIA es una plataforma completa que permite administrar:

- Clubes de Conquistadores y Aventureros
- Inscripciones anuales y períodos de membresía
- Gestión de miembros, directores y padres
- Sistema de investidura y certificaciones
- Seguros y gestión financiera
- Eventos y actividades

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
- **Auth:** Supabase Auth
- **Validation:** Zod

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

## 📖 Documentación

- **[Tech Stack](.specs/_steering/tech.md)** - Stack tecnológico completo
- **[Database Schema](docs/database/schema.prisma)** - Schema de base de datos
- **[API Documentation](docs/api/)** - Documentación de endpoints
- **[Product Requirements](docs/product.md)** - Requerimientos del producto

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

---

**Última actualización:** Enero 2026
