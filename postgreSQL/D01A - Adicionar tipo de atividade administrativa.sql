SET search_path TO plataforma;

-- Descrição do procedure

CREATE OR REPLACE PROCEDURE adicionar_tipo_cargo(
  IN in_executado_por INT,
  IN in_nome          VARCHAR,
  IN in_descricao     TEXT DEFAULT NULL,
  IN in_horas         INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $procedure$
BEGIN
  IF in_horas IS NOT NULL AND in_horas < 0 THEN
    RAISE EXCEPTION 'A quantidade de horas nao pode ser negativa';
  END IF;

  INSERT INTO tipo_cargo (nome, descricao, horas)
  VALUES (in_nome, in_descricao, in_horas);

  INSERT INTO log (rotulo, dados)
  VALUES (
    'adicionar_tipo_cargo',
    jsonb_build_object(
      'executado_por', in_executado_por,
      'nome',          in_nome,
      'descricao',     in_descricao,
      'horas',         in_horas
    )
  );
END;
$procedure$;
