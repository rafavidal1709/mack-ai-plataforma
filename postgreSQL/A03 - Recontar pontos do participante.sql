SET search_path TO plataforma;

-- Calcula e grava as horas do participante no semestre (retorna o total)
CREATE OR REPLACE FUNCTION calcular_horas_participante(
  in_participante BIGINT,
  in_semestre     TEXT
) RETURNS NUMERIC
LANGUAGE plpgsql AS
$$
DECLARE
  v_semestre_id INT;
  v_participou NUMERIC := 0;
  v_apresentou NUMERIC := 0;
  v_executou   NUMERIC := 0;
  v_cargo      NUMERIC := 0;
  out_horas    NUMERIC := 0;
BEGIN
  -- obter o ID do semestre a partir da descricao
  SELECT id INTO v_semestre_id
  FROM semestre
  WHERE descricao = in_semestre;

  IF v_semestre_id IS NULL THEN
    RAISE EXCEPTION 'Semestre "%" não encontrado', in_semestre;
  END IF;

  -- 1) Participou de encontros (usa p.horas)
  SELECT COALESCE(SUM(p.horas), 0) INTO v_participou
  FROM participou p
  JOIN encontro  e ON e.id = p.encontro
  JOIN ocorreu   o ON o.id = e.ocorrencia
  WHERE p.confirmado = TRUE
    AND p.participante = in_participante
    AND o.semestre = v_semestre_id;

  -- 2) Apresentou em encontros (usa a.horas)
  SELECT COALESCE(SUM(a.horas), 0) INTO v_apresentou
  FROM apresentou a
  JOIN encontro  e ON e.id = a.encontro
  JOIN ocorreu   o ON o.id = e.ocorrencia
  WHERE a.confirmado = TRUE
    AND a.participante = in_participante
    AND o.semestre = v_semestre_id;

  -- 3) Executou tarefas (usa x.horas)
  SELECT COALESCE(SUM(x.horas), 0) INTO v_executou
  FROM executou x
  JOIN tarefa   t ON t.id = x.tarefa
  JOIN ocorreu  o ON o.id = t.ocorrencia
  WHERE x.confirmado = TRUE
    AND x.participante = in_participante
    AND o.semestre = v_semestre_id;

  -- 4) Cargos no semestre (usa c.horas)
  SELECT COALESCE(SUM(c.horas), 0) INTO v_cargo
  FROM cargo c
  WHERE c.confirmado = TRUE
    AND c.participante = in_participante
    AND c.semestre = v_semestre_id;

  out_horas := v_participou + v_apresentou + v_executou + v_cargo;

  -- UPSERT em horas(participante, semestre, horas)
  INSERT INTO horas (horas, participante, semestre)
  VALUES (out_horas, in_participante, v_semestre_id)
  ON CONFLICT (participante, semestre)
  DO UPDATE SET horas = EXCLUDED.horas;

  RETURN out_horas;
END;
$$;

CREATE OR REPLACE FUNCTION trg_recalc_horas() RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  p BIGINT;
  s TEXT;
BEGIN
  /*
    - cargo: semestre está na linha (precisa converter para descricao)
    - participou/apresentou: semestre vem de encontro -> ocorreu -> semestre.descricao
    - executou: semestre vem de tarefa -> ocorreu -> semestre.descricao
  */

  IF TG_TABLE_NAME = 'cargo' THEN
    IF TG_OP = 'DELETE' THEN
      p := OLD.participante;
      SELECT s2.descricao INTO s
      FROM semestre s2
      WHERE s2.id = OLD.semestre;
    ELSE
      p := NEW.participante;
      SELECT s2.descricao INTO s
      FROM semestre s2
      WHERE s2.id = NEW.semestre;
    END IF;

  ELSIF TG_TABLE_NAME = 'participou' THEN
    IF TG_OP = 'DELETE' THEN
      p := OLD.participante;
      SELECT s2.descricao INTO s
        FROM encontro e
        JOIN ocorreu  o ON o.id = e.ocorrencia
        JOIN semestre s2 ON s2.id = o.semestre
       WHERE e.id = OLD.encontro;
    ELSE
      p := NEW.participante;
      SELECT s2.descricao INTO s
        FROM encontro e
        JOIN ocorreu  o ON o.id = e.ocorrencia
        JOIN semestre s2 ON s2.id = o.semestre
       WHERE e.id = NEW.encontro;
    END IF;

  ELSIF TG_TABLE_NAME = 'apresentou' THEN
    IF TG_OP = 'DELETE' THEN
      p := OLD.participante;
      SELECT s2.descricao INTO s
        FROM encontro e
        JOIN ocorreu  o ON o.id = e.ocorrencia
        JOIN semestre s2 ON s2.id = o.semestre
       WHERE e.id = OLD.encontro;
    ELSE
      p := NEW.participante;
      SELECT s2.descricao INTO s
        FROM encontro e
        JOIN ocorreu  o ON o.id = e.ocorrencia
        JOIN semestre s2 ON s2.id = o.semestre
       WHERE e.id = NEW.encontro;
    END IF;

  ELSIF TG_TABLE_NAME = 'executou' THEN
    IF TG_OP = 'DELETE' THEN
      p := OLD.participante;
      SELECT s2.descricao INTO s
        FROM tarefa t
        JOIN ocorreu o ON o.id = t.ocorrencia
        JOIN semestre s2 ON s2.id = o.semestre
       WHERE t.id = OLD.tarefa;
    ELSE
      p := NEW.participante;
      SELECT s2.descricao INTO s
        FROM tarefa t
        JOIN ocorreu o ON o.id = t.ocorrencia
        JOIN semestre s2 ON s2.id = o.semestre
       WHERE t.id = NEW.tarefa;
    END IF;

  ELSE
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- Se conseguimos (participante, semestre-descricao), recalcula
  IF p IS NOT NULL AND s IS NOT NULL THEN
    PERFORM calcular_horas_participante(p, s);
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;

---------------
-- TRIGGERS: --
---------------
-- participou
DROP TRIGGER IF EXISTS tr_participou_recalc ON participou;
CREATE TRIGGER tr_participou_recalc
AFTER INSERT OR UPDATE OR DELETE ON participou
FOR EACH ROW EXECUTE FUNCTION trg_recalc_horas();

-- apresentou
DROP TRIGGER IF EXISTS tr_apresentou_recalc ON apresentou;
CREATE TRIGGER tr_apresentou_recalc
AFTER INSERT OR UPDATE OR DELETE ON apresentou
FOR EACH ROW EXECUTE FUNCTION trg_recalc_horas();

-- executou
DROP TRIGGER IF EXISTS tr_executou_recalc ON executou;
CREATE TRIGGER tr_executou_recalc
AFTER INSERT OR UPDATE OR DELETE ON executou
FOR EACH ROW EXECUTE FUNCTION trg_recalc_horas();

-- cargo
DROP TRIGGER IF EXISTS tr_cargo_recalc ON cargo;
CREATE TRIGGER tr_cargo_recalc
AFTER INSERT OR UPDATE OR DELETE ON cargo
FOR EACH ROW EXECUTE FUNCTION trg_recalc_horas();
