# Ensayo con cuentas ficticias

**Propósito:** probar el discurso y el entorno **antes** de la cita.  
**Datos:** solo cuentas y clubes de ensayo. Nada de producción UMI.  
**Corte:** 2026-09-14. Este archivo es el guion; **no** se ejecutó aquí un
login real.

Si un paso falla, se anota. No se inventa el resultado en la cita.

## Cuentas (nombres de rol, no personas reales)

| Alias | Rol a ensayar | Para qué |
|---|---|---|
| U1 | `director-union` | Tablero operativo, informes, carpeta (confirmación) |
| C1 | Director de **una** sección CQ ficticia | Ingreso pendiente, inscripción anual, miembros |
| R1 | Revisor (`coordinator` o quien tenga `validation:review`) | Evidencia de clase u honor |
| Opcional J1 | Juez `primary` | Solo si hay camporee con clubes **cerrados** |

No usar `admin` / `super-admin` como si fueran el cargo del destinatario.

## Antes de empezar (checklist)

- [ ] Año eclesiástico vigente visible
- [ ] Sección ficticia activa (ej. “Panteras · Conquistadores”)
- [ ] Al menos un membership `pending` o un no inscrito del año
- [ ] Una evidencia de clase o especialidad lista para revisar
- [ ] Flag `field_payment_orders_v1` del campo demo: **ON u OFF**, anotado
- [ ] Si se muestra camporee: hay uno publicado; tipo CQ incluido
- [ ] Si se muestra carpeta: hay sección `PREAPPROVED_LF` **o** se omite
      confirmación
- [ ] Conectividad app + panel + API del entorno de ensayo

Sin esto, recortar el guion. No improvisar scoring ni confirm-union.

## Recorrido A — núcleo (~8 min de demo viva)

El deck ya explicó el concepto. Aquí se **enseña** una vez cada acto.

1. **App, persona nueva (o captura previa):** wizard hasta membresía
   pendiente. Decir: aún no está activa. Clase no es combo libre.
2. **App o panel, C1:** aprobar la solicitud (o mostrar una ya pendiente).
3. **App, C1:** no inscritos del año → inscribir **uno**. Leer el outcome
   (`enrolled` / `already_enrolled` / `blocked`). No autoinscripción.
4. **App, miembro o consejero:** un requisito con archivo. Decir: esto
   todavía no es investidura.
5. **R1:** aprobar o rechazar **esa** evidencia. Decir: un archivo no
   cierra la clase.

Parar aquí si el tiempo o el entorno fallan.

## Recorrido B — Unión (~4 min, solo si A salió)

Con **U1** en panel:

1. `/dashboard`: club operativo ≠ club activo del catálogo. Cobertura de
   informes: si sale `not_applicable`, explicarlo (mes no cerrado).
2. Supervisión de informes: un PDF `submitted`. **No hay aprobar.**
3. `/dashboard/annual-folders`: si hay `PREAPPROVED_LF`, mostrar dónde
   confirmaría Unión. Si no hay, decirlo y no inventar.
4. **No abrir SLA.** Si alguien lo pide: “esa vista no es de este cargo”.

## Recorrido C — camporee (opcional, 3 min)

Solo con camporee publicado y C1 = **director** de la sección activa.

1. Inscribir la **sección**. Decir: todavía no hay personas.
2. Personas: según flag ON/OFF (orden vs register). Seguro visible.
3. **No** cerrar clubes ni puntuar salvo ensayo previo en verde.

Coordinador no es el aprobador. No mezclar camporee local y de unión.

## Recorrido D — operación de sección (solo si sobra tiempo)

Lista de miembros → una unidad → una actividad. Frase: “grupo de trabajo,
no la clase; actividad registrada no es camporee”. Ficha 13.

## Fallos que ya se conocen (no sorprenderse)

| Síntoma | Qué decir | Fuente |
|---|---|---|
| Subdirector no inscribe camporee | Solo el director de la sección activa | Ficha 11 |
| `FIELD_PAYMENT_ORDER_LEGACY_DISABLED` | Flag ON: hay que pagar con orden | Ficha 11 |
| Submit de informe en `draft` | Falta generar/congelar | Ficha 12 |
| 403 SLA con U1 | Esperado | Ficha 12 |
| App coordinador: evidencias en 0 | Mapeo desfasado vs API | Ficha 12 |
| Clase sugerida en anual y POST error | La UI puede ofrecer una clase bloqueada | Ficha 07 / lámina 09 |

Anotar aquí fallos **nuevos** del ensayo real (fecha, cuenta, pantalla,
código):

| Fecha | Cuenta | Qué pasó | ¿Se muestra en la cita? |
|---|---|---|---|
| | | | |

## Después del ensayo

- Recortar el piloto de la lámina 14 a lo que **sí** funcionó.
- No ampliar a finanzas/inventario/ranking para “llenar tiempo”.
- Congelado el PPTX: los fallos se corrigen en entorno o se sacan del
  demo; no se regenera el deck por un bug de datos.
