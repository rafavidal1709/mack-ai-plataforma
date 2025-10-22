SET search_path TO plataforma;

-- agendar_encontro(executado_por, ocorrencia, inicio, fim, tema, resumo)
-- Cria uma linha na tabela 'encontro', resumo é opcional com default null.
-- Se fim for null, o valor padrão é inicio + 1 hora.
-- Os encontros devem ter entre 30 minutos e 6 horas de duração.


CREATE OR REPLACE PROCEDURE agendar_encontro(
  IN in_executado_por INT,
  IN in_ocorrencia    INT,
  IN in_inicio        TIMESTAMPTZ,
  IN in_fim           TIMESTAMPTZ,
  IN in_tema          VARCHAR(255),
  IN in_resumo        TEXT DEFAULT NULL
)
LANGUAGE plpgsql
SET search_path = plataforma
AS $$
DECLARE
  v_fim TIMESTAMPTZ := NULL;
BEGIN
  IF in_inicio IS NULL THEN
    RAISE EXCEPTION 'O horário de início não pode ser nulo';
  ELSIF in_fim IS NULL THEN
    v_fim := in_inicio + INTERVAL '1 hour';
  ELSE
    v_fim := in_fim;
  END IF;

  IF NOT v_fim - in_inicio >= INTERVAL '30 minutes' THEN
    RAISE EXCEPTION 'O horário de término deve ser pelo menos 30 minutos após início';
  ELSIF v_fim - in_inicio >= INTERVAL '6 hours' THEN
    RAISE EXCEPTION 'O horário de término não pode ser mais de 6 horas após início';
  END IF;

  IF in_resumo IS NULL THEN                                             -- Neste caso esse IF não era necessário, mas fique atento ao valor DEFAULT da tabela.
    INSERT INTO plataforma.encontro (ocorrencia, inicio, fim, tema)     -- Se o valor DEFAULT da tabela **não** for NULL este IF é necessário.
    VALUES (in_ocorrencia, in_inicio, v_fim, in_tema);
  ELSE
    INSERT INTO plataforma.encontro (ocorrencia, inicio, fim, tema, resumo)   -- Veja que o in_executado_por não entra aqui
    VALUES (in_ocorrencia, in_inicio, v_fim, in_tema, in_resumo);
  END IF;

  INSERT INTO plataforma.log (rotulo, dados)
  VALUES (
    'agendar_encontro',                     -- Mesmo nome do procedimento
    jsonb_build_object(
      'executado_por', in_executado_por,
      'ocorrencia',    in_ocorrencia,
      'inicio',        in_inicio,
      'fim',           in_fim,
      'tema',          in_tema,
      'resumo',        in_resumo            -- Os parâmetros opcionais devem ser incluídos aqui
    )
  );
END;
$$;
