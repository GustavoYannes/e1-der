-- =====================================================================
--  SISTEMA DE GESTÃO DE BIBLIOTECA UNIVERSITÁRIA
--  PUC Minas · ICEI · Banco de Dados 2026/1
--  Engenharia de Software — 2º Período
--  Prof. Cristiano de Macedo Neto
--  Etapa 5 — Script SQL Final (DDL + DML + 10 Consultas)
--  SGBD-alvo: PostgreSQL 14+
-- =====================================================================

-- Para reexecução limpa do script (reset do esquema).
DROP VIEW IF EXISTS vw_multas_pendentes        CASCADE;
DROP VIEW IF EXISTS vw_disponibilidade_acervo  CASCADE;
DROP VIEW IF EXISTS vw_emprestimos_detalhados  CASCADE;
DROP VIEW IF EXISTS vw_acervo_detalhado        CASCADE;
DROP VIEW IF EXISTS vw_usuario_completo        CASCADE;
DROP VIEW IF EXISTS vw_perfil_usuario          CASCADE;

DROP TABLE IF EXISTS MULTA             CASCADE;
DROP TABLE IF EXISTS MOTIVO_MULTA      CASCADE;
DROP TABLE IF EXISTS RESERVA           CASCADE;
DROP TABLE IF EXISTS EMPRESTIMO        CASCADE;
DROP TABLE IF EXISTS EXEMPLAR          CASCADE;
DROP TABLE IF EXISTS LOCALIZACAO_FISICA CASCADE;
DROP TABLE IF EXISTS EBOOK             CASCADE;
DROP TABLE IF EXISTS PERIODICO         CASCADE;
DROP TABLE IF EXISTS LIVRO             CASCADE;
DROP TABLE IF EXISTS ACERVO            CASCADE;
DROP TABLE IF EXISTS TELEFONE_USUARIO  CASCADE;
DROP TABLE IF EXISTS USUARIO           CASCADE;
DROP TABLE IF EXISTS ENDERECO          CASCADE;


-- =====================================================================
-- 1. DDL — CRIAÇÃO DAS TABELAS (em ordem de dependência)
-- =====================================================================

-- ---------- 1.1 MÓDULO: USUÁRIO E ENDEREÇO ----------

-- Endereço dos usuários. CEP validado por expressão regular (formato 00000-000).
CREATE TABLE ENDERECO (
    id_endereco SERIAL PRIMARY KEY,
    cep         CHAR(9)      NOT NULL,
    logradouro  VARCHAR(120) NOT NULL,
    numero      VARCHAR(10)  NOT NULL,
    bairro      VARCHAR(60)  NOT NULL,
    cidade      VARCHAR(60)  NOT NULL,
    CONSTRAINT ck_cep_formato CHECK (cep ~ '^[0-9]{5}-[0-9]{3}$')
);

-- Usuário da biblioteca (aluno, professor ou funcionário).
-- CPF e e-mail únicos; tipo restrito por CHECK; nascimento no passado.
CREATE TABLE USUARIO (
    id_usuario      SERIAL PRIMARY KEY,
    primeiro_nome   VARCHAR(50)  NOT NULL,
    sobrenome       VARCHAR(80)  NOT NULL,
    cpf             CHAR(14)     NOT NULL UNIQUE,
    email           VARCHAR(120) NOT NULL UNIQUE,
    data_nascimento DATE         NOT NULL,
    data_cadastro   DATE         NOT NULL DEFAULT CURRENT_DATE,
    tipo_usuario    VARCHAR(20)  NOT NULL,
    id_endereco     INTEGER      NOT NULL,
    CONSTRAINT fk_usuario_endereco FOREIGN KEY (id_endereco)
        REFERENCES ENDERECO(id_endereco) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_usuario_tipo CHECK (tipo_usuario IN ('ALUNO','PROFESSOR','FUNCIONARIO')),
    CONSTRAINT ck_data_nascimento CHECK (data_nascimento < CURRENT_DATE)
);

