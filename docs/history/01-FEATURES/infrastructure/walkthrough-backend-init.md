# Walkthrough: Inicialización Backend SACDIA

**Fecha**: 29 de enero de 2026  
**Duración**: ~20 minutos

---

## ✅ Completado

### 1. Creación del Proyecto NestJS

```bash
npx @nestjs/cli new sacdia-backend --package-manager pnpm
```

**Resultado**:
- ✅ Proyecto creado en `/Users/abner/Documents/dev/sacdia/sacdia-backend`
- ✅ Estructura básica de NestJS inicializada
- ✅ Dependencias base instaladas con pnpm

---

### 2. Instalación de Dependencias

```bash
cd sacdia-backend
pnpm install @nestjs/config @nestjs/swagger @prisma/client
pnpm install -D prisma
```

**Dependencias instaladas**:
- `@nestjs/config` - Configuración de variables de entorno
- `@nestjs/swagger` - Documentación automática de API
- `@prisma/client` - Cliente Prisma para acceso a BD
- `prisma` (dev) - CLI de Prisma

---

### 3. Inicialización de Prisma

```bash
npx prisma init
```

**Resultado**:
- ✅ Carpeta `prisma/` creada
- ✅ Archivo `prisma/schema.prisma` generado (vacío)
- ✅ Archivo `.env` creado con template
- ✅ Archivo `prisma.config.ts` generado

---

### 4. Copia de Schema Actualizado

```bash
cp ../docs/03-DATABASE/schema.prisma prisma/schema.prisma
```

**Schema incluye**:
- ✅ `users` con `maternal_last_name` (renombrado de `mother_last_name`)
- ✅ `users_pr` con tracking granular (3 campos nuevos)
- ✅ `club_role_assignments` con campo `status`
- ✅ Tabla nueva: `relationship_types`
- ✅ Tabla nueva: `legal_representatives`
- ✅ `role_category` enum (GLOBAL, CLUB)
- ✅ Todas las relaciones bidireccionales configuradas

---

### 5. Configuración de Variables de Entorno

```env
DATABASE_URL="postgresql://postgres.[ref]:***@aws-0-us-east-1.pooler.supabase.com:5432/postgres"
```

**Configurado por usuario** ✅

---

### 6. Aplicación de Migration

```bash
npx prisma migrate dev --name initial_schema_v2
```

**Resultado**:
```
✅ Migration aplicada: 20260129232837_initial_schema_v2
✅ Tablas creadas en Supabase
✅ Índices y constraints aplicados
✅ Enums creados
```

**Tablas creadas** (60+ total):
- `users` (con campos actualizados)
- `users_pr` (con tracking)
- `club_role_assignments` (con status)
- `legal_representatives` ✨ NUEVO
- `relationship_types` ✨ NUEVO
- `roles` (con role_category)
- `club_adventurers`, `club_pathfinders`, `club_master_guild`
- `emergency_contacts`
- `classes`, `enrollments`, `certifications`
- `member_insurances`, `investiture_*`
- Y todas las demás...

---

### 7. Generación de Cliente Prisma

```bash
npx prisma generate
```

**Resultado**:
```
✅ Prisma Client generado en node_modules/@prisma/client
✅ Tipos TypeScript generados
✅ Listo para usar en NestJS
```

---

## 📁 Estructura Final del Proyecto

```
sacdia-backend/
├── prisma/
│   ├── schema.prisma              ✅ Schema completo V2
│   ├── migrations/
│   │   └── 20260129232837_initial_schema_v2/
│   │       └── migration.sql      ✅ 1629 líneas SQL
│   └── prisma.config.ts
├── src/
│   ├── app.controller.ts
│   ├── app.module.ts
│   ├── app.service.ts
│   └── main.ts
├── .env                           ✅ DATABASE_URL configurado
├── .env.example                   ✅ Template creado
├── package.json
├── tsconfig.json
└── nest-cli.json
```

---

## 🎯 Tablas V2 - Decisiones Finales

### users
```sql
- name VARCHAR(50)
- paternal_last_name VARCHAR(50)
- maternal_last_name VARCHAR(50)  ✅ RENOMBRADO
- email VARCHAR(100)
- gender VARCHAR
- birthday DATE
- blood blood_type ENUM
- baptism BOOLEAN
- baptism_date DATE
```

### users_pr (Post-Registro Tracking)
```sql
- user_id UUID UNIQUE
- complete BOOLEAN
- profile_picture_complete BOOLEAN  ✅ NUEVO
- personal_info_complete BOOLEAN    ✅ NUEVO
- club_selection_complete BOOLEAN   ✅ NUEVO
```

### club_role_assignments
```sql
- user_id UUID
- role_id UUID
- club_adv_id INT?
- club_pathf_id INT?
- club_mg_id INT?
- ecclesiastical_year_id INT        ✅ YA EXISTÍA
- start_date DATE
- end_date DATE?                    ✅ AHORA OPCIONAL
- status VARCHAR(20)                ✅ NUEVO ('pending', 'active', 'inactive')
- active BOOLEAN
```

