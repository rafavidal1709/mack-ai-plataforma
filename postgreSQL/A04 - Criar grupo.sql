SET search_path TO plataforma;

-- Cria uma linha na tabela 'grupo', tipo e descrição são opcionais pois tem valor default.
-- por Kaique Barros

CREATE OR REPLACE PROCEDURE criar_grupo(
  IN in_executado_por INT,
  IN in_nome VARCHAR(255),
  IN in_tipo tipo_grupo DEFAULT NULL,      -- Também tem default NULL porque tem valor DEAFAULT na estrutura do DB
  IN in_descricao TEXT DEFAULT NULL        -- Também tem default NULL porque tem valor DEAFAULT na estrutura do DB
)
LANGUAGE plpgsql
SET search_path = plataforma
AS $$
BEGIN
  IF in_tipo IS NULL THEN       -- criar a condicional, pois o valor padrão não é NULL na arquitetura da tabela
    INSERT INTO plataforma.grupo (nome, descricao)
    VALUES (
      in_nome,
      in_descricao
    )
    ON CONFLICT (nome) DO NOTHING;
  ELSE
    INSERT INTO plataforma.grupo (nome, tipo, descricao)
    VALUES (
      in_nome,
      in_tipo,
      in_descricao
    )
    ON CONFLICT (nome) DO NOTHING;
  END IF;

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