-- Atributo multivalorado de telefone (1:N com USUARIO).
CREATE TABLE TELEFONE_USUARIO (
    id_usuario INTEGER     NOT NULL,
    telefone   VARCHAR(20) NOT NULL,
    CONSTRAINT pk_telefone_usuario PRIMARY KEY (id_usuario, telefone),
    CONSTRAINT fk_telefone_usuario FOREIGN KEY (id_usuario)
        REFERENCES USUARIO(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------- 1.2 MÓDULO: ACERVO (especialização LIVRO/PERIODICO/EBOOK) ----------

-- Superclasse do acervo. Atributos comuns a qualquer obra catalogada.
CREATE TABLE ACERVO (
    id_acervo      INTEGER      NOT NULL,
    titulo         VARCHAR(150) NOT NULL,
    subtitulo      VARCHAR(150),
    ano_publicacao INTEGER,
    idioma         VARCHAR(50),
    descricao      TEXT,
    CONSTRAINT pk_acervo PRIMARY KEY (id_acervo),
    CONSTRAINT ck_acervo_ano CHECK (ano_publicacao > 0)
);

-- Subclasse LIVRO (especialização total/disjunta via PK = FK).
CREATE TABLE LIVRO (
    id_acervo      INTEGER     NOT NULL,
    isbn           VARCHAR(20) NOT NULL,
    numero_paginas INTEGER,
    edicao         INTEGER,
    CONSTRAINT pk_livro PRIMARY KEY (id_acervo),
    CONSTRAINT fk_livro_acervo FOREIGN KEY (id_acervo)
        REFERENCES ACERVO(id_acervo) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_livro_isbn UNIQUE (isbn),
    CONSTRAINT ck_livro_paginas CHECK (numero_paginas > 0)
);

-- Subclasse PERIODICO.
CREATE TABLE PERIODICO (
    id_acervo     INTEGER     NOT NULL,
    issn          VARCHAR(10) NOT NULL,
    volume        INTEGER,
    numero_edicao INTEGER,
    periodicidade VARCHAR(50),
    CONSTRAINT pk_periodico PRIMARY KEY (id_acervo),
    CONSTRAINT fk_periodico_acervo FOREIGN KEY (id_acervo)
        REFERENCES ACERVO(id_acervo) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_periodico_issn UNIQUE (issn),
    CONSTRAINT ck_periodico_volume CHECK (volume > 0),
    CONSTRAINT ck_periodico_numero CHECK (numero_edicao > 0)
);

-- Subclasse EBOOK.
CREATE TABLE EBOOK (
    id_acervo          INTEGER NOT NULL,
    formato_arquivo    VARCHAR(20),
    tamanho_arquivo_mb DECIMAL(6,2),
    url_acesso         TEXT,
    licenca_digital    VARCHAR(50),
    CONSTRAINT pk_ebook PRIMARY KEY (id_acervo),
    CONSTRAINT fk_ebook_acervo FOREIGN KEY (id_acervo)
        REFERENCES ACERVO(id_acervo) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_ebook_tamanho CHECK (tamanho_arquivo_mb > 0)
);

-- ---------- 1.3 MÓDULO: TOMBAMENTO (exemplares físicos) ----------

-- Onde o exemplar fica fisicamente (sala, andar, estante).
CREATE TABLE LOCALIZACAO_FISICA (
    id_localizacao VARCHAR(50) PRIMARY KEY,
    endereco       VARCHAR(50) NOT NULL,
    andar          INTEGER CHECK (andar >= 0),
    estante        VARCHAR(30)
);

-- Exemplar = cópia física de uma obra do acervo (identificado por tombo).
CREATE TABLE EXEMPLAR (
    id_tombo       VARCHAR(20) PRIMARY KEY,
    tipo_aquisicao VARCHAR(30),
    data_aquisicao DATE,
    valor_compra   DECIMAL(10,2) DEFAULT 0.00 CHECK (valor_compra >= 0),
    status         VARCHAR(20) DEFAULT 'DISPONIVEL'
                   CHECK (status IN ('DISPONIVEL','EMPRESTADO','DANIFICADO','RESERVADO')),
    conservacao    VARCHAR(30),
    id_localizacao VARCHAR(50) NOT NULL,
    id_acervo      INTEGER     NOT NULL,
    CONSTRAINT fk_exemplar_localizacao FOREIGN KEY (id_localizacao)
        REFERENCES LOCALIZACAO_FISICA(id_localizacao) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_exemplar_acervo FOREIGN KEY (id_acervo)
        REFERENCES ACERVO(id_acervo) ON DELETE CASCADE
);

-- ---------- 1.4 MÓDULO: EMPRÉSTIMO, RESERVA E MULTA ----------

-- Empréstimo de um exemplar a um usuário.
CREATE TABLE EMPRESTIMO (
    id_emprestimo     SERIAL PRIMARY KEY,
    id_usuario        INTEGER     NOT NULL,
    id_tombo          VARCHAR(20) NOT NULL,
    status            VARCHAR(20) NOT NULL,
    data_inicio       DATE        NOT NULL,
    data_retorno      DATE,
    data_fim_previsto DATE        NOT NULL,
    CONSTRAINT fk_emp_usuario  FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)  ON DELETE RESTRICT,
    CONSTRAINT fk_emp_exemplar FOREIGN KEY (id_tombo)   REFERENCES EXEMPLAR(id_tombo)   ON DELETE RESTRICT,
    CONSTRAINT chk_status_emp CHECK (status IN ('ativo','devolvido','atrasado')),
    CONSTRAINT chk_data_retorno CHECK (data_retorno IS NULL OR data_retorno >= data_inicio)
);

-- Reserva de exemplar (fila de espera quando indisponível).
CREATE TABLE RESERVA (
    id_reserva    SERIAL PRIMARY KEY,
    id_usuario    INTEGER     NOT NULL,
    id_tombo      VARCHAR(20) NOT NULL,
    data_reserva  DATE        NOT NULL,
    data_validade DATE        NOT NULL,
    status        VARCHAR(20) NOT NULL,
    CONSTRAINT fk_res_usuario  FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario),
    CONSTRAINT fk_res_exemplar FOREIGN KEY (id_tombo)   REFERENCES EXEMPLAR(id_tombo),
    CONSTRAINT chk_status_res CHECK (status IN ('ATIVA','FINALIZADA','CANCELADA')),
    CONSTRAINT chk_data_val CHECK (data_validade >= data_reserva)
);

