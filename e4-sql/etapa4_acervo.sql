-- =========================================================
-- ETAPA 4 - IMPLEMENTAÇÃO SQL
-- Domínio: Acervo de Biblioteca Universitária
-- Tabelas: ACERVO, LIVRO, PERIODICO, EBOOK
-- =========================================================

-- =====================
-- 1. DDL
-- =====================

DROP TABLE IF EXISTS EBOOK CASCADE;
DROP TABLE IF EXISTS PERIODICO CASCADE;
DROP TABLE IF EXISTS LIVRO CASCADE;
DROP TABLE IF EXISTS ACERVO CASCADE;

CREATE TABLE ACERVO (
    id_acervo INTEGER NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    subtitulo VARCHAR(150),
    ano_publicacao INTEGER,
    idioma VARCHAR(50),
    descricao TEXT,

    CONSTRAINT pk_acervo PRIMARY KEY (id_acervo),
    CONSTRAINT ck_acervo_ano CHECK (ano_publicacao > 0)
);

CREATE TABLE LIVRO (
    id_acervo INTEGER NOT NULL,
    isbn VARCHAR(20) NOT NULL,
    numero_paginas INTEGER,
    edicao INTEGER,

    CONSTRAINT pk_livro PRIMARY KEY (id_acervo),
    CONSTRAINT fk_livro_acervo
        FOREIGN KEY (id_acervo)
        REFERENCES ACERVO (id_acervo)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_livro_isbn UNIQUE (isbn),
    CONSTRAINT ck_livro_paginas CHECK (numero_paginas > 0)
);

CREATE TABLE PERIODICO (
    id_acervo INTEGER NOT NULL,
    issn VARCHAR(10) NOT NULL,
    volume INTEGER,
    numero_edicao INTEGER,
    periodicidade VARCHAR(50),

    CONSTRAINT pk_periodico PRIMARY KEY (id_acervo),
    CONSTRAINT fk_periodico_acervo
        FOREIGN KEY (id_acervo)
        REFERENCES ACERVO (id_acervo)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_periodico_issn UNIQUE (issn),
    CONSTRAINT ck_periodico_volume CHECK (volume > 0),
    CONSTRAINT ck_periodico_numero CHECK (numero_edicao > 0)
);

CREATE TABLE EBOOK (
    id_acervo INTEGER NOT NULL,
    formato_arquivo VARCHAR(20),
    tamanho_arquivo_mb DECIMAL(6,2),
    url_acesso TEXT,
    licenca_digital VARCHAR(50),

    CONSTRAINT pk_ebook PRIMARY KEY (id_acervo),
    CONSTRAINT fk_ebook_acervo
        FOREIGN KEY (id_acervo)
        REFERENCES ACERVO (id_acervo)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_ebook_tamanho CHECK (tamanho_arquivo_mb > 0)
);

COMMENT ON TABLE ACERVO IS 'Tabela que armazena os dados gerais dos itens do acervo.';
COMMENT ON TABLE LIVRO IS 'Tabela que armazena os dados específicos de livros.';
COMMENT ON TABLE PERIODICO IS 'Tabela que armazena os dados específicos de periódicos.';
COMMENT ON TABLE EBOOK IS 'Tabela que armazena os dados específicos de e-books.';

-- =====================
-- 2. DML
-- =====================

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

INSERT INTO LIVRO VALUES
(1, '978-85-333-0227-3', 320, 3),
(2, '978-65-555-1234-8', 540, 1),
(3, '978-85-7522-999-1', 480, 2),
(4, '978-85-9999-111-2', 650, 4);

INSERT INTO PERIODICO VALUES
(5, '1234-5678', 12, 45, 'Mensal'),
(6, '2345-6789', 8, 20, 'Trimestral'),
(7, '3456-7890', 5, 13, 'Semestral'),
(8, '4567-8901', 10, 30, 'Mensal');

INSERT INTO EBOOK VALUES
(9, 'PDF', 12.50, 'https://biblioteca.edu/ebooks/postgresql.pdf', 'Aberta'),
(10, 'EPUB', 8.75, 'https://biblioteca.edu/ebooks/python.epub', 'Institucional'),
(11, 'PDF', 20.30, 'https://biblioteca.edu/ebooks/ml.pdf', 'Restrita'),
(12, 'PDF', 18.00, 'https://biblioteca.edu/ebooks/datascience.pdf', 'Aberta');

-- =====================
-- 3. CONSULTAS
-- =====================

-- Q1: Listar acervos publicados após 2020.
SELECT titulo, ano_publicacao
FROM ACERVO
WHERE ano_publicacao > 2020;

-- Q2: Buscar acervos em português que tenham "Banco" no título.
SELECT titulo, idioma
FROM ACERVO
WHERE idioma = 'Português'
AND titulo LIKE '%Banco%';

-- Q3: Listar livros com seus respectivos ISBNs.
SELECT A.titulo, L.isbn, L.numero_paginas
FROM ACERVO A
INNER JOIN LIVRO L
ON A.id_acervo = L.id_acervo;

-- Q4: Listar periódicos com ISSN e periodicidade.
SELECT A.titulo, P.issn, P.periodicidade
FROM ACERVO A
INNER JOIN PERIODICO P
ON A.id_acervo = P.id_acervo;

-- Q5: Listar todos os acervos e mostrar dados de e-book quando existirem.
SELECT A.titulo, E.formato_arquivo, E.url_acesso
FROM ACERVO A
LEFT JOIN EBOOK E
ON A.id_acervo = E.id_acervo;

-- Q6: Quantidade de acervos por idioma, exibindo apenas idiomas com mais de 3 itens.
SELECT idioma, COUNT(*) AS quantidade
FROM ACERVO
GROUP BY idioma
HAVING COUNT(*) > 3;

-- Q7: Listar títulos que são livros usando subquery não correlacionada.
SELECT titulo
FROM ACERVO
WHERE id_acervo IN (
    SELECT id_acervo
    FROM LIVRO
);

-- Q8: Listar acervos que possuem registro como e-book usando EXISTS.
SELECT A.titulo
FROM ACERVO A
WHERE EXISTS (
    SELECT 1
    FROM EBOOK E
    WHERE E.id_acervo = A.id_acervo
);

-- Q9: Criar uma view com todos os livros cadastrados.
CREATE VIEW vw_livros_acervo AS
SELECT A.id_acervo, A.titulo, A.ano_publicacao, L.isbn, L.numero_paginas, L.edicao
FROM ACERVO A
INNER JOIN LIVRO L
ON A.id_acervo = L.id_acervo;

-- Consulta da view criada.
SELECT * FROM vw_livros_acervo;

-- Q10: Consulta de negócio: listar todos os materiais do acervo com seu tipo.
SELECT A.id_acervo, A.titulo, 'LIVRO' AS tipo
FROM ACERVO A
INNER JOIN LIVRO L ON A.id_acervo = L.id_acervo

UNION

SELECT A.id_acervo, A.titulo, 'PERIODICO' AS tipo
FROM ACERVO A
INNER JOIN PERIODICO P ON A.id_acervo = P.id_acervo

UNION

SELECT A.id_acervo, A.titulo, 'EBOOK' AS tipo
FROM ACERVO A
INNER JOIN EBOOK E ON A.id_acervo = E.id_acervo;
