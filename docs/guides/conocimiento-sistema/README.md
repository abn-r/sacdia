# Concentrado de conocimiento de SACDIA

**Estado**: DRAFT · **Corte inicial**: 2026-09-09 · **Continuación**: 2026-09-14

Material de estudio solicitado por el responsable del proyecto. La presentación
se dirige al director de jóvenes de la Unión Mexicana Interoceánica.
Esta guía explica y conecta fuentes; **no reemplaza el canon ni certifica producción**.
La presentación ejecutiva se congeló el 2026-09-14 (15 láminas) sobre el corte
de evidencia de las fichas 01–13. No certifica producción.

**Dos productos distintos:**

| Material | Uso |
|---|---|
| [Mapa de producto para la iglesia](14-mapa-producto-iglesia.md) | Fuente escrita: cómo queda SACDIA, qué está en código, qué sigue en proceso. |
| [PPTX de venta (19 láminas)](presentacion/entrega/SACDIA-presentacion-venta-iglesia-2026-09-14.pptx) | Presentación para vender el sistema a la iglesia (~25–30 min). |
| [PPTX congelado de 15 láminas](presentacion/README.md) | Recorte prudente de una cita corta. |

## Por dónde empezar

1. [Qué es el sistema y cómo entenderlo](01-fundamentos.md).
2. [Inventario de dominios por investigar](inventario-dominios.md).
3. [Primer flujo: revisión de evidencias](02-revision-evidencias.md).
4. [Mapa interactivo del sistema](diagramas/01-mapa-sistema.html).
5. [Diagrama del flujo de revisión](diagramas/02-revision-evidencias.html).
6. [Roles, permisos y contexto](03-roles-permisos-contexto.md).
7. [Arquitectura técnica](04-arquitectura-tecnica.md): backend y app validados;
   general y panel pendientes de terminar el trazado.
8. [Matriz de roles contrastada con código](05-matriz-roles-verificada.md).
9. [Ingreso inicial](06-ingreso-inicial.md).
10. [Inscripción anual, corte y sucesión](07-inscripcion-anual.md).
11. [Clases progresivas, avance e investidura](08-clases-progresivas.md).
12. [Especialidades (honores), caminos y revisión](09-honores.md).
13. [Certificaciones electivas](10-certificaciones.md).
14. [Camporees: inscripción, aprobación, agenda y evaluación](11-camporees.md).
15. [Supervisión institucional: informes, carpeta anual y tableros](12-supervision-institucional.md).
16. [Operación de la sección (recorte de demo)](13-operacion-seccion.md).
17. [Mapa de producto para la iglesia (fuente de venta)](14-mapa-producto-iglesia.md).
18. [Presentación ejecutiva (15 láminas, congelada)](presentacion/README.md).
19. [Presentación de venta a la iglesia (19 láminas)](presentacion/entrega/SACDIA-presentacion-venta-iglesia-2026-09-14.pptx).

Los diagramas son HTML autónomos: abrir en navegador, sin levantar SACDIA.
El contenido está en español; los controles fijos del visor Archify y su atributo
HTML de idioma usan el fallback inglés. No se publicaron estos materiales.

## Cómo vamos a completar el análisis

Trabajaremos por bloques de negocio, no por carpetas de código. Cada bloque deja
una explicación, fichas de flujos, evidencia y los diagramas que realmente ayuden.

| Orden | Bloque | Pregunta principal | Avance de esta entrega |
|---|---|---|---|
| 1 | Propósito y estructura | ¿Qué administra y cómo se organiza? | Primera síntesis documental |
| 2 | Personas, cargos y permisos | ¿Quién puede hacer qué, dónde y durante qué periodo? | Matriz de acciones críticas contrastada con código/seeds; grants reales pendientes |
| 3 | Ingreso y continuidad | ¿Cómo entra, se inscribe, cambia de sección y continúa una persona? | Ingreso y ciclo anual trazados en código; brechas de UI y negocio explícitas |
| 4 | Formación y reconocimiento | ¿Cómo avanza en clases/honores y quién valida? | Cerrado en fichas 02, 08, 09 y 10 (corte 2026-09-14); no es auditoría de piloto |
| 5 | Operación de la sección | ¿Cómo se administran unidades, actividades, finanzas, seguros e inventario? | Recorte de demo en ficha 13; finanzas/inventario/seguros no profundizados |
| 6 | Eventos y camporees | ¿Cómo se organiza, registra, aprueba y evalúa la participación? | Cerrado en ficha 11 (corte 2026-09-14); pedidos/insumos fuera del demo |
| 7 | Supervisión institucional | ¿Qué se reporta, evalúa y consulta por nivel? | Cerrado en ficha 12 (corte 2026-09-14); rankings solo nombrados |
| 8 | Límites y operación real | ¿Qué está disponible, qué falta y de qué depende? | Guía del expositor + ensayo ficticio; PPTX congelado (15 láminas) |
| 9 | Mapa de venta a la iglesia | ¿Cómo queda el producto completo para venderlo? | [Ficha 14](14-mapa-producto-iglesia.md) + PPTX de 19 láminas; no pisa el deck de 15 |

