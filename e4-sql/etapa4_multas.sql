-- =============================================
-- A) DDL - CRIAÇÃO DAS TABELAS
-- =============================================

-- Remover tabelas se existirem (idempotente)
DROP TABLE IF EXISTS exemplar CASCADE;
DROP TABLE IF EXISTS localizacao_fisica CASCADE;

-- 1. TABELA: LOCALIZACAO_FISICA
CREATE TABLE localizacao_fisica (
    id_localizacao   VARCHAR(50)   PRIMARY KEY,
    endereco         VARCHAR(50)   NOT NULL,
    andar            INTEGER       CHECK (andar >= 0),
    estante          VARCHAR(30)
);

COMMENT ON TABLE localizacao_fisica IS 'Armazena as localizações físicas dos exemplares no acervo';
COMMENT ON COLUMN localizacao_fisica.id_localizacao IS 'Código único da localização física';
COMMENT ON COLUMN localizacao_fisica.endereco IS 'Descrição do local (sala, ala, setor)';
COMMENT ON COLUMN localizacao_fisica.andar IS 'Número do andar';
COMMENT ON COLUMN localizacao_fisica.estante IS 'Identificação da estante ou prateleira';

-- 2. TABELA: EXEMPLAR
CREATE TABLE exemplar (
    id_tombo           VARCHAR(20)    PRIMARY KEY,
    tipo_aquisicao     VARCHAR(30),
    data_aquisicao     DATE,
    valor_compra       DECIMAL(10,2)  DEFAULT 0.00 CHECK (valor_compra >= 0),
    status             VARCHAR(20)    DEFAULT 'DISPONIVEL' 
                       CHECK (status IN ('DISPONIVEL', 'EMPRESTADO', 'DANIFICADO', 'RESERVADO')),
    conservacao        VARCHAR(30),
    id_localizacao     VARCHAR(50)    NOT NULL,
    
    CONSTRAINT fk_exemplar_localizacao 
        FOREIGN KEY (id_localizacao) 
        REFERENCES localizacao_fisica(id_localizacao)
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
);

COMMENT ON TABLE exemplar IS 'Cadastro dos exemplares do acervo da biblioteca';
COMMENT ON COLUMN exemplar.id_tombo IS 'Número de tombo único do exemplar';
COMMENT ON COLUMN exemplar.tipo_aquisicao IS 'Tipo de aquisição (Compra, Doação, etc)';
COMMENT ON COLUMN exemplar.data_aquisicao IS 'Data da aquisição';
COMMENT ON COLUMN exemplar.valor_compra IS 'Valor pago na aquisição';
COMMENT ON COLUMN exemplar.status IS 'Situação atual do exemplar';
COMMENT ON COLUMN exemplar.conservacao IS 'Estado de conservação';

-- =============================================
-- B) DML - DADOS DE TESTE
-- =============================================

-- Inserção de Localizações Físicas
INSERT INTO localizacao_fisica (id_localizacao, endereco, andar, estante) VALUES
('SALA101-A', 'Sala de Leitura - Ala A', 1, 'E1'),
('SALA101-B', 'Sala de Leitura - Ala B', 1, 'E3'),
('SALA202',   'Sala de Periódicos', 2, 'E5'),
('DEP03',     'Depósito Geral', 0, 'D12'),
('REF001',    'Referência - Balcão', 1, 'R2'),
('INF01',     'Laboratório de Informática', 2, 'E8'),
('LIT01',     'Literatura Brasileira', 1, 'E4'),
('CIEN02',    'Ciências Exatas', 2, 'E7');

