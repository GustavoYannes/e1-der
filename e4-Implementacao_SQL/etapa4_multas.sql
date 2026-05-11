-- ============================================================
--  ETAPA 4 — IMPLEMENTAÇÃO SQL (PostgreSQL)
--  Domínio: Sistema de Multas por Atraso em Empréstimos
--  Referência: Elmasri & Navathe, Cap. 8
--  Autor: Gerado com base no modelo ER da Etapa 2
-- ============================================================


-- ============================================================
-- SEÇÃO 1 — DDL (Data Definition Language)
-- ============================================================

-- Limpeza idempotente (ordem inversa das FKs)
DROP TABLE IF EXISTS MULTA        CASCADE;
DROP TABLE IF EXISTS EMPRESTIMO   CASCADE;
DROP TABLE IF EXISTS MOTIVO_MULTA CASCADE;

-- ----------------------------------------------------------
-- Tabela: MOTIVO_MULTA
-- Catálogo de motivos que podem originar uma multa
-- ----------------------------------------------------------
CREATE TABLE MOTIVO_MULTA (
    id_motivo   INTEGER       NOT NULL,
    descricao   VARCHAR(255)  NOT NULL,

    CONSTRAINT pk_motivo_multa PRIMARY KEY (id_motivo),
    CONSTRAINT uq_motivo_descricao UNIQUE (descricao),
    CONSTRAINT ck_motivo_descricao_nao_vazia CHECK (TRIM(descricao) <> '')
);

COMMENT ON TABLE  MOTIVO_MULTA            IS 'Catálogo de motivos que justificam a geração de uma multa em um empréstimo.';
COMMENT ON COLUMN MOTIVO_MULTA.id_motivo  IS 'Identificador único do motivo da multa (PK).';
COMMENT ON COLUMN MOTIVO_MULTA.descricao  IS 'Descrição textual do motivo (ex.: "Devolução em atraso", "Dano ao item").';

-- ----------------------------------------------------------
-- Tabela: EMPRESTIMO
-- Registro de cada empréstimo realizado
-- ----------------------------------------------------------
CREATE TABLE EMPRESTIMO (
    id_emprestimo   INTEGER     NOT NULL,
    data_emprestimo DATE        NOT NULL,
    data_prevista   DATE        NOT NULL,
    data_devolucao  DATE,                        -- NULL enquanto não devolvido
    id_usuario      INTEGER     NOT NULL,
    id_item         INTEGER     NOT NULL,         -- item emprestado (livro, equipamento etc.)
    status          VARCHAR(20) NOT NULL DEFAULT 'ATIVO',

    CONSTRAINT pk_emprestimo       PRIMARY KEY (id_emprestimo),
    CONSTRAINT ck_emprestimo_datas CHECK (data_prevista >= data_emprestimo),
    CONSTRAINT ck_emprestimo_devolucao
        CHECK (data_devolucao IS NULL OR data_devolucao >= data_emprestimo),
    CONSTRAINT ck_emprestimo_status
        CHECK (status IN ('ATIVO', 'DEVOLVIDO', 'ATRASADO', 'CANCELADO'))
);

COMMENT ON TABLE  EMPRESTIMO                  IS 'Registra cada empréstimo de item realizado pelo sistema de biblioteca/acervo.';
COMMENT ON COLUMN EMPRESTIMO.id_emprestimo    IS 'Identificador único do empréstimo (PK).';
COMMENT ON COLUMN EMPRESTIMO.data_emprestimo  IS 'Data em que o empréstimo foi efetuado.';
COMMENT ON COLUMN EMPRESTIMO.data_prevista    IS 'Data prevista para devolução do item.';
COMMENT ON COLUMN EMPRESTIMO.data_devolucao   IS 'Data efetiva de devolução; NULL indica que o item ainda não foi devolvido.';
COMMENT ON COLUMN EMPRESTIMO.id_usuario       IS 'Referência ao usuário responsável pelo empréstimo.';
COMMENT ON COLUMN EMPRESTIMO.id_item          IS 'Referência ao item emprestado.';
COMMENT ON COLUMN EMPRESTIMO.status           IS 'Estado corrente do empréstimo: ATIVO, DEVOLVIDO, ATRASADO ou CANCELADO.';

