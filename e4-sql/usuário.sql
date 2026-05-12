-- ============================================================
-- SISTEMA DE EMPRÉSTIMOS - PostgreSQL
-- Modelo normalizado (3FN)
-- ============================================================

-- Schema
CREATE SCHEMA IF NOT EXISTS biblioteca;
SET search_path TO biblioteca;

-- ============================================================
-- TABELA: item
-- ============================================================
CREATE TABLE IF NOT EXISTS item (
    codigo    VARCHAR(20)  PRIMARY KEY,
    nome      VARCHAR(100) NOT NULL,
    descricao TEXT
);

-- ============================================================
-- TABELA: usuario
-- ============================================================
CREATE TABLE IF NOT EXISTS usuario (
    id_usuario  SERIAL       PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE
);

-- ============================================================
-- TABELA: emprestimo
-- ============================================================
CREATE TABLE IF NOT EXISTS emprestimo (
    id                SERIAL      PRIMARY KEY,
    id_usuario        INTEGER     NOT NULL
                          REFERENCES usuario(id_usuario)
                          ON DELETE RESTRICT,
    cod_item          VARCHAR(20) NOT NULL
                          REFERENCES item(codigo)
                          ON DELETE RESTRICT,
    status            VARCHAR(20) NOT NULL
                          CHECK (status IN ('ativo', 'devolvido', 'atrasado')),
    data_inicio       DATE        NOT NULL,
    data_retorno      DATE,
    data_fim_previsto DATE,
    CONSTRAINT chk_datas CHECK (
        data_retorno IS NULL OR
        data_retorno >= data_inicio
    )
);

-- ============================================================
-- ÍNDICES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_emp_usuario ON emprestimo(id_usuario);
CREATE INDEX IF NOT EXISTS idx_emp_item    ON emprestimo(cod_item);
CREATE INDEX IF NOT EXISTS idx_emp_status  ON emprestimo(status);