-- Tabela de domínio dos motivos de multa.
CREATE TABLE MOTIVO_MULTA (
    id_motivo INTEGER PRIMARY KEY,
    descricao VARCHAR(255) NOT NULL
);

-- Multa associada a um empréstimo e a um motivo.
CREATE TABLE MULTA (
    id_multa       SERIAL PRIMARY KEY,
    id_emprestimo  INTEGER       NOT NULL,
    id_motivo      INTEGER       NOT NULL,
    valor          DECIMAL(10,2) NOT NULL,
    data_geracao   DATE          NOT NULL,
    data_pagamento DATE,
    dias_atraso    INTEGER,
    status         VARCHAR(20)   NOT NULL,
    CONSTRAINT fk_multa_emp    FOREIGN KEY (id_emprestimo) REFERENCES EMPRESTIMO(id_emprestimo),
    CONSTRAINT fk_multa_motivo FOREIGN KEY (id_motivo)     REFERENCES MOTIVO_MULTA(id_motivo)
);


-- =====================================================================
-- 2. DML — INSERÇÃO DE DADOS (carga inicial de teste)
-- =====================================================================

-- Endereços
INSERT INTO ENDERECO (cep, logradouro, numero, bairro, cidade) VALUES
('30140-010', 'Rua da Bahia', '1000', 'Centro', 'Belo Horizonte'),
('30535-000', 'Av. Dom José Gaspar', '500', 'Coração Eucarístico', 'Belo Horizonte'),
('30120-000', 'Av. Afonso Pena', '150', 'Centro', 'Belo Horizonte'),
('31270-901', 'Av. Antônio Carlos', '6627', 'Pampulha', 'Belo Horizonte'),
('30310-000', 'Rua Grão Mogol', '200', 'Sion', 'Belo Horizonte'),
('32000-000', 'Praça da Matriz', '10', 'Centro', 'Contagem'),
('34000-000', 'Rua Direita', '50', 'Centro', 'Nova Lima'),
('30640-000', 'Av. Olinto Meireles', '300', 'Barreiro', 'Belo Horizonte'),
('30150-280', 'Rua Ceará', '450', 'Santa Efigênia', 'Belo Horizonte'),
('30411-000', 'Av. Amazonas', '2000', 'Prado', 'Belo Horizonte');