-- ----------------------------------------------------------
-- Tabela: MULTA
-- Multas geradas a partir de empréstimos com problemas
-- ----------------------------------------------------------
CREATE TABLE MULTA (
    id_multa        INTEGER         NOT NULL,
    valor           DECIMAL(10,2)   NOT NULL,
    data_geracao    DATE            NOT NULL,
    data_pagamento  DATE,                        -- NULL enquanto não paga
    dias_atraso     INTEGER         NOT NULL DEFAULT 0,
    status          VARCHAR(20)     NOT NULL DEFAULT 'PENDENTE',
    id_emprestimo   INTEGER         NOT NULL,
    id_motivo       INTEGER         NOT NULL,

    CONSTRAINT pk_multa             PRIMARY KEY (id_multa),
    CONSTRAINT fk_multa_emprestimo  FOREIGN KEY (id_emprestimo)
                                    REFERENCES EMPRESTIMO (id_emprestimo)
                                    ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_multa_motivo      FOREIGN KEY (id_motivo)
                                    REFERENCES MOTIVO_MULTA (id_motivo)
                                    ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_multa_valor       CHECK (valor > 0),
    CONSTRAINT ck_multa_dias        CHECK (dias_atraso >= 0),
    CONSTRAINT ck_multa_pagamento
        CHECK (data_pagamento IS NULL OR data_pagamento >= data_geracao),
    CONSTRAINT ck_multa_status
        CHECK (status IN ('PENDENTE', 'PAGA', 'CANCELADA', 'CONTESTADA'))
);

COMMENT ON TABLE  MULTA                IS 'Multas geradas por empréstimos com atraso ou outros problemas. Cada multa está associada a um empréstimo e a um motivo.';
COMMENT ON COLUMN MULTA.id_multa       IS 'Identificador único da multa (PK).';
COMMENT ON COLUMN MULTA.valor          IS 'Valor monetário da multa em reais (deve ser positivo).';
COMMENT ON COLUMN MULTA.data_geracao   IS 'Data em que a multa foi gerada automaticamente pelo sistema.';
COMMENT ON COLUMN MULTA.data_pagamento IS 'Data em que a multa foi quitada; NULL indica multa ainda pendente.';
COMMENT ON COLUMN MULTA.dias_atraso    IS 'Quantidade de dias de atraso que originou a multa.';
COMMENT ON COLUMN MULTA.status         IS 'Situação da multa: PENDENTE, PAGA, CANCELADA ou CONTESTADA.';
COMMENT ON COLUMN MULTA.id_emprestimo  IS 'FK para o empréstimo que gerou esta multa.';
COMMENT ON COLUMN MULTA.id_motivo      IS 'FK para o motivo que classificou esta multa.';


-- ============================================================
-- SEÇÃO 2 — DML (Data Manipulation Language) — Dados de Teste
-- ============================================================

-- ----------------------------------------------------------
-- Motivos de Multa (10 registros)
-- ----------------------------------------------------------
INSERT INTO MOTIVO_MULTA (id_motivo, descricao) VALUES
(1,  'Devolução em atraso'),
(2,  'Dano parcial ao item'),
(3,  'Dano total ao item'),
(4,  'Perda do item'),
(5,  'Devolução em local incorreto'),
(6,  'Item devolvido sem embalagem protetora'),
(7,  'Marcações ou anotações indevidas'),
(8,  'Página(s) rasgada(s)'),
(9,  'Manchas ou umidade no item'),
(10, 'Devolução após suspensão de conta');

