-- Reiniciar `schema`
DROP SCHEMA IF EXISTS plataforma CASCADE;
CREATE SCHEMA plataforma;
SET search_path TO plataforma;

-- Função e trigger para atualizar "atualizado" automaticamente
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.atualizado := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tabelas
CREATE TABLE semestre(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    descricao     VARCHAR(255) NOT NULL UNIQUE
                  CHECK (
                    descricao ~ '^[0-9]{4}/[12]$'
                    AND split_part(descricao,'/',1)::int > 2015
                    AND split_part(descricao,'/',1)::int <= (EXTRACT(YEAR FROM CURRENT_DATE))::int + 1
                  ),
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TYPE tipo_grupo AS ENUM ('estudo', 'trabalho', 'pesquisa');

CREATE TABLE grupo(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome          VARCHAR(255) NOT NULL UNIQUE,
    tipo          tipo_grupo NOT NULL DEFAULT 'estudo',
    descricao     TEXT NULL,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE ocorreu(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    semestre      BIGINT NOT NULL REFERENCES semestre(id),
    grupo         BIGINT NOT NULL REFERENCES grupo(id),
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ocorreu_semestre_grupo UNIQUE (semestre, grupo)
);

CREATE TABLE encontro(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ocorrencia    BIGINT NOT NULL REFERENCES ocorreu(id),
    inicio        TIMESTAMPTZ NOT NULL,
    fim           TIMESTAMPTZ NOT NULL,
    valido        BOOLEAN NOT NULL DEFAULT TRUE,
    tema          VARCHAR(255) NOT NULL,
    resumo        TEXT DEFAULT NULL,
    video         VARCHAR(255) NULL UNIQUE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_encontro_ocorrencia_inicio UNIQUE (ocorrencia, inicio),
    CONSTRAINT uq_encontro_ocorrencia_tema   UNIQUE (ocorrencia, tema)
);

CREATE TABLE tarefa(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ocorrencia    BIGINT NOT NULL REFERENCES ocorreu(id),
    horas         INT NOT NULL DEFAULT 1,
    replicas      INT NOT NULL DEFAULT 1,
    inicio        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    prazo         TIMESTAMPTZ DEFAULT NULL,
    valido        BOOLEAN NOT NULL DEFAULT TRUE,
    tema          VARCHAR(255) NOT NULL,
    descricao     TEXT DEFAULT NULL,
    video         VARCHAR(255) NULL UNIQUE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tarefa_ocorrencia_inicio UNIQUE (ocorrencia, inicio),
    CONSTRAINT uq_tarefa_ocorrencia_tema   UNIQUE (ocorrencia, tema)
);

CREATE TABLE participante(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ra            VARCHAR(255) DEFAULT NULL UNIQUE
                  CHECK (
                    ra ~ '^[0-9]{8}$'           -- exatamente 8 dígitos numéricos
                  ),
    nome          VARCHAR(255) NOT NULL
                  CHECK (
                    length(btrim(nome)) > 5      -- mais de 5 caracteres após trim
                    AND position(' ' in btrim(nome)) > 0  -- pelo menos um espaço interno
                  ),
    senha         VARCHAR(255) DEFAULT NULL,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE dispositivo(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dados         JSONB DEFAULT NULL,
    codigo        VARCHAR(255) NOT NULL,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE sessao(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    participante  BIGINT NOT NULL REFERENCES participante(id),
    dispositivo   BIGINT NOT NULL REFERENCES dispositivo(id),
    CONSTRAINT uq_sessao_participante_dispositivo UNIQUE (participante, dispositivo)
);

CREATE TABLE acesso(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dispositivo   BIGINT NOT NULL REFERENCES dispositivo(id),
    participante  BIGINT DEFAULT NULL REFERENCES participante(id),
    url           VARCHAR(1023) NOT NULL,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE email(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE
                  CHECK (
                      email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
                  ),
    participante  BIGINT DEFAULT NULL REFERENCES participante(id),
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE codigo_email(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email         BIGINT NOT NULL REFERENCES email(id),
    dispositivo   BIGINT NOT NULL REFERENCES dispositivo(id),
    codigo        VARCHAR(255) NOT NULL,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE participou(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horas         INT NOT NULL DEFAULT 1,
    participante  BIGINT NOT NULL REFERENCES participante(id),
    encontro      BIGINT NOT NULL REFERENCES encontro(id),
    confirmado    BOOLEAN NOT NULL DEFAULT FALSE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_participou_participante_encontro UNIQUE (participante, encontro)
);

CREATE TABLE apresentou(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horas         INT NOT NULL DEFAULT 1,
    participante  BIGINT NOT NULL REFERENCES participante(id),
    encontro      BIGINT NOT NULL REFERENCES encontro(id),
    valido        BOOLEAN NOT NULL DEFAULT TRUE,
    confirmado    BOOLEAN NOT NULL DEFAULT FALSE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_apresentou_participante_encontro UNIQUE (participante, encontro)
);

CREATE TABLE executou(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horas         INT NOT NULL DEFAULT 1,
    participante  BIGINT NOT NULL REFERENCES participante(id),
    tarefa        BIGINT NOT NULL REFERENCES tarefa(id),
    valido        BOOLEAN NOT NULL DEFAULT FALSE,
    confirmado    BOOLEAN NOT NULL DEFAULT FALSE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TYPE tipo_abrangencia AS ENUM ('ampla', 'restrita');

CREATE TABLE tipo_cargo(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome          VARCHAR(255) NOT NULL UNIQUE
                  CHECK (
                      length(regexp_replace(nome, '\s+', '', 'g')) > 2
                  ),
    abrangencia   tipo_abrangencia NOT NULL DEFAULT 'ampla',
    descricao     TEXT DEFAULT NULL,
    horas         INT DEFAULT NULL,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE permissao(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome          VARCHAR(255) NOT NULL UNIQUE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE concessao(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    permissao     BIGINT NOT NULL REFERENCES permissao(id),
    tipo_cargo    BIGINT DEFAULT NULL REFERENCES tipo_cargo(id),
    abrangencia   tipo_abrangencia NOT NULL DEFAULT 'ampla',
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE cargo(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horas         INT DEFAULT NULL,
    tipo          BIGINT NOT NULL REFERENCES tipo_cargo(id),
    participante  BIGINT NOT NULL REFERENCES participante(id),
    semestre      BIGINT NOT NULL REFERENCES semestre(id),
    grupo         BIGINT DEFAULT NULL REFERENCES grupo(id),    -- Usado caso o cargo seja um coordenador de um grupo
    inicio        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fim           TIMESTAMPTZ DEFAULT NULL,
    ativo         BOOLEAN NOT NULL DEFAULT TRUE,
    confirmado    BOOLEAN NOT NULL DEFAULT FALSE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_cargo_tipo_participante_semestre_ocorrencia_inicio UNIQUE (tipo, participante, semestre, ocorrencia, inicio)
);

CREATE TABLE horas(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horas         INT NOT NULL DEFAULT 0,
    participante  BIGINT NOT NULL REFERENCES participante(id),
    semestre      BIGINT NOT NULL REFERENCES semestre(id),
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_horas_participante_semestre UNIQUE (participante, semestre)
);

CREATE TABLE log(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tempo         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    rotulo        VARCHAR(255) NOT NULL,
    dados         JSONB NOT NULL
);

-- Triggers de "updated_at" para cada tabela que tem a coluna "atualizado"
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'atualizado'
          AND table_schema = 'plataforma'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%I_set_updated_at
             BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
            r.table_name,
            r.table_name
        );
    END LOOP;
END;
$$;

SET plataforma.environment_mode = 'development';

CREATE OR REPLACE FUNCTION verificar_permissao(
    p_participante BIGINT,
    p_permissao BIGINT,
    p_grupo BIGINT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_mode TEXT;
    v_ok BOOLEAN;
BEGIN

    -- ler modo do ambiente
    BEGIN
        v_mode := current_setting('plataforma.environment_mode');
    EXCEPTION
        WHEN others THEN
            v_mode := 'production';
    END;

    -- ambiente de desenvolvimento libera tudo
    IF v_mode = 'development' THEN
        RETURN;
    END IF;

    ----------------------------------------------------------------
    -- regra 1: permissao global (tipo_cargo NULL)
    ----------------------------------------------------------------

    IF EXISTS (
        SELECT 1
        FROM concessao c
        WHERE c.permissao = p_permissao
        AND c.tipo_cargo IS NULL
        AND c.abrangencia = 'ampla'
    ) THEN
        RETURN;
    END IF;

    ----------------------------------------------------------------
    -- regra 2: verificar cargos ativos
    ----------------------------------------------------------------

    SELECT TRUE
    INTO v_ok
    FROM cargo cg
    JOIN concessao cs
        ON cs.tipo_cargo = cg.tipo
    WHERE
        cg.participante = p_participante
        AND cg.ativo = TRUE
        AND cg.confirmado = TRUE
        AND (cg.fim IS NULL OR cg.fim > NOW())
        AND cg.inicio <= NOW()
        AND cs.permissao = p_permissao
        AND (
            -- abrangência ampla
            cs.abrangencia = 'ampla'

            OR

            -- abrangência restrita
            (
                cs.abrangencia = 'restrita'
                AND cg.grupo IS NOT NULL
                AND cg.grupo = p_grupo
            )
        )
    LIMIT 1;

    IF v_ok THEN
        RETURN;
    END IF;

    ----------------------------------------------------------------
    -- acesso negado
    ----------------------------------------------------------------

    RAISE EXCEPTION 'Acesso negado'
    USING ERRCODE = '42501';

END;
$$;
