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
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    descricao           VARCHAR(255) NOT NULL UNIQUE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TYPE tipo_grupo AS ENUM ('estudo', 'trabalho', 'pesquisa');

CREATE TABLE grupo(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome          VARCHAR(255) NOT NULL UNIQUE,
    tipo          tipo_grupo NOT NULL DEFAULT 'estudo',
    descricao     TEXT NULL,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE ocorreu(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    semestre      INT NOT NULL REFERENCES semestre(id),
    grupo         INT NOT NULL REFERENCES grupo(id),
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ocorreu_semestre_grupo UNIQUE (semestre, grupo)
);

CREATE TABLE encontro(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ocorrencia    INT NOT NULL REFERENCES ocorreu(id),
    inicio        TIMESTAMPTZ NOT NULL,
    fim           TIMESTAMPTZ NOT NULL,
    tema          VARCHAR(255) NOT NULL,
    resumo        TEXT NULL,
    video         VARCHAR(255) NULL UNIQUE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_encontro_ocorrencia_inicio UNIQUE (ocorrencia, inicio),
    CONSTRAINT uq_encontro_ocorrencia_tema   UNIQUE (ocorrencia, tema)
);

CREATE TABLE tarefa(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ocorrencia    INT NOT NULL REFERENCES ocorreu(id),
    horas         INT NOT NULL DEFAULT 1,
    inicio        TIMESTAMPTZ NOT NULL,
    prazo         TIMESTAMPTZ NOT NULL,
    tema          VARCHAR(255) NOT NULL,
    descricao     TEXT NULL,
    video         VARCHAR(255) NULL UNIQUE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tarefa_ocorrencia_inicio UNIQUE (ocorrencia, inicio),
    CONSTRAINT uq_tarefa_ocorrencia_tema   UNIQUE (ocorrencia, tema)
);

CREATE TABLE participante(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ra            VARCHAR(255) NOT NULL UNIQUE, -- "RA" → ra (evita uso de aspas)
    nome          VARCHAR(255) NOT NULL,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE participou(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horas         INT NOT NULL DEFAULT 1,
    participante  INT NOT NULL REFERENCES participante(id),
    encontro      INT NOT NULL REFERENCES encontro(id),
    confirmado    BOOLEAN NOT NULL DEFAULT FALSE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_participou_participante_encontro UNIQUE (participante, encontro)
);

CREATE TABLE apresentou(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horas         INT NOT NULL DEFAULT 1,
    participante  INT NOT NULL REFERENCES participante(id),
    encontro      INT NOT NULL REFERENCES encontro(id),
    valido        BOOLEAN NOT NULL DEFAULT TRUE,
    confirmado    BOOLEAN NOT NULL DEFAULT FALSE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_apresentou_participante_encontro UNIQUE (participante, encontro)
);

CREATE TABLE executou(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horas         INT NOT NULL DEFAULT 1,
    participante  INT NOT NULL REFERENCES participante(id),
    tarefa        INT NOT NULL REFERENCES tarefa(id),
    valido        BOOLEAN NOT NULL DEFAULT FALSE,
    confirmado    BOOLEAN NOT NULL DEFAULT FALSE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_executou_participante_tarefa UNIQUE (participante, tarefa)
);

CREATE TABLE coordenou(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horas         INT NOT NULL DEFAULT 1,
    participante  INT NOT NULL REFERENCES participante(id),
    ocorrencia    INT NOT NULL REFERENCES ocorreu(id),
    inicio        TIMESTAMPTZ NOT NULL,
    fim           TIMESTAMPTZ NOT NULL,
    ativo         BOOLEAN NOT NULL DEFAULT TRUE,
    confirmado    BOOLEAN NOT NULL DEFAULT FALSE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_coordenou_participante_ocorrencia_inicio UNIQUE (participante, ocorrencia, inicio)
);

CREATE TYPE tipo_cargo AS ENUM ('presidente', 'diretor', 'supervisor', 'marketing');

CREATE TABLE cargo(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horas         INT NOT NULL DEFAULT 1,
    tipo          tipo_cargo NOT NULL,
    participante  INT NOT NULL REFERENCES participante(id),
    semestre      INT NOT NULL REFERENCES semestre(id),
    inicio        TIMESTAMPTZ NOT NULL,
    fim           TIMESTAMPTZ NOT NULL,
    ativo         BOOLEAN NOT NULL DEFAULT TRUE,
    confirmado    BOOLEAN NOT NULL DEFAULT FALSE,
    criado        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    atualizado    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_cargo_participante_semestre_inicio UNIQUE (participante, semestre, inicio)
);

CREATE TABLE horas(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horas         INT NOT NULL DEFAULT 0,
    participante  INT NOT NULL REFERENCES participante(id),
    semestre      INT NOT NULL REFERENCES semestre(id),
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

CREATE TRIGGER trg_participou_set_updated_at
BEFORE UPDATE ON participou
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_apresentou_set_updated_at
BEFORE UPDATE ON apresentou
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_executou_set_updated_at
BEFORE UPDATE ON executou
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_coordenou_set_updated_at
BEFORE UPDATE ON coordenou
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_cargo_set_updated_at
BEFORE UPDATE ON cargo
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_horas_set_updated_at
BEFORE UPDATE ON horas
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