-- ----------------------------------------------------------
-- Empréstimos (12 registros — entidade forte com 3+ relacionamentos)
-- ----------------------------------------------------------
INSERT INTO EMPRESTIMO (id_emprestimo, data_emprestimo, data_prevista, data_devolucao, id_usuario, id_item, status) VALUES
(1,  '2025-01-05', '2025-01-19', '2025-01-18', 101, 201, 'DEVOLVIDO'),
(2,  '2025-01-10', '2025-01-24', '2025-02-01', 102, 202, 'DEVOLVIDO'),  -- 8 dias de atraso
(3,  '2025-02-03', '2025-02-17', '2025-03-05', 103, 203, 'DEVOLVIDO'),  -- 16 dias de atraso
(4,  '2025-02-15', '2025-03-01', NULL,          104, 204, 'ATRASADO'),  -- ainda não devolvido
(5,  '2025-03-01', '2025-03-15', '2025-03-14', 105, 205, 'DEVOLVIDO'),
(6,  '2025-03-10', '2025-03-24', '2025-04-10', 106, 206, 'DEVOLVIDO'),  -- 17 dias de atraso + dano
(7,  '2025-04-01', '2025-04-15', NULL,          107, 207, 'ATRASADO'),  -- ainda não devolvido
(8,  '2025-04-05', '2025-04-19', '2025-04-19', 108, 208, 'DEVOLVIDO'),
(9,  '2025-05-01', '2025-05-15', '2025-05-20', 109, 209, 'DEVOLVIDO'),  -- 5 dias de atraso
(10, '2025-05-10', '2025-05-24', '2025-05-23', 110, 210, 'DEVOLVIDO'),
(11, '2025-06-01', '2025-06-15', '2025-07-02', 101, 211, 'DEVOLVIDO'),  -- 17 dias de atraso
(12, '2025-06-20', '2025-07-04', NULL,          102, 212, 'ATIVO');

-- ----------------------------------------------------------
-- Multas (15 registros)
-- ----------------------------------------------------------
INSERT INTO MULTA (id_multa, valor, data_geracao, data_pagamento, dias_atraso, status, id_emprestimo, id_motivo) VALUES
(1,  16.00,  '2025-02-01', '2025-02-05', 8,  'PAGA',       2,  1),
(2,  32.00,  '2025-03-05', '2025-03-10', 16, 'PAGA',       3,  1),
(3,  45.00,  '2025-03-20', NULL,          33, 'PENDENTE',   4,  1),  -- emp 4 ainda atrasado
(4,  34.00,  '2025-04-10', NULL,          17, 'PENDENTE',   6,  1),
(5,  80.00,  '2025-04-10', '2025-04-15', 17, 'PAGA',       6,  2),  -- dano + atraso
(6,  60.00,  '2025-04-30', NULL,          14, 'CONTESTADA', 7,  1),  -- emp 7 ainda atrasado
(7,  10.00,  '2025-05-20', '2025-05-22', 5,  'PAGA',       9,  1),
(8, 200.00,  '2025-05-20', NULL,          5,  'PENDENTE',   9,  4),  -- perda do item
(9,  15.00,  '2025-07-02', NULL,          17, 'PENDENTE',  11,  1),
(10, 50.00,  '2025-07-02', '2025-07-08', 17, 'PAGA',      11,  7),  -- marcações indevidas
(11, 25.00,  '2025-03-06', NULL,          16, 'CONTESTADA',  3,  8),  -- páginas rasgadas
(12, 12.00,  '2025-04-11', '2025-04-20', 17, 'PAGA',       6,  6),  -- sem embalagem
(13,  8.00,  '2025-05-21', NULL,           5, 'PENDENTE',   9,  9),  -- manchas
(14, 40.00,  '2026-01-15', NULL,           0, 'PENDENTE',   4,  10), -- suspensão de conta
(15, 18.00,  '2025-04-30', '2025-05-03', 14, 'PAGA',       7,   5); -- local incorreto


-- ============================================================
-- SEÇÃO 3 — CONSULTAS SQL (Q1 a Q10)
-- ============================================================

-- ----------------------------------------------------------
-- Q1 — Projeção e Seleção Simples
-- Pergunta de negócio: Quais multas estão pendentes com valor
-- acima de R$ 20,00, ordenadas do maior para o menor valor?
-- ----------------------------------------------------------
SELECT
    m.id_multa,
    m.valor,
    m.dias_atraso,
    m.data_geracao,
    m.status
