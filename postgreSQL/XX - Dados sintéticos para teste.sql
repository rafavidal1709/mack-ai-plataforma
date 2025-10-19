SET search_path TO plataforma;

-- ============================
-- SEMESTRES
-- ============================
INSERT INTO semestre (descricao) VALUES
  ('2024/2'),
  ('2025/1'),
  ('2025/2');

-- ============================
-- GRUPOS (4 de estudo, 4 de trabalho)
-- ============================
INSERT INTO grupo (nome, descricao) VALUES
  ('Estudo: Matemática',        'Grupo de estudo de matemática'),
  ('Estudo: Programação',       'Grupo de estudo de programação'),
  ('Estudo: Meio Ambiente',     'Grupo de estudo sobre meio ambiente'),
  ('Estudo: Línguas',           'Grupo de estudo de idiomas'),
  ('Trabalho: Comunicação',     'Célula de comunicação'),
  ('Trabalho: Desenvolvimento', 'Célula de desenvolvimento de software'),
  ('Trabalho: Pesquisa de Campo','Célula de pesquisa de campo'),
  ('Trabalho: Eventos',         'Célula de organização de eventos');

-- ============================
-- PARTICIPANTES (24)
-- ============================
INSERT INTO participante (ra, nome) VALUES
  ('RA0001','Ana Souza'),      ('RA0002','Bruno Lima'),
  ('RA0003','Carla Nunes'),    ('RA0004','Diego Martins'),
  ('RA0005','Eduarda Alves'),  ('RA0006','Felipe Rocha'),
  ('RA0007','Gabriela Reis'),  ('RA0008','Henrique Silva'),
  ('RA0009','Isabela Dias'),   ('RA0010','João Pedro'),
  ('RA0011','Karen Borges'),   ('RA0012','Lucas Ferreira'),
  ('RA0013','Mariana Pires'),  ('RA0014','Nicolas Teixeira'),
  ('RA0015','Olivia Castro'),  ('RA0016','Paulo Henrique'),
  ('RA0017','Queila Monteiro'),('RA0018','Rafael Vidal'),
  ('RA0019','Sofia Ramos'),    ('RA0020','Tiago Oliveira'),
  ('RA0021','Ursula Prado'),   ('RA0022','Vitor Santos'),
  ('RA0023','Wesley Faria'),   ('RA0024','Yasmin Moreira');

-- ============================
-- OCORREU (uma ocorrência por par semestre x grupo)
-- ============================
INSERT INTO ocorreu (semestre, grupo)
SELECT s.id, g.id
FROM semestre s
CROSS JOIN grupo g;

-- ============================
-- ENCONTROS (todos os grupos têm encontros)
-- - 2 encontros por ocorrência
-- - datas base por semestre:
--   2024/2 -> 2024-08-01
--   2025/1 -> 2025-03-01
--   2025/2 -> 2025-08-01
-- ============================
WITH bases AS (
  SELECT s.id AS semestre_id,
         CASE 
           WHEN '2024/2' THEN TIMESTAMPTZ '2024-08-01 19:00:00-03'
           WHEN '2025/1' THEN TIMESTAMPTZ '2025-03-01 19:00:00-03'
           WHEN '2025/2' THEN TIMESTAMPTZ '2025-08-01 19:00:00-03'
         END AS base_dt
  FROM semestre s
),
alvos AS (
  SELECT o.id AS ocorrencia_id, g.nome AS grupo_nome, b.base_dt,
         row_number() OVER (PARTITION BY o.semestre, o.grupo ORDER BY o.id) AS rn
  FROM ocorreu o
  JOIN grupo g ON g.id = o.grupo
  JOIN bases b ON b.semestre_id = o.semestre
)
INSERT INTO encontro (ocorrencia, inicio, fim, tema, resumo)
SELECT a.ocorrencia_id,
       a.base_dt + make_interval(days => 7 * n)                         AS inicio,
       a.base_dt + make_interval(days => 7 * n, hours => 2)             AS fim,
       CONCAT(a.grupo_nome, ' - Sessão ', n+1)                          AS tema,
       'Discussões e atividades do encontro ' || (n+1)                  AS resumo
