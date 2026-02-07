# 🧪 Guía de Pruebas (Testing) - SACDIA API

**Última actualización**: 2026-02-01

Este documento define la estrategia, herramientas y estándares para el testing en el backend de SACDIA.

---

## 🛠️ Stack Tecnológico

- **Framework**: [Jest](https://jestjs.io/)
- **E2E Testing**: [Supertest](https://github.com/ladjs/supertest)
- **Framework NestJS**: `@nestjs/testing`
- **CI/CD**: GitHub Actions

---

## 🚀 Ejecución de Pruebas

### Comandos Principales

| Comando               | Descripción                                     |
| --------------------- | ----------------------------------------------- |
| `pnpm run test`       | Ejecuta todos los tests unitarios (`*.spec.ts`) |
| `pnpm run test:watch` | Ejecuta tests en modo watch (desarrollo)        |
| `pnpm run test:cov`   | Genera reporte de cobertura (coverage)          |
| `pnpm run test:e2e`   | Ejecuta tests End-to-End (`*.e2e-spec.ts`)      |

### Salida Esperada

```bash
PASS src/catalogs/catalogs.service.spec.ts
PASS src/honors/honors.service.spec.ts
...
Test Suites: 47 passing
Tests:       47 passing
```

---

## 🧩 Test Unitarios

Los tests unitarios se enfocan en probar la lógica de negocio de los `Services` y la lógica de controladores de manera aislada, utilizando **Mocks** para dependencias externas (Prisma, ConfigModule, etc.).

### Ubicación y Naming

- **Ubicación**: Junto al archivo fuente (co-located).
- **Naming**: `nombre-archivo.spec.ts`

### Ejemplo de Mocks (PrismaService)

No conectamos a la BD real en tests unitarios. Mockeamos el servicio:

```typescript
const mockPrismaService = {
  users: {
    findUnique: jest.fn(),
    create: jest.fn(),
  },
};

// En beforeEach
providers: [
  UsersService,
  { provide: PrismaService, useValue: mockPrismaService },
];
```

---

## 🔄 Test End-to-End (E2E)

Los tests E2E verifican el flujo completo de la petición HTTP, desde el Controller hasta la respuesta, pasando por Guards, Interceptors y Pipes.

### Ubicación y Naming

- **Ubicación**: Carpeta `test/` en la raíz.
- **Naming**: `nombre-modulo.e2e-spec.ts`

### Configuración

Utilizan una instancia completa de la aplicación NestJS, pero idealmente conectada a una base de datos de prueba (o mockeada si se prefiere aislamiento total).

```typescript
describe("/api/v1/catalogs/club-types (GET)", () => {
  it("should return list of club types", async () => {
    return request(app.getHttpServer())
      .get("/api/v1/catalogs/club-types")
      .expect(200);
  });
});
```

---

## 🤖 CI/CD Pipeline

Las pruebas se ejecutan automáticamente en cada Push y Pull Request mediante GitHub Actions (`.github/workflows/ci.yml`).

### Pasos del Pipeline de Test

1. **Lint**: Verificación de estilo.
2. **Build**: Verificación de compilación.
3. **Unit Tests**: Ejecución de `pnpm run test --passWithNoTests`.
4. **Coverage**: Reporte de cobertura (opcionalmente subido a Codecov).

---

## 📊 Estado Actual (Sprint 8)

A fecha de Febrero 2026:

- **Cobertura Funcional**:
  - ✅ Catalogs (Unit + E2E)
  - ✅ Honors (Unit + E2E)
  - ✅ Clubs (Unit)
  - ✅ Activities (Unit)
  - ✅ Finances (Unit)
  - ✅ Auth/Users (Unit)

- **Métricas**: ~89% de tests pasando (47/53).
