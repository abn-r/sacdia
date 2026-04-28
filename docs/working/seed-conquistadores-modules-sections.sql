-- ==========================================================================
-- Seed: Conquistadores — Módulos y Secciones (6 clases)
-- Clases: Amigo (7), Compañero (8), Explorador (9),
--         Orientador (10), Viajero (11), Guía (12)
-- Fecha: 2026-03-24
-- Encoding: UTF-8
-- Idempotente: usa ON CONFLICT DO NOTHING
-- ==========================================================================
BEGIN;

-- ##########################################################################
-- CLASE: AMIGO (class_id = 7)
-- ##########################################################################

-- ============================================================
-- Amigo — Módulo 1: Requisitos generales
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos generales', 'Módulo 1 — Requisitos generales', 7, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos generales' AND class_id = 7
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Tener 10 años y/o estar en quinto grado', NULL::TEXT),
  ('Ser un miembro activo del Club de Conquistadores', NULL::TEXT),
  ('Memorizar y explicar el Voto y la Ley del Conquistador', NULL::TEXT),
  ('Leer el libro El Sendero de la Felicidad', NULL::TEXT),
  ('Tener un certificado vigente del Club de Libros', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Amigo — Módulo 2: Investigación bíblica
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Investigación bíblica', 'Módulo 2 — Investigación bíblica', 7, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Investigación bíblica' AND class_id = 7
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Aprender de memoria los libros del Antiguo Testamento e identificar sus secciones', NULL::TEXT),
  ('Tener un certificado vigente de Gemas Bíblicas', NULL::TEXT),
  ('Saber y explicar el Salmo 23 o el Salmo 46', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Amigo — Módulo 3: Sirviendo a otros
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sirviendo a otros', 'Módulo 3 — Sirviendo a otros', 7, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sirviendo a otros' AND class_id = 7
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Buscar maneras de dedicar dos horas a ayudar a alguien necesitado de la comunidad', NULL::TEXT),
  ('Ser un buen ciudadano en la escuela y en el hogar', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Amigo — Módulo 4: Historia denominacional
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Historia denominacional', 'Módulo 4 — Historia denominacional', 7, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Historia denominacional' AND class_id = 7
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Intercambiar ideas sobre el período comprendido entre la ascensión de Cristo y 1844', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Amigo — Módulo 5: Salud y bienestar físico
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Salud y bienestar físico', 'Módulo 5 — Salud y bienestar físico', 7, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Salud y bienestar físico' AND class_id = 7
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('Aprender principios de temperancia y escribir un voto personal', NULL::TEXT),
  ('Aprender principios de alimentación saludable y preparar un proyecto sobre grupos básicos de alimentos', NULL::TEXT),
  ('Completar la especialidad de Natación I (elemental)', NULL::TEXT),
  ('Realizar una caminata de 3 km en una hora', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Amigo — Módulo 6: Estudio de la naturaleza
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Estudio de la naturaleza', 'Módulo 6 — Estudio de la naturaleza', 7, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Estudio de la naturaleza' AND class_id = 7
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Participar en una caminata para apreciar la naturaleza y relacionarla con textos bíblicos', NULL::TEXT),
  ('Completar una especialidad entre: Perros, Gatos, Mamíferos, Semillas, Pájaros o Aves', NULL::TEXT),
  ('Conocer e identificar cinco flores y cinco insectos de su zona', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Amigo — Módulo 7: Destrezas de campamento
-- ============================================================
WITH mod_7 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Destrezas de campamento', 'Módulo 7 — Destrezas de campamento', 7, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_7_id AS (
  SELECT module_id FROM mod_7
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Destrezas de campamento' AND class_id = 7
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_7_id.module_id, true
FROM mod_7_id,
(VALUES
  ('Saber cómo se hacen las sogas/cuerdas y demostrar el uso correcto de nudos básicos', NULL::TEXT),
  ('Pernoctar en un campamento', NULL::TEXT),
  ('Aprobar un examen sobre medidas generales de seguridad', NULL::TEXT),
  ('Armar y desarmar una carpa y hacer una cama de campamento', NULL::TEXT),
  ('Conocer diez reglas para excursiones y qué hacer cuando uno está perdido', NULL::TEXT),
  ('Aprender señales de rastro y pista', NULL::TEXT),
  ('Completar una especialidad en Artes y Habilidades Manuales', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Amigo — Módulo 8: Sección avanzada
-- ============================================================
WITH mod_8 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sección avanzada', 'Módulo 8 — Sección avanzada', 7, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_8_id AS (
  SELECT module_id FROM mod_8
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sección avanzada' AND class_id = 7
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_8_id.module_id, true
FROM mod_8_id,
(VALUES
  ('Prender un fuego con un fósforo usando combustible natural', NULL::TEXT),
  ('Saber el uso adecuado del cuchillo y el hacha, con sus reglas de seguridad', NULL::TEXT),
  ('Atar cinco nudos con velocidad', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ##########################################################################
-- CLASE: COMPAÑERO (class_id = 8)
-- ##########################################################################

-- ============================================================
-- Compañero — Módulo 1: Requisitos generales
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos generales', 'Módulo 1 — Requisitos generales', 8, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos generales' AND class_id = 8
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Tener 11 años y/o estar en sexto grado', NULL::TEXT),
  ('Ser miembro activo del Club de Conquistadores', NULL::TEXT),
  ('Aprender o repasar el significado del Lema de los Conquistadores e ilustrar su sentido', NULL::TEXT),
  ('Leer el libro El Sendero de la Felicidad y elaborar un reporte', NULL::TEXT),
  ('Tener certificado vigente del Club de Libros y escribir al menos un párrafo relacionado con la lectura', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Compañero — Módulo 2: Investigación bíblica
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Investigación bíblica', 'Módulo 2 — Investigación bíblica', 8, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Investigación bíblica' AND class_id = 8
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Aprender de memoria los libros del Nuevo Testamento y sus grupos principales', NULL::TEXT),
  ('Tener un certificado vigente de Gemas Bíblicas', NULL::TEXT),
  ('Escoger con el consejero un tema de presentación o disertación', NULL::TEXT),
  ('Leer los evangelios de Mateo y Marcos', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Compañero — Módulo 3: Sirviendo a otros
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sirviendo a otros', 'Módulo 3 — Sirviendo a otros', 8, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sirviendo a otros' AND class_id = 8
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Emplear de manera conveniente al menos dos horas en servicio práctico', NULL::TEXT),
  ('Dedicar por lo menos una hora a un proyecto que beneficie a la comunidad o a la iglesia', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Compañero — Módulo 4: Historia denominacional
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Historia denominacional', 'Módulo 4 — Historia denominacional', 8, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Historia denominacional' AND class_id = 8
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Contestar preguntas basadas en el audiovisual El Clamor de Medianoche', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Compañero — Módulo 5: Salud y bienestar físico
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Salud y bienestar físico', 'Módulo 5 — Salud y bienestar físico', 8, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Salud y bienestar físico' AND class_id = 8
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('Aprender de memoria y explicar 1 Corintios 9:24-27', NULL::TEXT),
  ('Discutir con el consejero el tema de la salud y un programa regular de ejercicios', NULL::TEXT),
  ('Saber los efectos nocivos del tabaco sobre la salud y la condición física', NULL::TEXT),
  ('Completar la especialidad de Natación II (intermedia)', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Compañero — Módulo 6: Estudio de la naturaleza
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Estudio de la naturaleza', 'Módulo 6 — Estudio de la naturaleza', 8, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Estudio de la naturaleza' AND class_id = 8
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Identificar y describir siete pájaros y siete árboles', NULL::TEXT),
  ('Completar una especialidad de naturaleza', NULL::TEXT),
  ('Participar en una caminata de una hora por el campo', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Compañero — Módulo 7: Actividades de campamento
-- ============================================================
WITH mod_7 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Actividades de campamento', 'Módulo 7 — Actividades de campamento', 8, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_7_id AS (
  SELECT module_id FROM mod_7
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Actividades de campamento' AND class_id = 8
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_7_id.module_id, true
FROM mod_7_id,
(VALUES
  ('Saber o repasar los nudos requeridos en Amigo y aprender nuevos nudos con uso práctico', NULL::TEXT),
  ('Encontrar los ocho puntos cardinales sin brújula', NULL::TEXT),
  ('Pernoctar dos noches en campamento y conocer puntos esenciales del campamento', NULL::TEXT),
  ('Conocer amarres básicos', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Compañero — Módulo 8: Primeros auxilios
-- ============================================================
WITH mod_8 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Primeros auxilios', 'Módulo 8 — Primeros auxilios', 8, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_8_id AS (
  SELECT module_id FROM mod_8
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Primeros auxilios' AND class_id = 8
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_8_id.module_id, true
FROM mod_8_id,
(VALUES
  ('Pasar el examen de primeros auxilios para Compañero', NULL::TEXT),
  ('Primeros auxilios para atragantamiento y obstrucción de vías respiratorias', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Compañero — Módulo 9: Sección avanzada
-- ============================================================
WITH mod_9 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sección avanzada', 'Módulo 9 — Sección avanzada', 8, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_9_id AS (
  SELECT module_id FROM mod_9
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sección avanzada' AND class_id = 8
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_9_id.module_id, true
FROM mod_9_id,
(VALUES
  ('Aprender versículos de memoria y hacer reflexión', NULL::TEXT),
  ('Dedicar por lo menos cinco horas en servicio a la comunidad', NULL::TEXT),
  ('Ampliar la parte histórica con preguntas adicionales', NULL::TEXT),
  ('Caminar ocho kilómetros y llevar un diario', NULL::TEXT),
  ('Identificar 12 pájaros', NULL::TEXT),
  ('Comentar el plan de 5 días', NULL::TEXT),
  ('Identificar y describir 12 árboles', NULL::TEXT),
  ('Hacer diferentes fuegos y describir su uso', NULL::TEXT),
  ('Cocinar comida de campamento sin utensilios', NULL::TEXT),
  ('Preparar una tabla con quince nudos diferentes', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ##########################################################################
-- CLASE: EXPLORADOR (class_id = 9)
-- ##########################################################################

-- ============================================================
-- Explorador — Módulo 1: Requisitos generales
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos generales', 'Módulo 1 — Requisitos generales', 9, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos generales' AND class_id = 9
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Tener 12 años y/o estar en primero de secundaria', NULL::TEXT),
  ('Ser miembro activo del Club de Conquistadores', NULL::TEXT),
  ('Aprender o repasar el significado de la Ley de los Conquistadores y demostrar comprensión', NULL::TEXT),
  ('Leer El Sendero de la Felicidad si no se ha leído antes', NULL::TEXT),
  ('Tener certificado vigente del Club de Libros y escribir un párrafo sobre la lectura', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Explorador — Módulo 2: Investigación bíblica
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Investigación bíblica', 'Módulo 2 — Investigación bíblica', 9, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Investigación bíblica' AND class_id = 9
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Familiarizarse con el uso de una concordancia', NULL::TEXT),
  ('Tener certificado vigente de Gemas Bíblicas', NULL::TEXT),
  ('Leer los evangelios de Lucas y Juan', NULL::TEXT),
  ('Escoger con el consejero un pasaje para lectura y reflexión', NULL::TEXT),
  ('Aprender de memoria y explicar textos bíblicos solicitados', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Explorador — Módulo 3: Sirviendo a los demás
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sirviendo a los demás', 'Módulo 3 — Sirviendo a los demás', 9, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sirviendo a los demás' AND class_id = 9
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Participar en una actividad de servicio a la comunidad', NULL::TEXT),
  ('Participar en por lo menos tres programas de la iglesia', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Explorador — Módulo 4: Historia denominacional
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Historia denominacional', 'Módulo 4 — Historia denominacional', 9, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Historia denominacional' AND class_id = 9
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Contestar preguntas basadas en el audiovisual Cuéntaselo al mundo o Guardianes de la llama', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Explorador — Módulo 5: Salud y bienestar físico
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Salud y bienestar físico', 'Módulo 5 — Salud y bienestar físico', 9, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Salud y bienestar físico' AND class_id = 9
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('Completar actividades relacionadas con estilo de vida sano y voto de no adicciones', NULL::TEXT),
  ('Participar en una caminata de 8 kilómetros y escribir un informe breve', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Explorador — Módulo 6: Estudio de la naturaleza
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Estudio de la naturaleza', 'Módulo 6 — Estudio de la naturaleza', 9, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Estudio de la naturaleza' AND class_id = 9
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Identificar tres planetas, cinco estrellas y cinco constelaciones', NULL::TEXT),
  ('Completar una especialidad de naturaleza', NULL::TEXT),
  ('Empezar una especialidad JA no cumplida antes en recreación o artes', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Explorador — Módulo 7: Destrezas de campamento
-- ============================================================
WITH mod_7 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Destrezas de campamento', 'Módulo 7 — Destrezas de campamento', 9, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_7_id AS (
  SELECT module_id FROM mod_7
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Destrezas de campamento' AND class_id = 9
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_7_id.module_id, true
FROM mod_7_id,
(VALUES
  ('Pernoctar dos noches en campamento y repasar puntos esenciales', NULL::TEXT),
  ('Explicar qué es un mapa topográfico y sus usos', NULL::TEXT),
  ('Relacionar símbolos y orientación cartográfica', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Explorador — Módulo 8: Primeros auxilios
-- ============================================================
WITH mod_8 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Primeros auxilios', 'Módulo 8 — Primeros auxilios', 9, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_8_id AS (
  SELECT module_id FROM mod_8
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Primeros auxilios' AND class_id = 9
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_8_id.module_id, true
FROM mod_8_id,
(VALUES
  ('Aprobar el examen de primeros auxilios de Explorador', NULL::TEXT),
  ('Primeros auxilios para hemorragias externas e internas', NULL::TEXT),
  ('Estado de shock', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Explorador — Módulo 9: Sección avanzada
-- ============================================================
WITH mod_9 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sección avanzada', 'Módulo 9 — Sección avanzada', 9, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_9_id AS (
  SELECT module_id FROM mod_9
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sección avanzada' AND class_id = 9
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_9_id.module_id, true
FROM mod_9_id,
(VALUES
  ('Trabajo con banderín de unidad', NULL::TEXT),
  ('Preguntas históricas adicionales', NULL::TEXT),
  ('Actividades complementarias de orientación y naturaleza', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ##########################################################################
-- CLASE: ORIENTADOR (class_id = 10)
-- ##########################################################################

-- ============================================================
-- Orientador — Módulo 1: Requisitos generales
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos generales', 'Módulo 1 — Requisitos generales', 10, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos generales' AND class_id = 10
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Tener 13 años y/o estar en segundo de secundaria', NULL::TEXT),
  ('Ser miembro de un Club de Conquistadores', NULL::TEXT),
  ('Demostrar el significado del Lema y el Blanco de los Jóvenes Adventistas', NULL::TEXT),
  ('Escoger y leer tres libros del Club de Libros', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Orientador — Módulo 2: Descubrimiento espiritual
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Descubrimiento espiritual', 'Módulo 2 — Descubrimiento espiritual', 10, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Descubrimiento espiritual' AND class_id = 10
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Abordar en grupo temas sobre inspiración y autoridad bíblica', NULL::TEXT),
  ('Marcar en la Biblia textos relacionados con la inspiración', NULL::TEXT),
  ('Discutir argumentos de evolución y creación bíblica', NULL::TEXT),
  ('Anotar lo que Dios hizo cada día en la creación', NULL::TEXT),
  ('Tener certificado vigente de Gemas Bíblicas', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Orientador — Módulo 3: Sirviendo a otros
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sirviendo a otros', 'Módulo 3 — Sirviendo a otros', 10, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sirviendo a otros' AND class_id = 10
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Participar en dos programas diferentes de testificación a la comunidad', NULL::TEXT),
  ('Discutir cómo los jóvenes adventistas deben relacionarse con sus compañeros', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Orientador — Módulo 4: La vida en la iglesia
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('La vida en la iglesia', 'Módulo 4 — La vida en la iglesia', 10, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'La vida en la iglesia' AND class_id = 10
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Asistir a una Junta Administrativa o de Bautizados y preparar un informe', NULL::TEXT),
  ('Inscribir a tres personas en algún curso bíblico', NULL::TEXT),
  ('Realizar con el grupo una reunión social cada trimestre durante tres trimestres', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Orientador — Módulo 5: Historia denominacional
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Historia denominacional', 'Módulo 5 — Historia denominacional', 10, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Historia denominacional' AND class_id = 10
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('Contestar preguntas basadas en el audiovisual sobre el esparcimiento del mensaje adventista', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Orientador — Módulo 6: Desarrollo personal
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Desarrollo personal', 'Módulo 6 — Desarrollo personal', 10, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Desarrollo personal' AND class_id = 10
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Examinar actitudes personales mediante discusión en grupo e investigación individual', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Orientador — Módulo 7: Salud y bienestar físico
-- ============================================================
WITH mod_7 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Salud y bienestar físico', 'Módulo 7 — Salud y bienestar físico', 10, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_7_id AS (
  SELECT module_id FROM mod_7
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Salud y bienestar físico' AND class_id = 10
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_7_id.module_id, true
FROM mod_7_id,
(VALUES
  ('Discutir principios de la cultura física y bosquejar un programa de acondicionamiento', NULL::TEXT),
  ('Completar la especialidad de Buenos Modales y Apariencia Física', NULL::TEXT),
  ('Discutir ventajas de practicar el estilo de vida cristiano', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Orientador — Módulo 8: Actividades al aire libre
-- ============================================================
WITH mod_8 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Actividades al aire libre', 'Módulo 8 — Actividades al aire libre', 10, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_8_id AS (
  SELECT module_id FROM mod_8
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Actividades al aire libre' AND class_id = 10
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_8_id.module_id, true
FROM mod_8_id,
(VALUES
  ('Construir y demostrar el uso de un horno reflector', NULL::TEXT),
  ('Participar en una salida campestre con dos noches y preparar la mochila', NULL::TEXT),
  ('Terminar una especialidad de naturaleza o recreación no obtenida anteriormente', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Orientador — Módulo 9: Primeros auxilios
-- ============================================================
WITH mod_9 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Primeros auxilios', 'Módulo 9 — Primeros auxilios', 10, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_9_id AS (
  SELECT module_id FROM mod_9
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Primeros auxilios' AND class_id = 10
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_9_id.module_id, true
FROM mod_9_id,
(VALUES
  ('Participar en la clase de primeros auxilios para Orientador y aprobar examen', NULL::TEXT),
  ('Fracturas, dislocaciones, torceduras y dolor muscular', NULL::TEXT),
  ('Quemaduras y medidas terapéuticas', NULL::TEXT),
  ('Reanimación básica y ABC de primeros auxilios', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Orientador — Módulo 10: Sección avanzada
-- ============================================================
WITH mod_10 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sección avanzada', 'Módulo 10 — Sección avanzada', 10, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_10_id AS (
  SELECT module_id FROM mod_10
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sección avanzada' AND class_id = 10
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_10_id.module_id, true
FROM mod_10_id,
(VALUES
  ('Orientación por estrellas, reloj, luna y sombra', NULL::TEXT),
  ('Trabajo con plantas medicinales, identificación y preparación', NULL::TEXT),
  ('Uso de la pañoleta', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ##########################################################################
-- CLASE: VIAJERO (class_id = 11)
-- ##########################################################################

-- ============================================================
-- Viajero — Módulo 1: Requisitos generales
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos generales', 'Módulo 1 — Requisitos generales', 11, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos generales' AND class_id = 11
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Tener 14 años y/o estar en tercer grado de secundaria', NULL::TEXT),
  ('Ser miembro activo del Club de Conquistadores', NULL::TEXT),
  ('Explicar el significado del Voto de los Jóvenes Adventistas', NULL::TEXT),
  ('Seleccionar y leer tres libros de la lista del Club de Libros', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Viajero — Módulo 2: Descubrimiento espiritual
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Descubrimiento espiritual', 'Módulo 2 — Descubrimiento espiritual', 11, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Descubrimiento espiritual' AND class_id = 11
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Estudiar la obra personal del Espíritu Santo y su relación con el ser humano', NULL::TEXT),
  ('Aumentar el conocimiento sobre los acontecimientos finales previos a la segunda venida', NULL::TEXT),
  ('Describir el verdadero significado de la observancia del sábado', NULL::TEXT),
  ('Tener certificado vigente de Gemas Bíblicas', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Viajero — Módulo 3: Sirviendo a otros
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sirviendo a otros', 'Módulo 3 — Sirviendo a otros', 11, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sirviendo a otros' AND class_id = 11
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Invitar individualmente o en grupo a un amigo a actividades juveniles de la iglesia', NULL::TEXT),
  ('Ayudar a organizar y participar en un proyecto de servicio', NULL::TEXT),
  ('Discutir cómo un joven adventista debe relacionarse con quienes lo rodean', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Viajero — Módulo 4: La vida en la iglesia
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('La vida en la iglesia', 'Módulo 4 — La vida en la iglesia', 11, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'La vida en la iglesia' AND class_id = 11
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Preparar un diagrama sobre la organización de la iglesia local y enumerar funciones', NULL::TEXT),
  ('Participar en dos programas de la iglesia organizados por departamentos diferentes', NULL::TEXT),
  ('Planear una actividad social con el grupo por lo menos una vez por trimestre', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Viajero — Módulo 5: Historia denominacional
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Historia denominacional', 'Módulo 5 — Historia denominacional', 11, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Historia denominacional' AND class_id = 11
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('Mencionar el papel de Elena de White en la Iglesia Adventista en diferentes áreas', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Viajero — Módulo 6: Desarrollo personal
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Desarrollo personal', 'Módulo 6 — Desarrollo personal', 11, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Desarrollo personal' AND class_id = 11
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Examinar actitudes personales por medio del estudio y la discusión grupal', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Viajero — Módulo 7: Salud y bienestar físico
-- ============================================================
WITH mod_7 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Salud y bienestar físico', 'Módulo 7 — Salud y bienestar físico', 11, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_7_id AS (
  SELECT module_id FROM mod_7
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Salud y bienestar físico' AND class_id = 11
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_7_id.module_id, true
FROM mod_7_id,
(VALUES
  ('Organizar con la unidad una reunión social relacionada con principios de salud', NULL::TEXT),
  ('Trabajar recortes y evidencias sobre salud y estilo de vida', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Viajero — Módulo 8: Vida al aire libre
-- ============================================================
WITH mod_8 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Vida al aire libre', 'Módulo 8 — Vida al aire libre', 11, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_8_id AS (
  SELECT module_id FROM mod_8
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Vida al aire libre' AND class_id = 11
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_8_id.module_id, true
FROM mod_8_id,
(VALUES
  ('Participar en grupos de al menos cuatro personas, incluyendo un adulto, en actividad al aire libre', NULL::TEXT),
  ('Completar una especialidad sobre recreación o naturaleza no hecha antes', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Viajero — Módulo 9: Primeros auxilios
-- ============================================================
WITH mod_9 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Primeros auxilios', 'Módulo 9 — Primeros auxilios', 11, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_9_id AS (
  SELECT module_id FROM mod_9
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Primeros auxilios' AND class_id = 11
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_9_id.module_id, true
FROM mod_9_id,
(VALUES
  ('Aprobar el examen de primeros auxilios para Viajero', NULL::TEXT),
  ('Envenenamiento por ingestión', NULL::TEXT),
  ('Envenenamiento por inhalación', NULL::TEXT),
  ('Envenenamiento por absorción en la piel', NULL::TEXT),
  ('Envenenamiento por inyección', NULL::TEXT),
  ('Picaduras y mordeduras', NULL::TEXT),
  ('Posición de recuperación', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Viajero — Módulo 10: Sección avanzada
-- ============================================================
WITH mod_10 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sección avanzada', 'Módulo 10 — Sección avanzada', 11, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_10_id AS (
  SELECT module_id FROM mod_10
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sección avanzada' AND class_id = 11
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_10_id.module_id, true
FROM mod_10_id,
(VALUES
  ('Tabla de rendimiento y medallón de plata', NULL::TEXT),
  ('Especialidades avanzadas de aire libre y rescate', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ##########################################################################
-- CLASE: GUÍA (class_id = 12)
-- ##########################################################################

-- ============================================================
-- Guía — Módulo 1: Requisitos generales
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos generales', 'Módulo 1 — Requisitos generales', 12, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos generales' AND class_id = 12
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Tener 15 años y/o estar en primer grado de bachillerato', NULL::TEXT),
  ('Ser un miembro activo del Club de Conquistadores', NULL::TEXT),
  ('Saber y entender la Legión de Honor de los Jóvenes Adventistas', NULL::TEXT),
  ('Seleccionar y leer un libro de la lista del Club de Libros', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Guía — Módulo 2: Descubrimiento espiritual
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Descubrimiento espiritual', 'Módulo 2 — Descubrimiento espiritual', 12, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Descubrimiento espiritual' AND class_id = 12
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Discutir cómo el cristiano puede poseer el fruto del Espíritu según Pablo', NULL::TEXT),
  ('Contestar preguntas basadas en el audiovisual sobre el servicio del santuario', NULL::TEXT),
  ('Familiarizarse con el énfasis doctrinal y espiritual de la iglesia', NULL::TEXT),
  ('Tener certificado vigente de Gemas Bíblicas', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Guía — Módulo 3: Sirviendo a otros
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sirviendo a otros', 'Módulo 3 — Sirviendo a otros', 12, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sirviendo a otros' AND class_id = 12
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Ayudar a organizar y participar en grupo o individualmente en actividades de servicio y testificación', NULL::TEXT),
  ('Participar en un intercambio de ideas sobre cómo testificar a otros muchachos', NULL::TEXT),
  ('Reflexionar sobre el comunicador misionero', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Guía — Módulo 4: La vida en la iglesia
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('La vida en la iglesia', 'Módulo 4 — La vida en la iglesia', 12, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'La vida en la iglesia' AND class_id = 12
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Considerar el diagrama denominacional de la organización y sus detalles', NULL::TEXT),
  ('Planear una actividad social para el grupo una vez por trimestre', NULL::TEXT),
  ('Hacer una breve reseña histórica de la iglesia local', NULL::TEXT),
  ('Trazar el desarrollo de la Iglesia Adventista en la División Interamericana', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Guía — Módulo 5: Historia denominacional
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Historia denominacional', 'Módulo 5 — Historia denominacional', 12, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Historia denominacional' AND class_id = 12
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('Estudiar expansión misionera, divisiones mundiales y desarrollo histórico adventista', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Guía — Módulo 6: Desarrollo personal
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Desarrollo personal', 'Módulo 6 — Desarrollo personal', 12, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Desarrollo personal' AND class_id = 12
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Examinar actitudes frente a distintos tópicos por medio de la discusión en grupo', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Guía — Módulo 7: Salud y bienestar físico
-- ============================================================
WITH mod_7 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Salud y bienestar físico', 'Módulo 7 — Salud y bienestar físico', 12, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_7_id AS (
  SELECT module_id FROM mod_7
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Salud y bienestar físico' AND class_id = 12
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_7_id.module_id, true
FROM mod_7_id,
(VALUES
  ('Presentar motivos personales que demuestren la ventaja de una vida saludable', NULL::TEXT),
  ('Completar actividades relacionadas con temperancia', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Guía — Módulo 8: Actividades al aire libre
-- ============================================================
WITH mod_8 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Actividades al aire libre', 'Módulo 8 — Actividades al aire libre', 12, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_8_id AS (
  SELECT module_id FROM mod_8
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Actividades al aire libre' AND class_id = 12
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_8_id.module_id, true
FROM mod_8_id,
(VALUES
  ('Pernoctar dos noches en campamento y discutir equipo necesario', NULL::TEXT),
  ('Planear y cocinar al aire libre tres platillos diferentes', NULL::TEXT),
  ('Construir un objeto con cuerdas y amarras (puente, torre, etc.)', NULL::TEXT),
  ('Completar una especialidad no realizada anteriormente y que cuente para la clase', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Guía — Módulo 9: Primeros auxilios
-- ============================================================
WITH mod_9 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Primeros auxilios', 'Módulo 9 — Primeros auxilios', 12, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_9_id AS (
  SELECT module_id FROM mod_9
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Primeros auxilios' AND class_id = 12
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_9_id.module_id, true
FROM mod_9_id,
(VALUES
  ('Pasar el examen de primeros auxilios para Guía', NULL::TEXT),
  ('Técnica de RCP y RCCP', NULL::TEXT),
  ('Qué hacer en emergencias', NULL::TEXT),
  ('Transportación de lesionados', NULL::TEXT),
  ('Emergencias diabéticas', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Guía — Módulo 10: Sección avanzada
-- ============================================================
WITH mod_10 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Sección avanzada', 'Módulo 10 — Sección avanzada', 12, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_10_id AS (
  SELECT module_id FROM mod_10
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Sección avanzada' AND class_id = 12
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_10_id.module_id, true
FROM mod_10_id,
(VALUES
  ('Actividades complementarias de hogar, hospitalidad, arreglos florales y manejo del dinero', NULL::TEXT),
  ('Uso de la pañoleta', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

COMMIT;
