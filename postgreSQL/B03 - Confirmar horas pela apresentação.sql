SET search_path TO plataforma;

-- =====================================================
-- B03. Confirmar horas pela apresentação
-- Procedure: confirmar_apresentacao(executado_por, apresentou_id, horas)
-- Por: Vitoria Lima
-- Descrição:
--   Retorna erro se in_horas for negativo e não continua o procedimento.
--   Atualiza a tabela apresentou, definindo confirmado como TRUE.
--   Horas é opcional: se não for NULL, atualiza; caso contrário, mantém.
-- =====================================================

CREATE OR REPLACE PROCEDURE confirmar_apresentacao(
    IN in_executado_por INT,
    IN in_apresentou_id INT,
    IN in_horas NUMERIC DEFAULT NULL
)
LANGUAGE plpgsql
SET search_path = plataforma
AS $$
BEGIN
    IF in_horas IS NOT NULL AND in_horas < 0 THEN
        RAISE EXCEPTION 'O valor de horas não pode ser negativo.';
    END IF;

    IF in_horas IS NOT NULL THEN
        UPDATE apresentou
        SET confirmado = TRUE,
            horas = in_horas
        WHERE id = in_apresentou_id;
    ELSE
        UPDATE apresentou
        SET confirmado = TRUE
        WHERE id = in_apresentou_id;
    END IF;
END;
$$;