FROM MULTA m
WHERE m.status = 'PENDENTE'
  AND m.valor > 20.00
ORDER BY m.valor DESC;


-- ----------------------------------------------------------
-- Q2 — Projeção e Seleção com Operadores Lógicos/Especiais
-- Pergunta de negócio: Quais multas foram geradas no primeiro
-- semestre de 2025 e possuem status PAGA ou CONTESTADA?
-- ----------------------------------------------------------
SELECT
    m.id_multa,
    m.valor,
    m.data_geracao,
    m.status,
    m.id_emprestimo
FROM MULTA m
WHERE m.data_geracao BETWEEN '2025-01-01' AND '2025-06-30'
  AND m.status IN ('PAGA', 'CONTESTADA')
ORDER BY m.data_geracao;


-- ----------------------------------------------------------
-- Q3 — INNER JOIN (2 tabelas)
-- Pergunta de negócio: Listar todas as multas com a descrição
-- do seu motivo, mostrando apenas as ainda não pagas.
-- ----------------------------------------------------------
SELECT
    m.id_multa,
    mm.descricao          AS motivo,
    m.valor,
    m.dias_atraso,
    m.status,
    m.data_geracao
FROM MULTA m
INNER JOIN MOTIVO_MULTA mm ON mm.id_motivo = m.id_motivo
WHERE m.status <> 'PAGA'
ORDER BY m.valor DESC;


-- ----------------------------------------------------------
-- Q4 — INNER JOIN (3 tabelas)
-- Pergunta de negócio: Para cada multa, exibir dados do
-- empréstimo de origem e o motivo, a fim de análise completa.
-- ----------------------------------------------------------
SELECT
    e.id_emprestimo,
    e.data_emprestimo,
    e.data_prevista,
    e.data_devolucao,
    e.id_usuario,
    mm.descricao          AS motivo_multa,
    m.valor               AS valor_multa,
    m.dias_atraso,
    m.status              AS status_multa
FROM MULTA m
INNER JOIN EMPRESTIMO   e  ON e.id_emprestimo = m.id_emprestimo
INNER JOIN MOTIVO_MULTA mm ON mm.id_motivo    = m.id_motivo
ORDER BY e.id_emprestimo, m.id_multa;


-- ----------------------------------------------------------
-- Q5 — LEFT OUTER JOIN
-- Pergunta de negócio: Listar todos os empréstimos e indicar
-- quais ainda não geraram nenhuma multa (lado direito NULL).
-- ----------------------------------------------------------
SELECT
    e.id_emprestimo,
    e.id_usuario,
    e.data_emprestimo,
    e.data_prevista,
    e.status              AS status_emprestimo,
    m.id_multa,           -- NULL para empréstimos sem multa
    m.valor               -- NULL para empréstimos sem multa
FROM EMPRESTIMO e
LEFT JOIN MULTA m ON m.id_emprestimo = e.id_emprestimo
ORDER BY e.id_emprestimo;


-- ----------------------------------------------------------
-- Q6 — Agrupamento e Agregação com HAVING
-- Pergunta de negócio: Quais motivos geraram mais de uma multa?
-- Mostrar total de ocorrências e soma dos valores por motivo.
-- ----------------------------------------------------------
SELECT
    mm.id_motivo,
    mm.descricao                  AS motivo,
    COUNT(m.id_multa)             AS qtd_multas,
    SUM(m.valor)                  AS total_valor,
    AVG(m.valor)                  AS media_valor,
    MAX(m.valor)                  AS maior_multa,
    MIN(m.valor)                  AS menor_multa
FROM MOTIVO_MULTA mm
INNER JOIN MULTA m ON m.id_motivo = mm.id_motivo
GROUP BY mm.id_motivo, mm.descricao
HAVING COUNT(m.id_multa) > 1
ORDER BY qtd_multas DESC;


