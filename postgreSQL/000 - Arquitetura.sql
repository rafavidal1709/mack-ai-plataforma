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

CREATE TABLE tipo_cargo(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome          VARCHAR(255) NOT NULL UNIQUE
                  CHECK (
                      length(regexp_replace(nome, '\s+', '', 'g')) > 2
                  ),
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

CREATE TYPE tipo_abrangencia AS ENUM ('ampla', 'restrita');

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
    ocorrencia    BIGINT DEFAULT NULL REFERENCES ocorreu(id),    -- Usado caso o cargo seja um coordenador de um grupo
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
CREATE TRIGGER trg_semestre_set_updated_at
BEFORE UPDATE ON semestre
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_grupo_set_updated_at
BEFORE UPDATE ON grupo
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_ocorreu_set_updated_at
BEFORE UPDATE ON ocorreu
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_encontro_set_updated_at
BEFORE UPDATE ON encontro
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_tarefa_set_updated_at
BEFORE UPDATE ON tarefa
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_participante_set_updated_at
BEFORE UPDATE ON participante
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_dispositivo_set_updated_at
BEFORE UPDATE ON dispositivo
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_email_set_updated_at
BEFORE UPDATE ON email
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_participou_set_updated_at
BEFORE UPDATE ON participou
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_apresentou_set_updated_at
BEFORE UPDATE ON apresentou
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_executou_set_updated_at
BEFORE UPDATE ON executou
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_tipo_cargo_set_updated_at
BEFORE UPDATE ON tipo_cargo
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_cargo_set_updated_at
BEFORE UPDATE ON cargo
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_horas_set_updated_at
BEFORE UPDATE ON horas
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
