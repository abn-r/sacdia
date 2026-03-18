# Gobernanza del canon

## Estado

ACTIVE

## Propósito

La gobernanza del canon define cómo se mantiene la verdad documental de SACDIA. Su función es evitar autoridad dispersa, contradicciones entre documentos y acumulación de material que compite por interpretar el sistema.

## Principio rector

El canon de SACDIA debe ser:

- mínimo: solo conserva verdad estructural y vigente;
- normativo: disciplina lenguaje, interpretación y precedencia;
- explícito: separa canon, operación, trabajo e historia sin ambigüedad.

## Planos documentales

La documentación del sistema se divide en cuatro planos:

- canon: verdad vigente y normativa;
- operación: documentación técnica u operativa subordinada al canon;
- trabajo: exploración, diseño, transición o planeación;
- historia: contexto preservado sin autoridad vigente.

Estos planos no deben competir entre sí ni presentarse como si tuvieran la misma autoridad.

## Canon mínimo

El canon base de SACDIA se compone de seis documentos:

- `docs/canon/dominio-sacdia.md`;
- `docs/canon/identidad-sacdia.md`;
- `docs/canon/gobernanza-canon.md`;
- arquitectura del sistema;
- runtime vigente;
- decisiones clave.

Todo lo demás debe existir como derivado, subordinado o histórico.

## Precedencia

La precedencia del canon se interpreta así:

- la gobernanza del canon manda en reglas documentales y resolución de conflictos;
- el modelo del dominio manda en lenguaje, semántica y conceptos;
- la identidad del sistema manda en propósito, alcance y frontera;
- la arquitectura del sistema manda en organización técnica y responsabilidades;
- el runtime vigente manda en verdad operativa actual, sin redefinir semántica;
- las decisiones clave conservan memoria estructural, pero no reemplazan documentos normativos.

## Resolución de contradicciones

Cuando dos documentos parecen contradecirse:

1. se identifica qué tipo de verdad expresa cada uno;
2. se aplica precedencia, no intuición;
3. si el conflicto es semántico, manda el modelo del dominio;
4. si el conflicto es de propósito o frontera, manda la identidad del sistema;
5. si el conflicto es operativo, manda el runtime vigente, subordinado al dominio;
6. si el conflicto involucra material histórico, el histórico nunca redefine el presente.

## Estados documentales

Los estados permitidos son:

- `ACTIVE`: documento vigente;
- `DRAFT`: documento en construcción;
- `DEPRECATED`: documento reemplazado;
- `HISTORICAL`: documento preservado por contexto.

No deben inventarse estados paralelos para representar pendiente, futuro o aspiración.

## Regla de creación

Un documento nuevo solo debe existir si:

- fija una verdad no cubierta por otro documento canónico;
- responde una pregunta estructural recurrente;
- reduce ambigüedad real del sistema;
- evita que una decisión importante quede disuelta en material táctico o histórico.

No debe crearse un documento si:

- duplica semántica ya fijada;
- resume otro documento sin agregar autoridad;
- mezcla vigente, aspiracional e histórico;
- existe solo para llenar una carpeta.

## Regla de absorción

Cuando nace un documento canónico nuevo:

- absorbe la verdad vigente del tema;
- desplaza los documentos anteriores a rol subordinado;
- obliga a marcar el material viejo como `DEPRECATED` o `HISTORICAL` cuando corresponda.

Lo viejo puede quedarse. Lo que no puede hacer es seguir mandando.

## Regla de mantenimiento

- si cambia el lenguaje del negocio, se actualiza `docs/canon/dominio-sacdia.md`;
- si cambia propósito o frontera, se actualiza `docs/canon/identidad-sacdia.md`;
- si cambia estructura técnica, se actualiza el documento de arquitectura del sistema;
- si cambia la realidad implementada, se actualiza el documento de runtime vigente;
- si cambia una decisión estructural, se registra en decisiones clave;
- si cambia la disciplina documental, se actualiza `docs/canon/gobernanza-canon.md`.

## Regla de lenguaje

Ningún documento fuera del canon puede redefinir términos canónicos. Si una API, tabla o interfaz usa otro nombre, debe mapearse explícitamente al vocabulario del dominio.

## Regla de historia

La historia existe para conservar contexto, no para competir con el presente. Un documento histórico puede explicar cómo se llegó a algo, pero nunca debe actuar como contrato vigente.

## Regla de aspiración

Lo futuro o no implementado debe marcarse como pendiente o en transición dentro del documento correspondiente. No puede presentarse como si ya formara parte del runtime vigente.

## Cierre

La gobernanza del canon existe para que la documentación de SACDIA funcione como sistema y no como archivo muerto: pocas piezas, roles claros, precedencia explícita y separación estricta entre verdad vigente, operación, trabajo e historia.
