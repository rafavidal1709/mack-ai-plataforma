-- Calcula e grava as horas do participante no semestre (retorna o total)
CREATE OR REPLACE FUNCTION calcular_horas_participante(
  in_participante BIGINT,
  in_semestre     TEXT
) RETURNS NUMERIC
LANGUAGE plpgsql AS
$$
DECLARE
  v_participou NUMERIC := 0;
  v_apresentou NUMERIC := 0;
  v_executou   NUMERIC := 0;
  v_cargo      NUMERIC := 0;
  out_horas    NUMERIC := 0;
BEGIN
  -- 1) Participou de encontros
  SELECT COALESCE(SUM(e.horas), 0) INTO v_participou
  FROM participou p
  JOIN encontro  e ON e.id = p.encontro
  JOIN ocorreu   o ON o.id = e.ocorrencia
  WHERE p.confirmado = TRUE
    AND p.participante = in_participante
    AND o.semestre = in_semestre;

  -- 2) Apresentou em encontros
  SELECT COALESCE(SUM(e.horas), 0) INTO v_apresentou
  FROM apresentou a
  JOIN encontro  e ON e.id = a.encontro
  JOIN ocorreu   o ON o.id = e.ocorrencia
  WHERE a.confirmado = TRUE
    AND a.participante = in_participante
    AND o.semestre = in_semestre;

  -- 3) Executou tarefas
  SELECT COALESCE(SUM(t.horas), 0) INTO v_executou
  FROM executou x
  JOIN tarefa   t ON t.id = x.tarefa
  JOIN ocorreu  o ON o.id = t.ocorrencia
  WHERE x.confirmado = TRUE
    AND x.participante = in_participante
    AND o.semestre = in_semestre;

  -- 4) Cargos no semestre
  SELECT COALESCE(SUM(c.horas), 0) INTO v_cargo
  FROM cargo c
  WHERE c.confirmado = TRUE
    AND c.participante = in_participante
    AND c.semestre = in_semestre;

  out_horas := v_participou + v_apresentou + v_executou + v_cargo;

  -- UPSERT em horas(participante, semestre, horas)
  INSERT INTO horas (horas, participante, semestre)
  VALUES (out_horas, in_participante, in_semestre)
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
    - cargo: semestre está na linha
    - participou/apresentou: semestre vem de encontro -> ocorreu
    - executou: semestre vem de tarefa -> ocorreu
  */

  IF TG_TABLE_NAME = 'cargo' THEN
    IF TG_OP = 'DELETE' THEN
      p := OLD.participante; s := OLD.semestre;
    ELSE
      p := NEW.participante; s := NEW.semestre;
    END IF;

  ELSIF TG_TABLE_NAME = 'participou' THEN
    IF TG_OP = 'DELETE' THEN
      p := OLD.participante;
      SELECT o.semestre INTO s
        FROM encontro e
        JOIN ocorreu  o ON o.id = e.ocorrencia
       WHERE e.id = OLD.encontro;
    ELSE
      p := NEW.participante;
      SELECT o.semestre INTO s
        FROM encontro e
        JOIN ocorreu  o ON o.id = e.ocorrencia
       WHERE e.id = NEW.encontro;
    END IF;

  ELSIF TG_TABLE_NAME = 'apresentou' THEN
    IF TG_OP = 'DELETE' THEN
      p := OLD.participante;
      SELECT o.semestre INTO s
        FROM encontro e
        JOIN ocorreu  o ON o.id = e.ocorrencia
       WHERE e.id = OLD.encontro;
    ELSE
      p := NEW.participante;
      SELECT o.semestre INTO s
        FROM encontro e
        JOIN ocorreu  o ON o.id = e.ocorrencia
       WHERE e.id = NEW.encontro;
    END IF;

  ELSIF TG_TABLE_NAME = 'executou' THEN
    IF TG_OP = 'DELETE' THEN
      p := OLD.participante;
      SELECT o.semestre INTO s
        FROM tarefa t
        JOIN ocorreu o ON o.id = t.ocorrencia
       WHERE t.id = OLD.tarefa;
    ELSE
      p := NEW.participante;
      SELECT o.semestre INTO s
        FROM tarefa t
        JOIN ocorreu o ON o.id = t.ocorrencia
       WHERE t.id = NEW.tarefa;
    END IF;

  ELSE
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- Se conseguimos (participante, semestre), recalcula
  IF p IS NOT NULL AND s IS NOT NULL THEN
    PERFORM calcular_horas_participante(p, s);
  END IF;

  -- AFTER: retorno é ignorado, mas mantenho por padrão
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
