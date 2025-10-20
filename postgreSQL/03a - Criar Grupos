SET search_path TO plataforma;

-- Descrição do procedure


CREATE OR REPLACE PROCEDURE criar_grupo(
  IN in_executado_por INT,
  IN in_nome VARCHAR(255),
  IN in_tipo tipo_grupo,      
  IN in_descricao TEXT,         
  IN in_param INT DEFAULT NULL,
  IN in_param2 TEXT DEFAULT NULL
)
LANGUAGE plpgsql
SET search_path = plataforma
AS $$
BEGIN
    -- ... suas operações aqui ...

  INSERT INTO plataforma.grupo (nome, tipo, descricao)
  VALUES (
    in_nome,
    in_tipo,
    in_descricao
  )
  ON CONFLICT (nome) DO NOTHING;

  INSERT INTO plataforma.log (rotulo, dados)
  VALUES (
    'criar_grupo',
    jsonb_build_object(
    'executado_por', in_executado_por,
    'nome',          in_nome,
    'tipo',          in_tipo,
    'descricao',     in_descricao
    )
  );
END;
$$;