FROM alvos a
CROSS JOIN generate_series(0,1) AS n;

-- ============================
-- TAREFAS (apenas grupos de trabalho) - 2 por ocorrência
-- ============================
WITH bases AS (
  SELECT s.id AS semestre_id, descricao,
         CASE descricao
           WHEN '2024/2' THEN TIMESTAMPTZ '2024-08-05 09:00:00-03'
           WHEN '2025/1' THEN TIMESTAMPTZ '2025-03-05 09:00:00-03'
           WHEN '2025/2' THEN TIMESTAMPTZ '2025-08-05 09:00:00-03'
         END AS base_dt
  FROM semestre s
),
work_oc AS (
  SELECT o.id AS ocorrencia_id, g.nome AS grupo_nome, b.base_dt
  FROM ocorreu o
  JOIN grupo g ON g.id = o.grupo
  JOIN bases b ON b.semestre_id = o.semestre
  WHERE g.nome LIKE 'Trabalho:%'
)
INSERT INTO tarefa (ocorrencia, inicio, prazo, tema, descricao)
SELECT w.ocorrencia_id,
       w.base_dt + make_interval(days => 10 * n)           AS inicio,
       w.base_dt + make_interval(days => (10 * n + 5))     AS prazo,
       CONCAT(w.grupo_nome, ' - Tarefa ', n+1)             AS tema,
       'Executar atividade prática #' || (n+1)             AS descricao
FROM work_oc w
CROSS JOIN generate_series(0,1) AS n;

-- ============================
-- PARTICIPOU (presenças em encontros)
-- regra: cerca de 1/3 dos participantes por encontro, variando por id
-- ============================
INSERT INTO participou (horas, participante, encontro, confirmado)
SELECT 2                                 AS horas,
       p.id                               AS participante,
       e.id                               AS encontro,
       ( (p.id + e.id) % 2 = 0 )          AS confirmado
FROM encontro e
JOIN participante p ON (p.id % 3) = (e.id % 3);

-- ============================
-- APRESENTOU (subset de participantes que apresentaram em encontros)
-- regra: bem menor (aprox 2 por encontro)
-- ============================
INSERT INTO apresentou (horas, participante, encontro, valido, confirmado)
SELECT 1,
       p.id,
       e.id,
       TRUE,
       ((p.id + e.id) % 4 = 0)
FROM encontro e
JOIN participante p ON (p.id % 12) = (e.id % 12);

-- ============================
-- EXECUTOU (execução prática em encontros) — só para grupos de trabalho
-- ============================
INSERT INTO executou (horas, participante, tarefa, valido, confirmado)
SELECT 1,
       p.id,
       t.id,
       TRUE,
       ((p.id + e.id) % 5 = 0)
FROM tarefa t
JOIN ocorreu o ON o.id = t.ocorrencia
JOIN grupo g   ON g.id = o.grupo
JOIN participante p ON (p.id % 4) = (t.id % 4)
WHERE g.nome LIKE 'Trabalho:%';

-- ============================
-- COORDENOU (um coordenador por ocorrência, período dentro do semestre)
-- ============================
WITH sem_bounds AS (
  SELECT s.id AS semestre_id,
         CASE descricao
           WHEN '2024/2' THEN TIMESTAMPTZ '2024-08-01 00:00:00-03'
           WHEN '2025/1' THEN TIMESTAMPTZ '2025-03-01 00:00:00-03'
           WHEN '2025/2' THEN TIMESTAMPTZ '2025-08-01 00:00:00-03'
         END AS ini,
         CASE 
           WHEN '2024/2' THEN TIMESTAMPTZ '2024-12-20 23:59:59-03'
           WHEN '2025/1' THEN TIMESTAMPTZ '2025-07-15 23:59:59-03'
           WHEN '2025/2' THEN TIMESTAMPTZ '2025-12-20 23:59:59-03'
         END AS fim
  FROM semestre s
)
INSERT INTO coordenou (horas, participante, ocorrencia, inicio, fim, ativo, confirmado)
SELECT 4,
       ((o.id - 1) % 24) + 1       AS participante_id,
       o.id                        AS ocorrencia,
       b.ini,
       b.fim,
       TRUE,
       TRUE