### legal_representatives ✨ NUEVA
```sql
- id UUID PRIMARY KEY
- user_id UUID UNIQUE                           -- Máximo 1 por usuario
- representative_user_id UUID?                   -- Opción 1: Usuario registrado
- name VARCHAR(100)?                            -- Opción 2: Solo datos
- paternal_last_name VARCHAR(100)?
- maternal_last_name VARCHAR(100)?
- phone VARCHAR(20)?
- relationship_type_id UUID?
```

### relationship_types ✨ NUEVA
```sql
- relationship_type_id UUID PRIMARY KEY
- name VARCHAR(50) UNIQUE
- description TEXT
- active BOOLEAN
```

**Seed de datos**:
- Padre
- Madre
- Tutor Legal
- Abuelo/a
- Tío/a
- Otro

### roles (con role_category)
```sql
- role_id UUID
- role_name VARCHAR(255)
- role_category role_category ENUM  ✅ 'GLOBAL' | 'CLUB'
- active BOOLEAN
```

---

## 🔍 Verificación

### En Supabase

1. Ve a **Table Editor**
2. Verifica tablas creadas:
   - ✅ `users` tiene `maternal_last_name`
   - ✅ `users_pr` tiene 3 campos de tracking
   - ✅ `club_role_assignments` tiene campo `status`
   - ✅ `legal_representatives` existe
   - ✅ `relationship_types` existe

3. Ejecuta query de prueba:
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users_pr';

-- Debe mostrar:
-- user_id
-- complete
-- profile_picture_complete  ✅
-- personal_info_complete    ✅
-- club_selection_complete   ✅
```

---

## 🚀 Próximos Pasos Recomendados

### 1. Crear Servicio Prisma (Reusable)

```bash
cd sacdia-backend
nest g module prisma
nest g service prisma
```

**`src/prisma/prisma.service.ts`**:
```typescript
import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
```

**`src/prisma/prisma.module.ts`**:
```typescript
import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
```

---

### 2. Configurar Variables de Entorno

**`src/app.module.ts`**:
```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    PrismaModule,
  ],
})
export class AppModule {}
```

---

### 3. Seed de Datos Iniciales

Crear `prisma/seed.ts`:
```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Seed relationship_types
  await prisma.relationship_types.createMany({
    data: [
      { name: 'Padre', description: 'Padre biológico o adoptivo' },
      { name: 'Madre', description: 'Madre biológica o adoptiva' },
      { name: 'Tutor Legal', description: 'Tutor legal asignado' },
      // ... más
    ],
    skipDuplicates: true,
  });

  // Seed roles
  await prisma.roles.createMany({
    data: [
      { role_name: 'super_admin', role_category: 'GLOBAL', active: true },
      { role_name: 'user', role_category: 'GLOBAL', active: true },
      { role_name: 'member', role_category: 'CLUB', active: true },
      { role_name: 'director', role_category: 'CLUB', active: true },
      // ... más
    ],
    skipDuplicates: true,
  });

  console.log('✅ Seed completed');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

Ejecutar:
```bash
npx tsx prisma/seed.ts
```

---

### 4. Crear Módulos de Negocio

```bash
# Auth Module
nest g module auth
nest g service auth
nest g controller auth

# Users Module
nest g module users
nest g service users
nest g controller users

# Clubs Module
nest g module clubs
nest g service clubs
nest g controller clubs
```

---

### 5. Configurar Swagger

**`src/main.ts`**:
```typescript
import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Swagger
  const config = new DocumentBuilder()
    .setTitle('SACDIA API')
    .setDescription('API REST para SACDIA v2')
    .setVersion('2.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  await app.listen(3000);
  console.log(`🚀 Server running on http://localhost:3000`);
  console.log(`📖 Swagger docs on http://localhost:3000/api`);
}
bootstrap();
```

---

## ✅ Checklist de Validación

- [x] Proyecto NestJS creado
- [x] Dependencias instaladas
- [x] Prisma inicializado
- [x] Schema V2 copiado
- [x] DATABASE_URL configurado
- [x] Migration aplicada a Supabase
- [x] Cliente Prisma generado
- [ ] PrismaService creado
- [ ] Seed de datos ejecutado
- [ ] Módulos de negocio creados
- [ ] Swagger configurado

---

## 🎉 Resumen

**Tiempo total**: ~20 minutos  
**Líneas de SQL generadas**: 1,629  
**Tablas creadas**: 60+ 
**Tablas nuevas V2**: 2 (`legal_representatives`, `relationship_types`)  
**Campos actualizados**: 7  

**Base de datos lista para**:
✅ Registro y autenticación  
✅ Post-registro con tracking granular  
✅ Gestión de clubes con roles  
✅ Representantes legales para menores  
✅ Sistema de permisos (GLOBAL/CLUB)  
✅ Clases y certificaciones  
✅ Seguros e investidura  

---

**Estado**: ✅ BACKEND LISTO PARA DESARROLLO
