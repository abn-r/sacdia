-- ==========================================================================
-- Seed: Guía Mayor (class_id = 13) — Módulos y Secciones
-- Fuente: Manual Guías Mayores 2018
-- Fecha: 2026-03-24
-- Encoding: UTF-8
-- Idempotente: usa ON CONFLICT DO NOTHING
-- ==========================================================================
BEGIN;

-- ============================================================
-- Módulo 1 — Prerrequisitos
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Prerrequisitos', 'Sección I — Prerrequisitos', 13, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Prerrequisitos' AND class_id = 13
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Ser un miembro bautizado, fiel y en regla de la Iglesia Adventista del Séptimo Día', NULL::TEXT),
  ('Tener una recomendación por escrito de su Junta Directiva Local', NULL::TEXT),
  ('Tener por lo menos 16 años de edad al comenzar el programa de Guía Mayor y por lo menos 18 años de edad en la investidura', NULL::TEXT),
  ('Ser un miembro activo del personal (Directiva) de un Club de Aventureros o de Conquistadores', NULL::TEXT),
  ('Completar el Curso Básico de Capacitación para Consejeros y participar por un mínimo de un año en uno de los siguientes ministerios', 'Seleccionar uno de los siguientes ministerios'),
  ('Ministerio de los Aventureros', 'Sub-requisito de: Completar el Curso Básico de Capacitación para Consejeros'),
  ('Ministerio de los Conquistadores', 'Sub-requisito de: Completar el Curso Básico de Capacitación para Consejeros')
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 2 — Desarrollo espiritual
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Desarrollo espiritual', 'Sección II — Desarrollo espiritual', 13, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Desarrollo espiritual' AND class_id = 13
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Leer o escuchar el libro ''El Camino a Cristo'' y presentar una reacción de una página centrada en los beneficios de la lectura', NULL::TEXT),
  ('Completar la guía devocional ''Serie Encuentro I, Cristo el Camino'', o completar otro plan de lectura bíblica de un año que cubra los cuatro evangelios', NULL::TEXT),
  ('Leer o escuchar el libro ''El Deseado de Todas las Gentes''', NULL::TEXT),
  ('Realizar una de las siguientes acciones', 'Seleccionar una de las siguientes opciones'),
  ('Mantener un diario devocional de estudio y oración por un mínimo de cuatro semanas', 'Sub-requisito de: Realizar una de las siguientes acciones'),
  ('Completar los requisitos del programa espiritual ''Pasos para el Discipulado''', 'Sub-requisito de: Realizar una de las siguientes acciones'),
  ('Participar en uno o más eventos de evangelismo o de servicio a la comunidad basados en alcanzar a la gente', NULL::TEXT),
  ('Preparar un resumen de una página de cada una de las 28 Creencias Fundamentales, en formato de viñetas', NULL::TEXT),
  ('Desarrollar y hacer una presentación sobre cuatro de las siguientes creencias, haciendo uso de ayudas visuales si es posible', 'Seleccionar cuatro de las siguientes creencias'),
  ('La Creación', 'Sub-requisito de: Presentación sobre creencias fundamentales'),
  ('La Experiencia de la Salvación', 'Sub-requisito de: Presentación sobre creencias fundamentales'),
  ('Creciendo en Cristo', 'Sub-requisito de: Presentación sobre creencias fundamentales'),
  ('El Remanente y su Misión', 'Sub-requisito de: Presentación sobre creencias fundamentales'),
  ('El Bautismo', 'Sub-requisito de: Presentación sobre creencias fundamentales'),
  ('Dones y Ministerios Espirituales', 'Sub-requisito de: Presentación sobre creencias fundamentales'),
  ('El Don de Profecía', 'Sub-requisito de: Presentación sobre creencias fundamentales'),
  ('El Sábado', 'Sub-requisito de: Presentación sobre creencias fundamentales'),
  ('El Ministerio de Cristo en el Santuario Celestial', 'Sub-requisito de: Presentación sobre creencias fundamentales'),
  ('La Segunda Venida de Cristo', 'Sub-requisito de: Presentación sobre creencias fundamentales'),
  ('Muerte y Resurrección', 'Sub-requisito de: Presentación sobre creencias fundamentales'),
  ('Mejorar su conocimiento sobre Historia Denominacional completando lo siguiente', 'Completar todos los siguientes requisitos'),
  ('Obtener la especialidad de ''Herencia de los Pioneros a Adventistas''', 'Sub-requisito de: Historia Denominacional'),
  ('Leer un libro publicado por la Iglesia Adventista del Séptimo Día sobre conquistadores/herencia denominacional', 'Sub-requisito de: Historia Denominacional'),
  ('Leer un libro sobre la herencia de la iglesia', 'Sub-requisito de: Historia Denominacional'),
  ('Completar un trabajo de investigación de al menos dos páginas sobre un análisis del temperamento y completar un test sobre el temperamento', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 3 — Desarrollo de habilidades
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Desarrollo de habilidades', 'Sección III — Desarrollo de habilidades', 13, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Desarrollo de habilidades' AND class_id = 13
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Asistir y completar los requisitos del seminario en cada uno de los siguientes 12 temas', 'Completar todos los siguientes seminarios'),
  ('Cómo ser un líder cristiano', 'Sub-requisito de: Seminarios requeridos'),
  ('Visión, misión y motivación', 'Sub-requisito de: Seminarios requeridos'),
  ('Manejo de riesgos en el Ministerio de Aventureros y Conquistadores', 'Sub-requisito de: Seminarios requeridos'),
  ('Disciplina', 'Sub-requisito de: Seminarios requeridos'),
  ('Teoría de la comunicación y habilidades para escuchar', 'Sub-requisito de: Seminarios requeridos'),
  ('Entrenamiento en comunicación práctica', 'Sub-requisito de: Seminarios requeridos'),
  ('Entendiendo y enseñando los estilos de aprendizaje', 'Sub-requisito de: Seminarios requeridos'),
  ('Cómo preparar la adoración creativa efectiva', 'Sub-requisito de: Seminarios requeridos'),
  ('Comprender y usar la creatividad', 'Sub-requisito de: Seminarios requeridos'),
  ('Principios de evangelización en los jóvenes y niños', 'Sub-requisito de: Seminarios requeridos'),
  ('Cómo llevar a un niño a Cristo', 'Sub-requisito de: Seminarios requeridos'),
  ('Comprendiendo sus dones espirituales', 'Sub-requisito de: Seminarios requeridos'),
  ('Tener o desarrollar las siguientes especialidades', 'Completar todas las siguientes especialidades'),
  ('Narración de Historias', 'Sub-requisito de: Especialidades requeridas'),
  ('Habilidades de Campamento I-IV', 'Sub-requisito de: Especialidades requeridas'),
  ('Ejercicios de Marchas', 'Sub-requisito de: Especialidades requeridas'),
  ('Nudos', 'Sub-requisito de: Especialidades requeridas'),
  ('Desarrollar dos especialidades de tu elección, no desarrolladas anteriormente', NULL::TEXT),
  ('Tener un Certificado de Primeros Auxilios y Seguridad de la Cruz Roja vigente o su equivalente', NULL::TEXT),
  ('Supervisar a un grupo de niños o adolescentes a través de una clase de Aventureros o Conquistadores, o enseñar en una clase de Escuela Sabática durante al menos un año', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 4 — Desarrollo del niño
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Desarrollo del niño', 'Sección IV — Desarrollo del niño', 13, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Desarrollo del niño' AND class_id = 13
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Leer o escuchar el libro ''La Educación'' y presentar en una página tu reacción concentrándote en los beneficios de la lectura', NULL::TEXT),
  ('Leer o escuchar ''La Conducción del Niño'' o ''Mensaje para los Jóvenes'' y presentar en una página tu reacción concentrándote en los beneficios de la lectura', NULL::TEXT),
  ('Asistir a tres seminarios relacionados con el Desarrollo del Niño (PYSO) o sobre la Teoría de la Educación (EDUC) relacionados con la edad del grupo al que supervisas', NULL::TEXT),
  ('Observar por un período de dos horas a un grupo de Aventureros o Conquistadores y escribir una reflexión sobre la interacción entre ellos y el personal', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 5 — Desarrollo del liderazgo
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Desarrollo del liderazgo', 'Sección V — Desarrollo del liderazgo', 13, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Desarrollo del liderazgo' AND class_id = 13
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('Leer un libro actual de tu elección sobre el tema de ''Desarrollo de Habilidades de Liderazgo''', NULL::TEXT),
  ('Demostrar tus habilidades de liderazgo realizando lo siguiente', 'Completar todos los siguientes requisitos'),
  ('Desarrollar y dirigir tres talleres creativos para niños y/o adolescentes', 'Sub-requisito de: Demostrar habilidades de liderazgo'),
  ('Participar en un rol de liderazgo con el grupo que supervisas en un evento patrocinado por tu Asociación/Misión', 'Sub-requisito de: Demostrar habilidades de liderazgo'),
  ('Enseñar tres especialidades para Aventureros o dos especialidades para Conquistadores', 'Sub-requisito de: Demostrar habilidades de liderazgo'),
  ('Participar en la planificación y liderazgo de una excursión con un grupo de 6 a 15 años', 'Sub-requisito de: Demostrar habilidades de liderazgo'),
  ('Ser miembro activo del personal de un Club de Aventureros, Conquistadores o Escuela Sabática por al menos un año y participar en al menos 75% de las reuniones', 'Sub-requisito de: Demostrar habilidades de liderazgo'),
  ('Escribir los objetivos que te gustaría alcanzar en tu ministerio en favor de los niños y adolescentes', NULL::TEXT),
  ('Identificar 3 responsabilidades en tu vida, por lo menos una con orientación espiritual, y redactar 3 metas u objetivos para cada una', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 6 — Desarrollo de un estilo de vida sano
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Desarrollo de un estilo de vida sano', 'Sección VI — Desarrollo de un estilo de vida sano', 13, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Desarrollo de un estilo de vida sano' AND class_id = 13
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Participar en un plan de aptitud física personal realizando una de las siguientes opciones', 'Seleccionar una de las siguientes opciones'),
  ('Requisitos físicos del plan de ''Medallón de Plata'', o ''Medallón de Oro'' si ya posee plata', 'Sub-requisito de: Plan de aptitud física'),
  ('Un programa de entrenamiento físico escolar', 'Sub-requisito de: Plan de aptitud física'),
  ('Un programa de entrenamiento físico basado en un libro de aptitud física o aprobado por el instructor/director', 'Sub-requisito de: Plan de aptitud física')
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 7 — Documentación
-- ============================================================
WITH mod_7 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Documentación', 'Sección VII — Documentación', 13, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_7_id AS (
  SELECT module_id FROM mod_7
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Documentación' AND class_id = 13
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_7_id.module_id, true
FROM mod_7_id,
(VALUES
  ('Compilar una carpeta de evidencias documentando todo el trabajo realizado para cumplir todos los requisitos de Guía Mayor', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

COMMIT;
