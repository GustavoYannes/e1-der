-- 1. TABELA: LOCALIZACAO_FISICA
CREATE TABLE localizacao_fisica (
    id_localizacao   VARCHAR(50)   PRIMARY KEY,
    endereco         VARCHAR(50)   NOT NULL,
    andar            INTEGER,
    estante          VARCHAR(30)
);

-- 2. TABELA: EXEMPLAR
CREATE TABLE exemplar (
    id_tombo         VARCHAR(20)    PRIMARY KEY,
    tipo_aquisicao   VARCHAR(30),
    data_aquisicao   DATE,
    valor_compra     DECIMAL(10,2)  DEFAULT 0.00 CHECK (valor_compra >= 0),
    status           VARCHAR(20)    DEFAULT 'DISPONIVEL' 
                     CHECK (status IN ('DISPONIVEL', 'EMPRESTADO', 'DANIFICADO')),
    conservacao      VARCHAR(30),
    id_localizacao   VARCHAR(50)    NOT NULL,

    CONSTRAINT fk_exemplar_localizacao 
        FOREIGN KEY (id_localizacao) 
        REFERENCES localizacao_fisica(id_localizacao)
);

