SET search_path TO plataforma;

-- Descrição do procedure


CREATE OR REPLACE PROCEDURE vai_apresentar(
  IN in_executado_por INT,  -- Todos os procedimentos devem receber este no primeiro parâmetro
  IN in_participante         INT,
  IN in_encontro        INT
)
LANGUAGE plpgsql
AS $procedure$
BEGIN
    -- ... suas operações aqui ...
  INSERT INTO apresentou (participante, encontro)
  VALUES (in_participante, in_encontro);

  INSERT INTO log (rotulo, dados)
  VALUES (
    'vai_apresentar',                  -- Mesmo nome do procedimento
    jsonb_build_object(
      'executado_por', in_executado_por,
      'participante',        in_participante,
      'encontro',        in_encontro
    )
  );
END;
$procedure$;