-- Usuários
INSERT INTO USUARIO (primeiro_nome, sobrenome, cpf, email, data_nascimento, tipo_usuario, id_endereco) VALUES
('João Otávio', 'Gurgel', '111.222.333-44', 'joao.gurgel@puc.br', '2006-04-25', 'ALUNO', 2),
('Cristiano', 'Macedo', '222.333.444-55', 'cristiano.macedo@puc.br', '1980-05-10', 'PROFESSOR', 1),
('Maria', 'Silva', '333.444.555-66', 'maria.silva@puc.br', '2000-01-15', 'ALUNO', 3),
('Ricardo', 'Oliveira', '444.555.666-77', 'ricardo.ol@puc.br', '1975-08-20', 'FUNCIONARIO', 4),
('Ana', 'Beatriz', '555.666.777-88', 'ana.b@puc.br', '2002-11-30', 'ALUNO', 5),
('Carlos', 'Eduardo', '666.777.888-99', 'carlos.ed@puc.br', '1995-03-22', 'ALUNO', 6),
('Fernanda', 'Lima', '777.888.999-00', 'fernanda.l@puc.br', '1988-12-05', 'PROFESSOR', 7),
('Lucas', 'Martins', '888.999.000-11', 'lucas.m@puc.br', '2001-07-14', 'ALUNO', 8),
('Juliana', 'Costa', '999.000.111-22', 'juliana.c@puc.br', '1992-06-18', 'FUNCIONARIO', 9),
('Amanda', 'Souza', '000.111.222-33', 'amanda.s@puc.br', '1998-09-09', 'ALUNO', 10);

-- Telefones
INSERT INTO TELEFONE_USUARIO (id_usuario, telefone) VALUES
(1, '(31) 98888-7777'), (1, '(31) 3333-2222'), (2, '(31) 97777-6666'),
(3, '(31) 96666-5555'), (4, '(31) 3444-1111'), (5, '(31) 95555-4444'),
(6, '(31) 94444-3333'), (7, '(31) 3777-8888'), (8, '(31) 93333-2222'),
(9, '(31) 92222-1111'), (10, '(31) 91111-0000');

-- Acervo (superclasse)
INSERT INTO ACERVO VALUES
(1, 'Dom Casmurro', NULL, 1899, 'Português', 'Romance clássico brasileiro.'),
(2, 'Banco de Dados', 'Projeto e Implementação', 2020, 'Português', 'Livro acadêmico sobre bancos de dados.'),
(3, 'Engenharia de Software', NULL, 2019, 'Português', 'Livro sobre processos de software.'),
(4, 'Algoritmos', 'Teoria e Prática', 2018, 'Português', 'Livro sobre algoritmos e estruturas de dados.'),
(5, 'Revista Ciência Hoje', NULL, 2024, 'Português', 'Periódico científico nacional.'),
(6, 'Journal of Software Engineering', NULL, 2023, 'Inglês', 'Periódico internacional de engenharia de software.'),
(7, 'Revista Tecnologia e Sociedade', NULL, 2022, 'Português', 'Periódico sobre tecnologia.'),
(8, 'Computing Review', NULL, 2021, 'Inglês', 'Periódico da área de computação.'),
(9, 'Introdução ao PostgreSQL', NULL, 2023, 'Português', 'E-book sobre banco de dados PostgreSQL.'),
(10, 'Python para Iniciantes', NULL, 2022, 'Português', 'E-book introdutório de programação.'),
(11, 'Machine Learning Básico', NULL, 2024, 'Português', 'E-book sobre aprendizado de máquina.'),
(12, 'Data Science Handbook', NULL, 2021, 'Inglês', 'E-book sobre ciência de dados.');

-- Subclasses
INSERT INTO LIVRO VALUES
(1, '978-85-333-0227-3', 320, 3), (2, '978-65-555-1234-8', 540, 1),
(3, '978-85-7522-999-1', 480, 2), (4, '978-85-9999-111-2', 650, 4);

INSERT INTO PERIODICO VALUES
(5, '1234-5678', 12, 45, 'Mensal'), (6, '2345-6789', 8, 20, 'Trimestral'),
(7, '3456-7890', 5, 13, 'Semestral'), (8, '4567-8901', 10, 30, 'Mensal');