-- ----------------------------------------------------------
-- Q7 — Subquery Não Correlacionada
-- Pergunta de negócio: Listar todas as multas cujo valor
-- está acima da média geral de todas as multas do sistema.
-- ----------------------------------------------------------
SELECT
    m.id_multa,
    m.valor,
    m.status,
    m.id_emprestimo,
    m.id_motivo
FROM MULTA m
WHERE m.valor > (
    SELECT AVG(valor)
    FROM MULTA
)
ORDER BY m.valor DESC;


-- ----------------------------------------------------------
-- Q8 — Subquery Correlacionada com EXISTS
-- Pergunta de negócio: Quais empréstimos possuem pelo menos
-- uma multa com status CONTESTADA?
-- ----------------------------------------------------------
SELECT
    e.id_emprestimo,
    e.id_usuario,
    e.data_emprestimo,
    e.data_prevista,
    e.status AS status_emprestimo
FROM EMPRESTIMO e
WHERE EXISTS (
    SELECT 1
    FROM MULTA m
    WHERE m.id_emprestimo = e.id_emprestimo   -- referência à query externa
      AND m.status = 'CONTESTADA'
)
ORDER BY e.id_emprestimo;


-- ----------------------------------------------------------
-- Q9 — CTE (WITH) / VIEW
-- Pergunta de negócio: Ranking dos usuários com maior valor
-- total de multas pendentes, usando CTE para calcular subtotais.
-- ----------------------------------------------------------
WITH multas_por_usuario AS (
    SELECT
        e.id_usuario,
        COUNT(m.id_multa)   AS qtd_multas_pendentes,
        SUM(m.valor)        AS total_pendente
    FROM MULTA m
    INNER JOIN EMPRESTIMO e ON e.id_emprestimo = m.id_emprestimo
    WHERE m.status = 'PENDENTE'
    GROUP BY e.id_usuario
)
SELECT
    id_usuario,
    qtd_multas_pendentes,
    total_pendente,
    RANK() OVER (ORDER BY total_pendente DESC) AS ranking
FROM multas_por_usuario
ORDER BY total_pendente DESC;


-- ----------------------------------------------------------
-- Q10 — Consulta de Negócio Livre (complexidade combinada)
-- Pergunta de negócio: Relatório gerencial mensal de multas —
-- total arrecadado (pagas), total a receber (pendentes),
-- percentual de inadimplência e motivo mais frequente,
-- agrupados por mês de geração da multa.
-- ----------------------------------------------------------
WITH base AS (
    SELECT
        TO_CHAR(m.data_geracao, 'YYYY-MM')  AS mes_geracao,
        m.status,
        m.valor,
        mm.descricao                         AS motivo
    FROM MULTA m
    INNER JOIN MOTIVO_MULTA mm ON mm.id_motivo = m.id_motivo
),
resumo_mes AS (
    SELECT
        mes_geracao,
        COUNT(*)                                                          AS total_multas,
        SUM(valor)                                                        AS valor_total,
        SUM(CASE WHEN status = 'PAGA'     THEN valor ELSE 0 END)         AS valor_arrecadado,
        SUM(CASE WHEN status = 'PENDENTE' THEN valor ELSE 0 END)         AS valor_a_receber,
        COUNT(CASE WHEN status = 'PENDENTE' THEN 1 END)                  AS qtd_pendentes
    FROM base
    GROUP BY mes_geracao
),
motivo_dominante AS (
    SELECT DISTINCT ON (mes_geracao)
        mes_geracao,
        motivo            AS motivo_mais_frequente,
        COUNT(*) AS freq
    FROM base
    GROUP BY mes_geracao, motivo
    ORDER BY mes_geracao, COUNT(*) DESC
)
SELECT
    r.mes_geracao,
    r.total_multas,
    r.valor_total,
    r.valor_arrecadado,
    r.valor_a_receber,
    r.qtd_pendentes,
    ROUND(
        100.0 * r.qtd_pendentes / NULLIF(r.total_multas, 0), 1
    )                              AS pct_inadimplencia,
    md.motivo_mais_frequente
FROM resumo_mes r
LEFT JOIN motivo_dominante md USING (mes_geracao)
ORDER BY r.mes_geracao;
