SET search_path TO plataforma;

-- Descrição do procedure


CREATE OR REPLACE PROCEDURE inscrever_tarefa(
  IN in_executado_por INT,  -- Todos os procedimentos devem receber este no primeiro parâmetro
  IN in_participante         INT,
  IN in_tarefa        INT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_executou_contador INT;
  v_replica_contador INT;
  v_horas_tarefa INT;
  v_ja_inscrito BOOLEAN;
BEGIN

    SELECT EXISTS(
    SELECT 1 FROM executou
    WHERE participante = in_participante AND tarefa = in_tarefa
    ) INTO v_ja_inscrito;

    IF v_ja_inscrito THEN
      RAISE EXCEPTION 'Ja inscrito';
      END IF;

    SELECT COUNT(*) INTO v_executou_contador
    FROM executou
    WHERE tarefa = in_tarefa;

    SELECT replicas, horas INTO v_replica_contador, v_horas_tarefa
    FROM tarefa
    WHERE id = in_tarefa;

    IF v_executou_contador >= v_replica_contador THEN
      RAISE EXCEPTION 'Numero total de incricoes atingida';
      END IF;

    INSERT INTO executou(horas, participante, tarefa)
    VALUES(v_horas_tarefa, in_participante, in_tarefa);

  INSERT INTO log (rotulo, dados)
  VALUES (
    'inscrever_tarefa',                  -- Mesmo nome do procedimento
    jsonb_build_object(
      'executado_por', in_executado_por,
      'participante_id',        in_participante,
      'tarefa_id',        in_tarefa
    )
  );
END;
$$;
