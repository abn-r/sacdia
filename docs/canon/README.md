# Canon Documentation

## Estado
ACTIVE

## Propósito
Esta carpeta contiene la capa documental canónica y activa del proyecto.

Su objetivo es reducir contradicciones entre documentos históricos, walkthroughs, notas de implementación y contratos realmente vigentes.

Acá debe vivir la fuente de verdad operativa para dominios, runtime y procesos clave.

## Regla principal
Si un documento dentro de `docs/canon/` contradice un documento fuera de esta carpeta, manda `docs/canon/`.

Los documentos fuera de `docs/canon/` pueden seguir existiendo como referencia, contexto histórico o evidencia de implementación, pero no redefinen el contrato activo.

## Qué debe vivir en esta carpeta
En `docs/canon/` solo deben vivir documentos que cumplan al menos una de estas funciones:

- definir el lenguaje y límites de un dominio;
- definir el comportamiento técnico vigente de un área;
- definir procesos operativos canónicos;
- mapear la relación entre documentos canónicos y documentos legacy.

## Qué no debe vivir en esta carpeta
No deben vivir acá:

- walkthroughs históricos;
- notas exploratorias sin validar;
- planes temporales de implementación;
- bitácoras de sesión;
- documentación duplicada cuyo contrato activo ya exista en otro documento canónico.

## Precedencia dentro de la capa canónica
Orden de autoridad actual:

1. `gobernanza-canon.md`
2. `dominio-sacdia.md`
3. `identidad-sacdia.md`
4. `arquitectura-sacdia.md`
5. `runtime-sacdia.md`
6. `decisiones-clave.md`

Semántica:
- `gobernanza-canon.md` manda en precedencia y reglas documentales;
- `dominio-sacdia.md` manda en lenguaje, conceptos y semántica del sistema;
- `identidad-sacdia.md` manda en propósito, alcance y frontera;
- `arquitectura-sacdia.md` manda en organización técnica y responsabilidades;
- `runtime-sacdia.md` manda en verdad operativa actual, subordinada al dominio;
- `decisiones-clave.md` conserva memoria estructural y justificación.

## Resolución de conflictos
Si aparece una contradicción:

1. se prioriza el documento canónico más específico dentro de `docs/canon/`;
2. si la contradicción es entre dominio y runtime:
   - `dominio-*.md` manda en intención y semántica del negocio;
   - `runtime-*.md` manda en comportamiento técnico vigente;
3. si la contradicción es con documentación legacy, el documento legacy debe marcarse como `DEPRECATED` o `HISTORICAL`.

## Estados permitidos
Cada documento canónico debe declarar uno de estos estados:

- `ACTIVE` — documento vigente y operativo;
- `DRAFT` — documento en construcción, todavía no definitivo;
- `DEPRECATED` — documento reemplazado por otro canónico;
- `HISTORICAL` — documento preservado por contexto, pero no vigente.

## Convención editorial para futuro y pendientes
- No inventar estados nuevos como `future`, `planned` o `pending`.
- Si un documento sigue siendo canónico, mantener `ACTIVE` y marcar dentro del texto lo que esté `Pendiente`, `Por definir`, `Por verificar` o `Planificado`.
- No presentar como vigente algo que todavía no existe en runtime.

## Estructura actual recomendada
```text
docs/
  canon/
    README.md
    dominio-sacdia.md
    identidad-sacdia.md
    gobernanza-canon.md
    arquitectura-sacdia.md
    runtime-sacdia.md
    decisiones-clave.md
    auth/
      modelo-autorizacion.md
      runtime-auth.md
```

## Documentos canónicos actuales

### `dominio-sacdia.md`

Define el lenguaje oficial, los conceptos centrales, las reglas semánticas, los invariantes y las tensiones del dominio.

### `identidad-sacdia.md`

Define propósito, problema, actores, frontera y criterio rector del sistema.

### `gobernanza-canon.md`

Define planos documentales, precedencia, resolución de contradicciones, estados y reglas de mantenimiento del canon.

### `arquitectura-sacdia.md`

Traduce el dominio a una organización técnica coherente para backend, admin web, app móvil, datos e integraciones.

### `runtime-sacdia.md`

Describe la verdad operativa actual del sistema. Mientras no termine su verificación contra código, permanece en estado `DRAFT`.

### `decisiones-clave.md`

Conserva la memoria estructural de las decisiones que fijan interpretación, organización y evolución del sistema.

## Convenciones de nombres
- `<area>.md` o `<tema>.md` — documento canónico cuando el nombre exacto comunica mejor su rol sistémico;
- `dominio-<area>.md` — definición funcional y semántica de un dominio específico;
- `modelo-<tema>.md` — decisión conceptual canónica cuando un tema necesita más profundidad que dominio o runtime;
- `runtime-<area>.md` — comportamiento técnico vigente;
- `procesos-<area>.md` — flujos operativos canónicos;
- `legacy-map.md` — mapa de reemplazo documental cuando haga falta cortar autoridad a material viejo.

## Cómo migrar documentación existente
La migración no se hace borrando todo. Se hace así:

1. crear el documento canónico nuevo;
2. declararlo `ACTIVE` cuando ya sea la fuente de verdad;
3. identificar documentos anteriores relacionados;
4. marcar esos documentos anteriores como `DEPRECATED` o `HISTORICAL`;
5. agregar en los documentos anteriores una línea visible con el reemplazo activo.

Ejemplo:

```md
## Estado
DEPRECATED

Reemplazado por: `docs/canon/dominio-sacdia.md`
```

## Regla editorial mínima antes de crear un documento nuevo
Antes de agregar un documento en esta capa, verificar:

- si ya existe otro documento canónico que cubra ese tema;
- si el nuevo documento corresponde a dominio, runtime o proceso;
- si agrega claridad real o solo duplica contenido existente.

## Criterio de calidad mínimo
Un documento canónico debe:

- declarar su propósito;
- declarar su estado;
- no contradecir otros documentos canónicos;
- distinguir claramente entre estado actual y decisiones futuras;
- permitir que otro dev o IA continúe el trabajo sin reinventar el contexto.
