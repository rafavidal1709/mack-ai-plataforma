SET search_path TO plataforma;

-- Descrição do procedure


CREATE OR REPLACE PROCEDURE horas_cargo(
  IN in_executado_por INT,  -- Todos os procedimentos devem receber este no primeiro parâmetro
  IN in_cargo         INT,
  IN in_horas        INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $procedure$
BEGIN
  IF in_horas < 0 THEN
    RAISE EXCEPTION 'A quantidade de horas nao pode ser negativa';
  END IF;

  UPDATE cargo
  SET horas = in_horas,
      confirmado = CASE
            WHEN in_horas = 0 OR in_horas IS NULL THEN FALSE
            ELSE TRUE
          END
  WHERE id = in_cargo;

  INSERT INTO log (rotulo, dados)
  VALUES (
    'horas_cargo',
    jsonb_build_object(
      'executado_por', in_executado_por,
      'cargo',         in_cargo,
      'horas',         in_horas
    )
  );
END;
$procedure$;
