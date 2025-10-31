SET search_path TO plataforma;

CREATE OR REPLACE PROCEDURE criar_participante(
  IN in_executado_por  INT,
  IN in_ra             VARCHAR(255),
  IN in_nome           VARCHAR(255)
)
LANGUAGE plpgsql
SET search_path = plataforma
AS $$
DECLARE
  v_ra   text;
  v_nome text;
BEGIN
  -- Normalização básica (não altera conteúdo interno)
  v_ra   := btrim(in_ra);
  v_nome := btrim(in_nome);

  -- Presença
  IF v_ra IS NULL OR v_nome IS NULL OR v_ra = '' OR v_nome = '' THEN
    RAISE EXCEPTION 'É necessário inserir RA e nome.'
      USING ERRCODE = '22004';
  END IF;

  -- RA: exatamente 8 dígitos
  IF v_ra !~ '^[0-9]{8}$' THEN
    RAISE EXCEPTION 'RA inválido: "%". Deve conter exatamente 8 dígitos (0–9).', v_ra
      USING ERRCODE = '22023';
  END IF;

  -- Nome: > 5 caracteres (desconsiderando espaços das extremidades) e pelo menos um espaço interno
  IF length(v_nome) <= 5 THEN
    RAISE EXCEPTION 'Nome inválido: muito curto após trim. Deve ter mais de 5 caracteres.'
      USING ERRCODE = '22023';
  END IF;

  IF position(' ' in v_nome) = 0 THEN
    RAISE EXCEPTION 'Nome inválido: deve conter pelo menos um espaço (nome e sobrenome, por exemplo).'
      USING ERRCODE = '22023';
  END IF;

  -- Colapsar múltiplos espaços internos:
  v_nome := regexp_replace(v_nome, '\s+', ' ', 'g');

  -- Duplicidade de RA (mensagem amigável)
  IF EXISTS (SELECT 1 FROM participante WHERE ra = v_ra) THEN
    RAISE EXCEPTION 'RA "%" já cadastrado.', v_ra
      USING ERRCODE = '23505';
  END IF;

  -- Inserção com valores normalizados
  INSERT INTO participante (ra, nome)
  VALUES (v_ra, v_nome);

  -- Log de auditoria
  INSERT INTO log (rotulo, dados)
  VALUES (
    'criar_participante',
    jsonb_build_object(
      'executado_por',  in_executado_por,
      'ra',             v_ra,
      'nome',           v_nome
    )
  );
END;
$$;