FROM ocorreu o
JOIN sem_bounds b ON b.semestre_id = o.semestre;

-- ============================
-- CARGOS (por semestre: presidente e marketing)
-- *Sem campo “tipo”: indicado via comentários abaixo*
-- ============================
-- 2024/2 — PRESIDENTE
INSERT INTO cargo (horas, participante, semestre, inicio, fim, ativo, confirmado)
SELECT 8,  1, s.id, b.ini, b.fim, TRUE, TRUE
FROM semestre s
JOIN (
  SELECT '2024/2' AS descricao,
         TIMESTAMPTZ '2024-08-01 00:00:00-03' AS ini,
         TIMESTAMPTZ '2024-12-20 23:59:59-03' AS fim
) b ON b.descricao = s.descricao;

-- 2024/2 — MARKETING
INSERT INTO cargo (horas, participante, semestre, inicio, fim, ativo, confirmado)
SELECT 6,  2, s.id, b.ini, b.fim, TRUE, TRUE
FROM semestre s
JOIN (
  SELECT '2024/2' AS descricao,
         TIMESTAMPTZ '2024-08-01 00:00:00-03' AS ini,
         TIMESTAMPTZ '2024-12-20 23:59:59-03' AS fim
) b ON b.descricao = ;

-- 2025/1 — PRESIDENTE
INSERT INTO cargo (horas, participante, semestre, inicio, fim, ativo, confirmado)
SELECT 8,  3, s.id, b.ini, b.fim, TRUE, TRUE
FROM semestre s
JOIN (
  SELECT '2025/1' AS descricao,
         TIMESTAMPTZ '2025-03-01 00:00:00-03' AS ini,
         TIMESTAMPTZ '2025-07-15 23:59:59-03' AS fim
) b ON b.descricao = ;

-- 2025/1 — MARKETING
INSERT INTO cargo (horas, participante, semestre, inicio, fim, ativo, confirmado)
SELECT 6,  4, s.id, b.ini, b.fim, TRUE, TRUE
FROM semestre s
JOIN (
  SELECT '2025/1' AS descricao,
         TIMESTAMPTZ '2025-03-01 00:00:00-03' AS ini,
         TIMESTAMPTZ '2025-07-15 23:59:59-03' AS fim
) b ON b.descricao = ;

-- 2025/2 — PRESIDENTE
INSERT INTO cargo (horas, participante, semestre, inicio, fim, ativo, confirmado)
SELECT 8,  5, s.id, b.ini, b.fim, TRUE, TRUE
FROM semestre s
JOIN (
  SELECT '2025/2' AS descricao,
         TIMESTAMPTZ '2025-08-01 00:00:00-03' AS ini,
         TIMESTAMPTZ '2025-12-20 23:59:59-03' AS fim
) b ON b.descricao = ;

-- 2025/2 — MARKETING
INSERT INTO cargo (horas, participante, semestre, inicio, fim, ativo, confirmado)
SELECT 6,  6, s.id, b.ini, b.fim, TRUE, TRUE
FROM semestre s
JOIN (
  SELECT '2025/2' AS descricao,
         TIMESTAMPTZ '2025-08-01 00:00:00-03' AS ini,
         TIMESTAMPTZ '2025-12-20 23:59:59-03' AS fim
) b ON b.descricao = ;

-- ============================
-- HORAS (totais por participante x semestre)
-- regra: número sintético 5..24h
-- ============================
INSERT INTO horas (horas, participante, semestre)
SELECT ((p.id*3 + s.id) % 20) + 5 AS horas,
       p.id,
       s.id
FROM participante p
CROSS JOIN semestre s;