INSERT INTO EBOOK VALUES
(9, 'PDF', 12.50, 'https://biblioteca.edu/ebooks/postgresql.pdf', 'Aberta'),
(10, 'EPUB', 8.75, 'https://biblioteca.edu/ebooks/python.epub', 'Institucional'),
(11, 'PDF', 20.30, 'https://biblioteca.edu/ebooks/ml.pdf', 'Restrita'),
(12, 'PDF', 18.00, 'https://biblioteca.edu/ebooks/datascience.pdf', 'Aberta');

-- Localizações físicas
INSERT INTO LOCALIZACAO_FISICA (id_localizacao, endereco, andar, estante) VALUES
('SALA101-A', 'Sala de Leitura - Ala A', 1, 'E1'),
('SALA101-B', 'Sala de Leitura - Ala B', 1, 'E3'),
('SALA202',   'Sala de Periódicos', 2, 'E5'),
('DEP03',     'Depósito Geral', 0, 'D12'),
('SALA303',   'Sala Multimídia', 3, 'E7'),
('DEP04',     'Depósito Digital', 0, 'D20');

-- Exemplares
INSERT INTO EXEMPLAR (id_tombo, tipo_aquisicao, data_aquisicao, valor_compra, status, conservacao, id_localizacao, id_acervo) VALUES
('T2023001', 'Compra', '2023-05-10', 89.90,  'DISPONIVEL', 'Bom',   'SALA101-A', 1),
('T2023002', 'Doação', '2023-06-15', 0.00,   'EMPRESTADO', 'Ótimo', 'SALA101-B', 2),
('T2023003', 'Compra', '2023-08-20', 145.50, 'DISPONIVEL', 'Bom',   'SALA202',   3),
('T2023004', 'Compra', '2024-01-05', 67.80,  'DANIFICADO', 'Ruim',  'DEP03',     4),
('T2024005', 'Compra', '2024-03-12', 110.00, 'DISPONIVEL', 'Ótimo', 'SALA202',   5),
('T2024006', 'Doação', '2024-04-18', 0.00,   'DISPONIVEL', 'Bom',   'SALA303',   6),
('T2024007', 'Compra', '2024-05-22', 75.40,  'RESERVADO',  'Bom',   'SALA101-A', 1),
('T2024008', 'Compra', '2024-06-30', 95.00,  'DISPONIVEL', 'Bom',   'DEP04',     3);

-- Motivos de multa
INSERT INTO MOTIVO_MULTA VALUES
(1, 'Atraso na Devolução'), (2, 'Dano ao Material'), (3, 'Perda do Exemplar');

-- Empréstimos
INSERT INTO EMPRESTIMO (id_usuario, id_tombo, status, data_inicio, data_retorno, data_fim_previsto) VALUES
(1, 'T2023002', 'ativo',     '2025-05-01', NULL,         '2025-05-15'),
(2, 'T2023003', 'devolvido', '2025-04-10', '2025-04-20', '2025-04-25'),
(3, 'T2023001', 'atrasado',  '2025-03-01', NULL,         '2025-03-15'),
(5, 'T2024005', 'ativo',     '2025-05-20', NULL,         '2025-06-03'),
(6, 'T2024008', 'devolvido', '2025-04-05', '2025-04-15', '2025-04-19');

-- Reservas
INSERT INTO RESERVA (id_usuario, id_tombo, data_reserva, data_validade, status) VALUES
(3, 'T2023001', '2026-05-01', '2026-05-05', 'ATIVA'),
(8, 'T2024007', '2026-05-10', '2026-05-14', 'ATIVA'),
(1, 'T2023003', '2026-04-01', '2026-04-05', 'FINALIZADA');

-- Multas
INSERT INTO MULTA (id_emprestimo, id_motivo, valor, data_geracao, data_pagamento, dias_atraso, status) VALUES
(2, 1, 15.00, '2025-04-21', NULL,         0,  'PENDENTE'),
(3, 1, 25.00, '2025-03-16', NULL,         11, 'PENDENTE');


-- =====================================================================
-- 3. VIEWS — VISÕES DE APOIO
-- =====================================================================

-- Perfil completo do usuário com seu endereço.
CREATE OR REPLACE VIEW vw_usuario_completo AS
SELECT u.id_usuario,
       u.primeiro_nome || ' ' || u.sobrenome AS nome_completo,
       u.cpf, u.email, u.tipo_usuario,
       e.logradouro, e.numero, e.bairro, e.cidade, e.cep
