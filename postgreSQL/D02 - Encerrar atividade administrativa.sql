SET search_path TO plataforma;

-- Descrição do procedure


CREATE OR REPLACE PROCEDURE encerrar_cargo(
  IN in_executado_por INT,  -- Todos os procedimentos devem receber este no primeiro parâmetro
  IN in_cargo         INT,
  IN in_horas        INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
  
BEGIN
  IF in_horas < 0 THEN
    RAISE EXCEPTION 'A quantidade de horas nao pode ser negativa';
  END IF;

  IF in_horas IS NOT NULL THEN
    UPDATE cargo 
    SET ativo = FALSE,
      horas = in_horas
    WHERE id = in_cargo;
  ELSE 
    UPDATE cargo
    SET ativo = FALSE
    WHERE id = in_cargo;
  END IF;

  UPDATE cargo
  SET confirmado = TRUE
  WHERE id = in_cargo AND horas IS NOT NULL AND horas != 0;  

  INSERT INTO log (rotulo, dados)
  VALUES (
    'nome_da_procedure',                  -- Mesmo nome do procedimento
    jsonb_build_object(
      'executado_por', in_executado_por,
      'cargo',        in_cargo,
      'horas',        in_horas
    )
  );
END;
$procedure$;
