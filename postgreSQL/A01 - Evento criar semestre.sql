SET search_path TO plataforma;

CREATE OR REPLACE PROCEDURE criar_semestre(
  IN in_executado_por INT DEFAULT NULL,
  IN in_descricao     VARCHAR(255)
)
LANGUAGE plpgsql
SET search_path = plataforma
AS $$
DECLARE
  v_ano INT;
  v_p   INT;
BEGIN
  -- Checagens de nulidade e formato
  IF in_descricao IS NULL THEN
    RAISE EXCEPTION 'Descrição não pode ser NULL. Use o formato YYYY/P (ex.: 2025/2).' USING ERRCODE = '22004';
  END IF;

  IF in_descricao !~ '^[0-9]{4}/[12]$' THEN
    RAISE EXCEPTION 'Descrição inválida: "%". Use o formato YYYY/P (ex.: 2025/2).', in_descricao
      USING ERRCODE = '22023';
  END IF;

  v_ano := (split_part(in_descricao, '/', 1))::int;
  v_p   := (split_part(in_descricao, '/', 2))::int;  -- já é 1 ou 2 pelo regex

  IF v_ano <= 2015 THEN
    RAISE EXCEPTION 'Ano inválido (%). Deve ser maior que 2015.', v_ano
      USING ERRCODE = '22007';
  END IF;

  IF v_ano > (EXTRACT(YEAR FROM CURRENT_DATE))::int + 1 THEN
    RAISE EXCEPTION 'Ano inválido (%). Deve ser menor ou igual ao ano atual + 1.', v_ano
      USING ERRCODE = '22007';
  END IF;

  -- Se passou pelas validações, insere
  INSERT INTO semestre (descricao)
  VALUES (in_descricao);

  -- Log de auditoria
  INSERT INTO plataforma.log (rotulo, dados)
  VALUES (
    'criar_semestre',
    jsonb_build_object(
      'executado_por', in_executado_por,
      'descricao',     in_descricao
    )
  );
END;
$$;