FROM USUARIO u
JOIN ENDERECO e ON u.id_endereco = e.id_endereco;

-- Acervo unificado com o tipo de material identificado.
CREATE OR REPLACE VIEW vw_acervo_detalhado AS
SELECT a.id_acervo, a.titulo, a.ano_publicacao, a.idioma,
       CASE
           WHEN l.id_acervo IS NOT NULL THEN 'LIVRO'
           WHEN p.id_acervo IS NOT NULL THEN 'PERIODICO'
           WHEN b.id_acervo IS NOT NULL THEN 'EBOOK'
           ELSE 'INDEFINIDO'
       END AS tipo_material
FROM ACERVO a
LEFT JOIN LIVRO l     ON a.id_acervo = l.id_acervo
LEFT JOIN PERIODICO p ON a.id_acervo = p.id_acervo
LEFT JOIN EBOOK b     ON a.id_acervo = b.id_acervo;

-- Empréstimos com dados do usuário e do material.
CREATE OR REPLACE VIEW vw_emprestimos_detalhados AS
SELECT em.id_emprestimo,
       u.primeiro_nome || ' ' || u.sobrenome AS usuario,
       ac.titulo, ex.id_tombo,
       em.data_inicio, em.data_fim_previsto, em.data_retorno, em.status
FROM EMPRESTIMO em
JOIN USUARIO u   ON em.id_usuario = u.id_usuario
JOIN EXEMPLAR ex ON em.id_tombo   = ex.id_tombo
JOIN ACERVO ac   ON ex.id_acervo  = ac.id_acervo;

-- Disponibilidade de exemplares por título.
CREATE OR REPLACE VIEW vw_disponibilidade_acervo AS
SELECT a.id_acervo, a.titulo,
       COUNT(ex.id_tombo) AS total_exemplares,
       COUNT(*) FILTER (WHERE ex.status = 'DISPONIVEL') AS disponiveis,
       COUNT(*) FILTER (WHERE ex.status = 'EMPRESTADO') AS emprestados
FROM ACERVO a
LEFT JOIN EXEMPLAR ex ON a.id_acervo = ex.id_acervo
GROUP BY a.id_acervo, a.titulo;

-- Multas pendentes por usuário.
CREATE OR REPLACE VIEW vw_multas_pendentes AS
SELECT u.id_usuario,
       u.primeiro_nome || ' ' || u.sobrenome AS usuario,
       m.id_multa, mm.descricao AS motivo, m.valor, m.data_geracao, m.dias_atraso
FROM MULTA m
JOIN EMPRESTIMO em   ON m.id_emprestimo = em.id_emprestimo
JOIN USUARIO u       ON em.id_usuario = u.id_usuario
JOIN MOTIVO_MULTA mm ON m.id_motivo = mm.id_motivo
WHERE m.status = 'PENDENTE';


-- =====================================================================
-- 4. ÍNDICES — OTIMIZAÇÃO DE CONSULTAS
-- =====================================================================

-- Índices em chaves estrangeiras (aceleram JOINs).
CREATE INDEX idx_usuario_endereco     ON USUARIO    (id_endereco);
CREATE INDEX idx_exemplar_acervo      ON EXEMPLAR   (id_acervo);
CREATE INDEX idx_exemplar_localizacao ON EXEMPLAR   (id_localizacao);
CREATE INDEX idx_emprestimo_usuario   ON EMPRESTIMO (id_usuario);
CREATE INDEX idx_emprestimo_tombo     ON EMPRESTIMO (id_tombo);
CREATE INDEX idx_reserva_usuario      ON RESERVA    (id_usuario);
CREATE INDEX idx_reserva_tombo        ON RESERVA    (id_tombo);
CREATE INDEX idx_multa_emprestimo     ON MULTA      (id_emprestimo);
CREATE INDEX idx_multa_motivo         ON MULTA      (id_motivo);

-- Índices em colunas de filtro frequente (WHERE).
CREATE INDEX idx_usuario_tipo         ON USUARIO    (tipo_usuario);
CREATE INDEX idx_acervo_idioma        ON ACERVO     (idioma);
CREATE INDEX idx_exemplar_status      ON EXEMPLAR   (status);
CREATE INDEX idx_emprestimo_status    ON EMPRESTIMO (status);