**Bloques 2 y 3:** cierre analítico del corte 2026-09-14, no auditoría exhaustiva
de permisos ni certificación de producción. **Bloque 4:** cerrado (fichas 02,
08, 09, 10). **Bloque 5:** recorte de demo (ficha 13). **Bloque 6:** cerrado
(ficha 11). **Bloque 7:** cerrado (ficha 12). **Bloque 8:** guía del expositor
y ensayo con cuentas ficticias. **PPTX congelado** (15 láminas, 2026-09-14).
**Bloque 9:** mapa de producto para armar presentaciones de venta (ficha 14).
El ensayo vivo con login queda pendiente de ejecutarse en el entorno ficticio.
No asumir que el cargo institucional del destinatario equivale a un
administrador técnico del sistema.

## Qué debe contener cada ficha de flujo

- Propósito y problema que resuelve.
- Actor que inicia, participantes y responsable de decidir.
- Alcance: persona, sección, club, campo, unión y año, según corresponda.
- Condiciones previas, pasos y datos necesarios.
- Reglas, estados, salidas, rechazos, correcciones y excepciones.
- Permisos y diferencias entre app, panel y backend.
- Beneficio esperado y límites conocidos, sin cifras inventadas.
- Fuentes, fecha de revisión, contradicciones y comprobaciones pendientes.

## Criterio de evidencia

Separar cuatro preguntas en cada capacidad:

1. **Regla de negocio:** qué establece el canon o la definición aprobada.
2. **Contrato documentado:** qué describe la referencia API y el dominio.
3. **Implementación comprobada:** qué se ha contrastado con código y pruebas.
4. **Disponibilidad comprobada:** qué funciona en el entorno y las interfaces a mostrar.

En esta primera entrega se cubren principalmente las dos primeras. No se
ejecutaron pruebas del producto, se accedió a cuentas reales ni se comprobó un
despliegue. Un endpoint existente no demuestra que el recorrido completo esté
disponible en app/panel. Los datos de prueba posteriores serán ficticios.

Para discrepancias, seguir [la autoridad documental](../../canon/source-of-truth.md).
Registrar el conflicto y no mezclar versiones. Los hashes de las fuentes leídas
están en [el corte de fuentes](evidencias/fuentes.json); algunos documentos tenían
cambios locales previos, por lo que el commit del workspace por sí solo no basta.
La revisión al retomar se guarda por separado en `evidencias/fuentes-2026-09-10.json`;
no se sobrescribe el corte inicial. Ver [verificación de los diagramas](evidencias/VERIFICACION.md).

## Archify en este workspace

- Origen: <https://github.com/tt-a1i/archify> · licencia MIT.
- Instalación local: `.agents/skills/archify`; no es dependencia de SACDIA.
- Versión: `2.17.0-dev.1`, fijada al commit `10722002bb8777ecb639d93c49586fae4adf3ae4`.
- Se instaló la skill con el instalador oficial de Codex. Estará disponible para
  detección automática desde el siguiente turno; su CLI ya se usó aquí.
- No se ejecutó `npm install`, builds del producto ni cambios en `.env`.
- Comprobaciones de actualización desactivadas mediante variable de proceso;
  no se cambió la configuración global ni se enviaron fuentes a Archify remoto.
- Los JSON son editables; los HTML se regeneran, no se editan a mano.

Desde la raíz del workspace, para validar y regenerar el mapa:

```sh
ARCHIFY_UPDATE_CHECK_DISABLED=1 node .agents/skills/archify/bin/archify.mjs validate architecture docs/guides/conocimiento-sistema/diagramas/01-mapa-sistema.architecture.json --quality showcase --json
ARCHIFY_UPDATE_CHECK_DISABLED=1 node .agents/skills/archify/bin/archify.mjs deliver architecture docs/guides/conocimiento-sistema/diagramas/01-mapa-sistema.architecture.json docs/guides/conocimiento-sistema/diagramas/01-mapa-sistema.html --quality showcase --json
```

Para el segundo diagrama, usar `workflow` y `02-revision-evidencias.workflow.json`.
Después de cada regeneración, ejecutar `visual-check` sobre el HTML y revisar las
imágenes. Los recibos separan validación estructural, navegador y revisión visual.

La versión fijada es de desarrollo: ofrece reproducibilidad, no una garantía de
estabilidad. Su uso queda aislado al material de conocimiento. No se instalaron
actualizaciones automáticas ni un servicio permanente.
