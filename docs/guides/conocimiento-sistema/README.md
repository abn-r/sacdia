# Concentrado de conocimiento de SACDIA

**Estado**: DRAFT · **Corte inicial**: 2026-09-09 · **Continuación**: 2026-09-10

Material de estudio solicitado por el responsable del proyecto. La presentación
al director de jóvenes de la Unión Mexicana Interoceánica se preparará después.
Esta guía explica y conecta fuentes; **no reemplaza el canon ni certifica producción**.

## Por dónde empezar

1. [Qué es el sistema y cómo entenderlo](01-fundamentos.md).
2. [Inventario de dominios por investigar](inventario-dominios.md).
3. [Primer flujo: revisión de evidencias](02-revision-evidencias.md).
4. [Mapa interactivo del sistema](diagramas/01-mapa-sistema.html).
5. [Diagrama del flujo de revisión](diagramas/02-revision-evidencias.html).
6. [Roles, permisos y contexto](03-roles-permisos-contexto.md).

Los diagramas son HTML autónomos: abrir en navegador, sin levantar SACDIA.
El contenido está en español; los controles fijos del visor Archify y su atributo
HTML de idioma usan el fallback inglés. No se publicaron estos materiales.

## Cómo vamos a completar el análisis

Trabajaremos por bloques de negocio, no por carpetas de código. Cada bloque deja
una explicación, fichas de flujos, evidencia y los diagramas que realmente ayuden.

| Orden | Bloque | Pregunta principal | Avance de esta entrega |
|---|---|---|---|
| 1 | Propósito y estructura | ¿Qué administra y cómo se organiza? | Primera síntesis documental |
| 2 | Personas, cargos y permisos | ¿Quién puede hacer qué, dónde y durante qué periodo? | Capítulo documental y ejemplos; matriz exacta pendiente |
| 3 | Ingreso y continuidad | ¿Cómo entra, se inscribe, cambia de sección y continúa una persona? | Pendiente; cambio anual en conciliación |
| 4 | Formación y reconocimiento | ¿Cómo avanza en clases/honores y quién valida? | Un flujo documental de evidencias; resto pendiente |
| 5 | Operación de la sección | ¿Cómo se administran unidades, actividades, finanzas, seguros e inventario? | Inventariado, sin análisis detallado |
| 6 | Eventos y camporees | ¿Cómo se organiza, registra, aprueba y evalúa la participación? | Inventariado, sin análisis detallado |
| 7 | Supervisión institucional | ¿Qué se reporta, evalúa y consulta por nivel? | Inventariado, sin análisis detallado |
| 8 | Límites y operación real | ¿Qué está disponible, qué falta y de qué depende? | Registro inicial de incertidumbres |

**Próximo bloque:** cerrar la matriz de roles y verificar el ciclo de ingreso e
inscripción anual. No asumir que el cargo institucional del
destinatario equivale a un administrador técnico del sistema.

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
