SET search_path TO plataforma;

-- Descrição do procedure


CREATE OR REPLACE PROCEDURE criar_tarefa(
  IN in_executado_por INT,  -- Todos os procedimentos devem receber este no primeiro parâmetro
  IN in_ocorrencia    INT,
  IN in_tema          VARCHAR,
  IN in_horas         INT DEFAULT 1,
  IN in_replicas      INT DEFAULT 1,
  IN in_inicio TIMESTAMPTZ    DEFAULT NULL,
  IN in_fim TIMESTAMPTZ       DEFAULT NULL,
  IN in_resumo TEXT           DEFAULT NULL,
  IN in_video VARCHAR         DEFAULT NULL
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
  v_inicio TIMESTAMPTZ;
BEGIN
  IF in_horas < 0 THEN
    RAISE EXCEPTION 'A quantidade de horas nao pode ser negativa';
  END IF;
  IF in_inicio IS NULL THEN
    v_inicio := NOW();
  ELSE
    v_inicio := in_inicio;
  END IF;

  INSERT INTO tarefa (ocorrencia, tema, horas, replicas, inicio, prazo, descricao, video)
  VALUES (in_ocorrencia, in_tema, in_horas, in_replicas, v_inicio, in_fim, in_resumo, in_video);

  INSERT INTO log (rotulo, dados)
  VALUES (
    'criar_tarefa',
    jsonb_build_object(
      'executado_por', in_executado_por,
      'ocorrencia', in_ocorrencia,
      'tema', in_tema,
      'horas', in_horas,
      'replicas', in_replicas,
      'inicio', v_inicio,
      'fim', in_fim,
      'resumo', in_resumo,
      'video', in_video
    )
  );
END;
$procedure$;
