SET search_path TO plataforma;

-- Descrição do procedure


CREATE OR REPLACE PROCEDURE cancelar_apresentar(
  IN in_executado_por INT,  -- Todos os procedimentos devem receber este no primeiro parâmetro
  IN in_participante  INT,
  IN in_encontro      INT
)
LANGUAGE plpgsql
AS $procedure$

BEGIN
  
  UPDATE apresentou
  SET valido = FALSE
  WHERE participante = in_participante AND encontro = in_encontro;

  INSERT INTO log (rotulo, dados)
  VALUES (
    'cancelar_apresentar',                  -- Mesmo nome do procedimento
    jsonb_build_object(
      'executado_por',   in_executado_por,
      'participante',    in_participante,
      'encontro',        in_encontro
    )
  );
END;
$procedure$;
