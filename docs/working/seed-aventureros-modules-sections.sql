-- ==========================================================================
-- Seed: Aventureros (class_id 1–6) — Módulos y Secciones
-- Clases: Corderitos, Castores, Abejas, Rayos de Sol, Constructores,
--         Manos Ayudadoras
-- Fecha: 2026-03-24
-- Encoding: UTF-8
-- Idempotente: usa ON CONFLICT DO NOTHING
-- ==========================================================================
BEGIN;

-- ╔════════════════════════════════════════════════════════════════════════╗
-- ║  CLASE 1 — Corderitos  (class_id = 1)                               ║
-- ╚════════════════════════════════════════════════════════════════════════╝

-- ============================================================
-- Módulo 1 — Requisitos básicos  (Corderitos)
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos básicos', 'Módulo 1 — Requisitos básicos', 1, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos básicos' AND class_id = 1
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Requisitos básicos generales de la tarjeta de Corderitos', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 2 — Mi Dios  (Corderitos)
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi Dios', 'Módulo 2 — Mi Dios', 1, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi Dios' AND class_id = 1
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Acuérdate', NULL::TEXT),
  ('La creación nos habla', NULL::TEXT),
  ('Mi amigo Jesús', NULL::TEXT),
  ('Dejen que los niños vengan', NULL::TEXT),
  ('Trabajar con Jesús', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 3 — Yo mismo  (Corderitos)
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Yo mismo', 'Módulo 3 — Yo mismo', 1, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Yo mismo' AND class_id = 1
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Creciendo cada día', NULL::TEXT),
  ('Compartir', NULL::TEXT),
  ('Partes del cuerpo', NULL::TEXT),
  ('Mi cuerpo', NULL::TEXT),
  ('Comer para vivir', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 4 — Mi familia  (Corderitos)
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi familia', 'Módulo 4 — Mi familia', 1, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi familia' AND class_id = 1
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Mi querida familia', NULL::TEXT),
  ('Papá', NULL::TEXT),
  ('Mamá', NULL::TEXT),
  ('Bebé', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 5 — Mi mundo  (Corderitos)
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi mundo', 'Módulo 5 — Mi mundo', 1, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi mundo' AND class_id = 1
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('Ayudante de la comunidad', NULL::TEXT),
  ('Compartiendo con mis amigos', NULL::TEXT),
  ('Comportamiento en el aula y convivencia', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 6 — Especialidades  (Corderitos)
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Especialidades', 'Módulo 6 — Especialidades', 1, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Especialidades' AND class_id = 1
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Alimentos sanos', NULL::TEXT),
  ('Ayudante especial', NULL::TEXT),
  ('Saludable', NULL::TEXT),
  ('Ayudante de la comunidad', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;


-- ╔════════════════════════════════════════════════════════════════════════╗
-- ║  CLASE 2 — Aves Madrugadoras / Castores  (class_id = 2)             ║
-- ╚════════════════════════════════════════════════════════════════════════╝

-- ============================================================
-- Módulo 1 — Requisitos básicos  (Castores)
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos básicos', 'Módulo 1 — Requisitos básicos', 2, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos básicos' AND class_id = 2
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Requisitos básicos generales de la tarjeta de Castores', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 2 — Mi Dios  (Castores)
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi Dios', 'Módulo 2 — Mi Dios', 2, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi Dios' AND class_id = 2
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Amigos de la Biblia', NULL::TEXT),
  ('El mundo de Dios', NULL::TEXT),
  ('Creación de Dios', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 3 — Yo mismo  (Castores)
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Yo mismo', 'Módulo 3 — Yo mismo', 2, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Yo mismo' AND class_id = 2
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Diversión alfabética', NULL::TEXT),
  ('Diversión con buenos modales', NULL::TEXT),
  ('Conocer tu cuerpo', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 4 — Mi familia  (Castores)
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi familia', 'Módulo 4 — Mi familia', 2, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi familia' AND class_id = 2
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Ayudando a mamá', NULL::TEXT),
  ('Mascota', NULL::TEXT),
  ('Juguete', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 5 — Mi mundo  (Castores)
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi mundo', 'Módulo 5 — Mi mundo', 2, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi mundo' AND class_id = 2
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('Mis amigos de la comunidad', NULL::TEXT),
  ('Jugando con amigos', NULL::TEXT),
  ('Tesoro escondido', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 6 — Especialidades  (Castores)
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Especialidades', 'Módulo 6 — Especialidades', 2, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Especialidades' AND class_id = 2
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Seguridad ante incendios', NULL::TEXT),
  ('Amigos de la Biblia', NULL::TEXT),
  ('El mundo de Dios', NULL::TEXT),
  ('Diversión alfabética', NULL::TEXT),
  ('Diversión con buenos modales', NULL::TEXT),
  ('Ayudando a mamá', NULL::TEXT),
  ('Amigos de la comunidad', NULL::TEXT),
  ('Jugando con amigos', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;


-- ╔════════════════════════════════════════════════════════════════════════╗
-- ║  CLASE 3 — Abejitas Industriosas / Abejas  (class_id = 3)           ║
-- ╚════════════════════════════════════════════════════════════════════════╝

-- ============================================================
-- Módulo 1 — Requisitos básicos  (Abejas)
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos básicos', 'Módulo 1 — Requisitos básicos', 3, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos básicos' AND class_id = 3
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Responsabilidad', NULL::TEXT),
  ('Refuerzo', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 2 — Mi Dios  (Abejas)
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi Dios', 'Módulo 2 — Mi Dios', 3, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi Dios' AND class_id = 3
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Su plan para salvarme', NULL::TEXT),
  ('Pecado e inicio del pecado', NULL::TEXT),
  ('Creación', NULL::TEXT),
  ('Jesús cuida de mí hoy', NULL::TEXT),
  ('Cielo', NULL::TEXT),
  ('Jesús viene otra vez', NULL::TEXT),
  ('Su mensaje para mí', NULL::TEXT),
  ('Su poder en mi vida', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 3 — Yo mismo  (Abejas)
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Yo mismo', 'Módulo 3 — Yo mismo', 3, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Yo mismo' AND class_id = 3
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Soy especial', NULL::TEXT),
  ('Puedo hacer decisiones inteligentes', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 4 — Mi familia  (Abejas)
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi familia', 'Módulo 4 — Mi familia', 3, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi familia' AND class_id = 3
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Tengo una familia', NULL::TEXT),
  ('Las familias cuidan de otras familias', NULL::TEXT),
  ('Mi familia me ayuda a cuidarme', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 5 — Mi mundo  (Abejas)
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi mundo', 'Módulo 5 — Mi mundo', 3, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi mundo' AND class_id = 3
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('El mundo de los amigos', NULL::TEXT),
  ('El mundo de otras personas', NULL::TEXT),
  ('Yo ayudé en la iglesia', NULL::TEXT),
  ('El mundo de la naturaleza', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 6 — Especialidades  (Abejas)
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Especialidades', 'Módulo 6 — Especialidades', 3, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Especialidades' AND class_id = 3
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Biblia I', NULL::TEXT),
  ('Especialista en seguridad', NULL::TEXT),
  ('Amigo de los animales', NULL::TEXT),
  ('Especialista en salud', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;


-- ╔════════════════════════════════════════════════════════════════════════╗
-- ║  CLASE 4 — Rayos de Sol  (class_id = 4)                             ║
-- ╚════════════════════════════════════════════════════════════════════════╝

-- ============================================================
-- Módulo 1 — Requisitos básicos  (Rayos de Sol)
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos básicos', 'Módulo 1 — Requisitos básicos', 4, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos básicos' AND class_id = 4
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Responsabilidad', NULL::TEXT),
  ('Refuerzo', NULL::TEXT),
  ('Resumen', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 2 — Mi Dios  (Rayos de Sol)
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi Dios', 'Módulo 2 — Mi Dios', 4, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi Dios' AND class_id = 4
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Su plan para salvarme', NULL::TEXT),
  ('Su mensaje para mí', NULL::TEXT),
  ('Su poder en mi vida', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 3 — Yo mismo  (Rayos de Sol)
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Yo mismo', 'Módulo 3 — Yo mismo', 4, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Yo mismo' AND class_id = 4
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Soy especial', NULL::TEXT),
  ('Puedo hacer decisiones inteligentes', NULL::TEXT),
  ('Yo puedo cuidar mi cuerpo', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 4 — Mi familia  (Rayos de Sol)
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi familia', 'Módulo 4 — Mi familia', 4, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi familia' AND class_id = 4
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Tengo una familia', NULL::TEXT),
  ('Las familias se aman', NULL::TEXT),
  ('Mi familia me ayuda a cuidarme', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 5 — Mi mundo  (Rayos de Sol)
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi mundo', 'Módulo 5 — Mi mundo', 4, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi mundo' AND class_id = 4
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('El mundo de los amigos', NULL::TEXT),
  ('El mundo de otras personas', NULL::TEXT),
  ('El mundo de la naturaleza', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 6 — Especialidades  (Rayos de Sol)
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Especialidades', 'Módulo 6 — Especialidades', 4, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Especialidades' AND class_id = 4
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Amigo de Jesús', NULL::TEXT),
  ('Cultura física', NULL::TEXT),
  ('Seguridad en la carretera', NULL::TEXT),
  ('Cortesía', NULL::TEXT),
  ('Amigo de la naturaleza', NULL::TEXT),
  ('Recolección y prensado de flores', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;


-- ╔════════════════════════════════════════════════════════════════════════╗
-- ║  CLASE 5 — Constructores  (class_id = 5)                            ║
-- ╚════════════════════════════════════════════════════════════════════════╝

-- ============================================================
-- Módulo 1 — Requisitos básicos  (Constructores)
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos básicos', 'Módulo 1 — Requisitos básicos', 5, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos básicos' AND class_id = 5
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Responsabilidad', NULL::TEXT),
  ('Refuerzo', NULL::TEXT),
  ('Resumen', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 2 — Mi Dios  (Constructores)
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi Dios', 'Módulo 2 — Mi Dios', 5, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi Dios' AND class_id = 5
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Su plan para salvarme', NULL::TEXT),
  ('Martin Lutero', NULL::TEXT),
  ('Elena G. White', NULL::TEXT),
  ('Pablo', NULL::TEXT),
  ('Su mensaje para mí', NULL::TEXT),
  ('Su poder en mi vida', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 3 — Yo mismo  (Constructores)
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Yo mismo', 'Módulo 3 — Yo mismo', 5, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Yo mismo' AND class_id = 5
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Soy especial', NULL::TEXT),
  ('Yo puedo hacer decisiones inteligentes', NULL::TEXT),
  ('Yo puedo cuidar mi cuerpo', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 4 — Mi familia  (Constructores)
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi familia', 'Módulo 4 — Mi familia', 5, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi familia' AND class_id = 5
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Tengo una familia', NULL::TEXT),
  ('Las familias cuidan de otras familias', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 5 — Mi mundo  (Constructores)
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi mundo', 'Módulo 5 — Mi mundo', 5, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi mundo' AND class_id = 5
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('El mundo de los amigos', NULL::TEXT),
  ('El mundo de otras personas', NULL::TEXT),
  ('El mundo de la naturaleza', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 6 — Especialidades  (Constructores)
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Especialidades', 'Módulo 6 — Especialidades', 5, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Especialidades' AND class_id = 5
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Biblia II', NULL::TEXT),
  ('Analista de comunicación', NULL::TEXT),
  ('Temperancia', NULL::TEXT),
  ('Mayordomo sabio', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;


-- ╔════════════════════════════════════════════════════════════════════════╗
-- ║  CLASE 6 — Manos Ayudadoras  (class_id = 6)                         ║
-- ╚════════════════════════════════════════════════════════════════════════╝

-- ============================================================
-- Módulo 1 — Requisitos básicos  (Manos Ayudadoras)
-- ============================================================
WITH mod_1 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Requisitos básicos', 'Módulo 1 — Requisitos básicos', 6, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_1_id AS (
  SELECT module_id FROM mod_1
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Requisitos básicos' AND class_id = 6
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_1_id.module_id, true
FROM mod_1_id,
(VALUES
  ('Responsabilidad', NULL::TEXT),
  ('Ley', NULL::TEXT),
  ('Voto', NULL::TEXT),
  ('Refuerzo', NULL::TEXT),
  ('Resumen', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 2 — Mi Dios  (Manos Ayudadoras)
-- ============================================================
WITH mod_2 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi Dios', 'Módulo 2 — Mi Dios', 6, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_2_id AS (
  SELECT module_id FROM mod_2
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi Dios' AND class_id = 6
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_2_id.module_id, true
FROM mod_2_id,
(VALUES
  ('Su plan para salvarme', NULL::TEXT),
  ('Noé', NULL::TEXT),
  ('Abraham', NULL::TEXT),
  ('Moisés', NULL::TEXT),
  ('David', NULL::TEXT),
  ('Daniel', NULL::TEXT),
  ('Su mensaje para mí', NULL::TEXT),
  ('Su poder en mi vida', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 3 — Yo mismo  (Manos Ayudadoras)
-- ============================================================
WITH mod_3 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Yo mismo', 'Módulo 3 — Yo mismo', 6, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_3_id AS (
  SELECT module_id FROM mod_3
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Yo mismo' AND class_id = 6
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_3_id.module_id, true
FROM mod_3_id,
(VALUES
  ('Soy especial', NULL::TEXT),
  ('Yo puedo hacer decisiones inteligentes', NULL::TEXT),
  ('Yo puedo cuidar mi cuerpo', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 4 — Mi familia  (Manos Ayudadoras)
-- ============================================================
WITH mod_4 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi familia', 'Módulo 4 — Mi familia', 6, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_4_id AS (
  SELECT module_id FROM mod_4
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi familia' AND class_id = 6
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_4_id.module_id, true
FROM mod_4_id,
(VALUES
  ('Tengo una familia', NULL::TEXT),
  ('Las familias cuidan de otras familias', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 5 — Mi mundo  (Manos Ayudadoras)
-- ============================================================
WITH mod_5 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Mi mundo', 'Módulo 5 — Mi mundo', 6, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_5_id AS (
  SELECT module_id FROM mod_5
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Mi mundo' AND class_id = 6
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_5_id.module_id, true
FROM mod_5_id,
(VALUES
  ('El mundo de los amigos', NULL::TEXT),
  ('El mundo de otras personas', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

-- ============================================================
-- Módulo 6 — Especialidades  (Manos Ayudadoras)
-- ============================================================
WITH mod_6 AS (
  INSERT INTO class_modules (name, description, class_id, active)
  VALUES ('Especialidades', 'Módulo 6 — Especialidades', 6, true)
  ON CONFLICT (name, class_id) DO NOTHING
  RETURNING module_id
),
mod_6_id AS (
  SELECT module_id FROM mod_6
  UNION ALL
  SELECT module_id FROM class_modules WHERE name = 'Especialidades' AND class_id = 6
  LIMIT 1
)
INSERT INTO class_sections (name, description, module_id, active)
SELECT s.name, s.description, mod_6_id.module_id, true
FROM mod_6_id,
(VALUES
  ('Higiene', NULL::TEXT),
  ('Amigo cariñoso', NULL::TEXT),
  ('En mi casa', NULL::TEXT),
  ('En la iglesia', NULL::TEXT),
  ('En otro lugar', NULL::TEXT),
  ('Cuidado del agua', NULL::TEXT),
  ('Tortuga Arrau', NULL::TEXT)
) AS s(name, description)
ON CONFLICT (name, module_id) DO NOTHING;

COMMIT;