-- Inserção de Exemplares (12 registros)
INSERT INTO exemplar (id_tombo, tipo_aquisicao, data_aquisicao, valor_compra, status, conservacao, id_localizacao) VALUES
('T2023001', 'Compra',  '2023-05-10',  89.90, 'DISPONIVEL',  'Bom',     'SALA101-A'),
('T2023002', 'Doação',  '2023-06-15',   0.00, 'EMPRESTADO',  'Ótimo',   'SALA101-B'),
('T2023003', 'Compra',  '2023-08-20', 145.50, 'DISPONIVEL',  'Bom',     'SALA202'),
('T2023004', 'Compra',  '2024-01-05',  67.80, 'DANIFICADO',  'Ruim',    'DEP03'),
('T2023005', 'Doação',  '2023-11-30',   0.00, 'DISPONIVEL',  'Ótimo',   'REF001'),
('T2023006', 'Compra',  '2024-02-18', 210.00, 'EMPRESTADO',  'Bom',     'INF01'),
('T2023007', 'Compra',  '2024-03-10',  95.00, 'DISPONIVEL',  'Bom',     'LIT01'),
('T2023008', 'Doação',  '2023-09-25',   0.00, 'RESERVADO',   'Ótimo',   'SALA101-A'),
('T2023009', 'Compra',  '2024-04-01', 120.75, 'DISPONIVEL',  'Bom',     'CIEN02'),
('T2023010', 'Compra',  '2023-12-12',  78.90, 'EMPRESTADO',  'Regular', 'SALA202'),
('T2023011', 'Doação',  '2024-05-05',   0.00, 'DISPONIVEL',  'Ótimo',   'LIT01'),
('T2023012', 'Compra',  '2024-06-20', 165.00, 'DANIFICADO',  'Ruim',    'DEP03');

-- =============================================
-- C) CONSULTAS SQL (Q1 a Q10)
-- =============================================

-- Q1: Projeção e Seleção Simples
SELECT id_tombo, tipo_aquisicao, valor_compra, status 
FROM exemplar 
WHERE valor_compra > 100 AND status = 'DISPONIVEL';

-- Q2: Seleção com operadores lógicos e LIKE
SELECT id_tombo, data_aquisicao, conservacao 
FROM exemplar 
WHERE tipo_aquisicao = 'Compra' 
  AND data_aquisicao BETWEEN '2024-01-01' AND '2024-06-30'
  AND conservacao IN ('Bom', 'Ótimo');

-- Q3: INNER JOIN (2 tabelas)
SELECT 
    e.id_tombo,
    e.status,
    l.endereco AS localizacao,
    l.andar,
    l.estante
FROM exemplar e
INNER JOIN localizacao_fisica l ON e.id_localizacao = l.id_localizacao
WHERE e.status = 'EMPRESTADO';

-- Q4: INNER JOIN + Agregação
SELECT 
    l.endereco AS local,
    COUNT(e.id_tombo) AS qtd_exemplares,
    ROUND(AVG(e.valor_compra), 2) AS valor_medio
FROM localizacao_fisica l
INNER JOIN exemplar e ON l.id_localizacao = e.id_localizacao
GROUP BY l.endereco
ORDER BY qtd_exemplares DESC;

-- Q5: LEFT OUTER JOIN (exemplos sem correspondência)
SELECT 
    e.id_tombo,
    e.status,
    l.endereco
FROM exemplar e
LEFT OUTER JOIN localizacao_fisica l ON e.id_localizacao = l.id_localizacao
WHERE l.id_localizacao IS NULL;

-- Q6: RIGHT OUTER JOIN (localizações sem exemplares)
SELECT 
    l.endereco,
    e.id_tombo
FROM exemplar e
RIGHT OUTER JOIN localizacao_fisica l ON e.id_localizacao = l.id_localizacao
WHERE e.id_tombo IS NULL;

-- Q7: Subquery
SELECT id_tombo, valor_compra 
FROM exemplar 
WHERE valor_compra > (SELECT AVG(valor_compra) FROM exemplar);

-- Q8: GROUP BY + HAVING
SELECT 
    status,
    COUNT(*) AS quantidade,
    MIN(valor_compra) AS menor_valor,
    MAX(valor_compra) AS maior_valor
FROM exemplar 
GROUP BY status
HAVING COUNT(*) >= 2;

-- Q9: Consulta com ORDER BY e LIMIT
SELECT id_tombo, tipo_aquisicao, data_aquisicao, valor_compra
FROM exemplar 
ORDER BY valor_compra DESC 
LIMIT 5;

-- Q10: Junção + Agregação + Filtro
SELECT 
    l.andar,
    COUNT(e.id_tombo) AS total_exemplares,
    SUM(CASE WHEN e.status = 'EMPRESTADO' THEN 1 ELSE 0 END) AS emprestados
FROM localizacao_fisica l
LEFT JOIN exemplar e ON l.id_localizacao = e.id_localizacao
GROUP BY l.andar
ORDER BY total_exemplares DESC;

-- =============================================
-- FIM DO ARQUIVO e4-sql.sql
-- =============================================