-- Índice composto (empréstimos ativos de um usuário).
CREATE INDEX idx_emprestimo_usuario_status ON EMPRESTIMO (id_usuario, status);

-- Índice parcial (apenas reservas ativas - otimiza EXISTS da Q8).
CREATE INDEX idx_reserva_ativa ON RESERVA (id_usuario) WHERE status = 'ATIVA';


-- =====================================================================
-- 5. CONSULTAS SQL — 10 CONSULTAS COMENTADAS (Q1 a Q10)
-- =====================================================================

-- Q1 — Projeção e seleção simples.
-- Objetivo de negócio: listar todos os usuários do tipo ALUNO com seu contato.
SELECT primeiro_nome, sobrenome, email
FROM USUARIO
WHERE tipo_usuario = 'ALUNO';

-- Q2 — Seleção com operadores lógicos (AND).
-- Objetivo: obras em português publicadas após 2020 (acervo recente nacional).
SELECT titulo, ano_publicacao, idioma
FROM ACERVO
WHERE idioma = 'Português' AND ano_publicacao > 2020;

-- Q3 — INNER JOIN entre 2 tabelas.
-- Objetivo: relacionar cada livro ao seu título e ISBN.
SELECT a.titulo, l.isbn
FROM ACERVO a
INNER JOIN LIVRO l ON a.id_acervo = l.id_acervo;

-- Q4 — INNER JOIN entre 4 tabelas + filtro.
-- Objetivo: quem está com qual obra emprestada no momento (empréstimos ativos).
SELECT u.primeiro_nome, a.titulo, e.status
FROM EMPRESTIMO e
JOIN USUARIO u  ON e.id_usuario = u.id_usuario
JOIN EXEMPLAR ex ON e.id_tombo  = ex.id_tombo
JOIN ACERVO a   ON ex.id_acervo = a.id_acervo
WHERE e.status = 'ativo';

-- Q5 — LEFT OUTER JOIN.
-- Objetivo: todos os endereços e os usuários vinculados, inclusive endereços sem usuário.
SELECT e.logradouro, u.primeiro_nome
FROM ENDERECO e
LEFT JOIN USUARIO u ON e.id_endereco = u.id_endereco;

-- Q6 — Agrupamento e agregação com HAVING.
-- Objetivo: idiomas que possuem 2 ou mais obras no acervo.
SELECT idioma, COUNT(*) AS quantidade
FROM ACERVO
GROUP BY idioma
HAVING COUNT(*) >= 2;

-- Q7 — Subconsulta não correlacionada (com média).
-- Objetivo: títulos cujos exemplares custaram acima da média de aquisição.
SELECT titulo
FROM ACERVO
WHERE id_acervo IN (
    SELECT id_acervo
    FROM EXEMPLAR
    WHERE valor_compra > (SELECT AVG(valor_compra) FROM EXEMPLAR)
);

-- Q8 — EXISTS (subconsulta correlacionada).
-- Objetivo: usuários que têm ao menos uma reserva ativa.
SELECT u.primeiro_nome, u.email
FROM USUARIO u
WHERE EXISTS (
    SELECT 1 FROM RESERVA r
    WHERE r.id_usuario = u.id_usuario AND r.status = 'ATIVA'
);

-- Q9 — Consulta sobre VIEW.
-- Objetivo: usar a visão de perfil para listar nome, cidade e tipo de cada usuário.
SELECT id_usuario, nome_completo, cidade, tipo_usuario
FROM vw_usuario_completo
ORDER BY nome_completo;

-- Q10 — Consulta de negócio livre (ranking com LEFT JOIN + agregação + ordenação).
-- Objetivo: ranking dos títulos mais reservados (materiais com maior demanda).
SELECT a.titulo, COUNT(r.id_reserva) AS total_reservas
FROM ACERVO a
JOIN EXEMPLAR ex ON a.id_acervo = ex.id_acervo
JOIN RESERVA r   ON ex.id_tombo = r.id_tombo
GROUP BY a.titulo
ORDER BY total_reservas DESC;

-- =====================================================================
-- FIM DO SCRIPT
-- =====================================================================
