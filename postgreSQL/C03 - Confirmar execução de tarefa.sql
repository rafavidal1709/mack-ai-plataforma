SET search_path TO plataforma;

-- Descrição do procedure


CREATE OR REPLACE PROCEDURE confirmar_execucao(
  IN in_executado_por       INT,  
  IN in_executou_id         INT,
  IN in_horas               INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $procedure$

BEGIN

  IF in_horas < 0 THEN
    RAISE EXCEPTION 'A quantidade de horas nao pode ser negativa';
  END IF;
  IF in_horas IS NULL THEN
    UPDATE executou
    SET confirmado = TRUE
    WHERE id = in_executou_id;
  ELSE
    UPDATE executou
    SET confirmado = TRUE,
        horas = in_horas
    WHERE id = in_executou_id;
  END IF;

  INSERT INTO log (rotulo, dados)
  VALUES (
    'confirmar_execucao',                  -- Mesmo nome do procedimento
    jsonb_build_object(
      'executado_por', in_executado_por,
      'executou_id',        in_executou_id,
      'horas',        in_horas
    )
  );
END;
$procedure$;
