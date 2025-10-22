SET search_path TO plataforma;

CREATE OR REPLACE PROCEDURE adicionar_cargo(
  IN in_executado_por INT,
  IN in_tipo          VARCHAR(255),
  IN in_participante  INT,
  IN in_semestre      INT,
  IN in_ocorrencia_id INT DEFAULT NULL,
  IN in_inicio        TIMESTAMPTZ DEFAULT NULL,
  IN in_horas         INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    semestre_ocorreu INT;
BEGIN
    IF in_horas IS NOT NULL AND in_horas < 0 THEN 
        RAISE EXCEPTION 'O número de horas não pode ser negativo';
    END IF;

    IF in_ocorrencia_id IS NOT NULL THEN
        SELECT semestre INTO semestre_ocorreu FROM ocorreu WHERE id = in_ocorrencia_id;

        IF semestre_ocorreu IS NULL THEN
            RAISE EXCEPTION 'Ocorrencia ID % não encontrada.', in_ocorrencia_id;
        END IF;

        IF semestre_ocorreu <> in_semestre THEN
            RAISE EXCEPTION 'O semestre da ocorrência (%) não corresponde ao semestre especificado (%).', semestre_ocorreu, in_semestre;
        END IF;
    END IF;

    IF in_inicio IS NULL THEN
        INSERT INTO cargo (tipo, horas, participante, semestre, ocorrencia, ativo, confirmado)
        VALUES (in_tipo::tipo_cargo, in_horas, in_participante, in_semestre, in_ocorrencia_id, TRUE, FALSE);
    ELSE 
        INSERT INTO cargo (tipo, horas, participante, semestre, inicio, ocorrencia, ativo, confirmado)
        VALUES (in_tipo::tipo_cargo, in_horas, in_participante, in_semestre, in_inicio, in_ocorrencia_id, TRUE, FALSE);
    END IF;

    INSERT INTO log (rotulo, dados)
    VALUES (
        'adicionar_cargo',
        jsonb_build_object(
            'executado_por', in_executado_por,
            'tipo',          in_tipo,
            'participante',  in_participante,
            'semestre',      in_semestre,
            'ocorrencia_id', in_ocorrencia_id,
            'inicio',        in_inicio,
            'horas',         in_horas
        )
    );
END;
$$;
