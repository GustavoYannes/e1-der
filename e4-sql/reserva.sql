-- MÓDULO: RESERVA
-- PostgreSQL
-- =====================================================

-- =====================================================
-- A) DDL - CRIAÇÃO DAS TABELAS
-- =====================================================

DROP TABLE IF EXISTS reserva CASCADE;
DROP TABLE IF EXISTS usuario CASCADE;
DROP TABLE IF EXISTS exemplar CASCADE;

-- =====================================================
-- TABELA USUARIO
-- =====================================================

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

COMMENT ON TABLE usuario IS 'Tabela responsável pelos usuários do sistema';
COMMENT ON COLUMN usuario.id_usuario IS 'Identificador único do usuário';
COMMENT ON COLUMN usuario.nome IS 'Nome completo do usuário';

-- =====================================================
-- TABELA EXEMPLAR
-- =====================================================

CREATE TABLE exemplar (
    id_tombo SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL
);

COMMENT ON TABLE exemplar IS 'Tabela responsável pelos exemplares disponíveis';
COMMENT ON COLUMN exemplar.id_tombo IS 'Identificador único do exemplar';
COMMENT ON COLUMN exemplar.nome IS 'Nome do exemplar';

-- =====================================================
-- TABELA RESERVA
-- =====================================================

CREATE TABLE reserva (
    id_reserva SERIAL PRIMARY KEY,

    data_reserva DATE NOT NULL,

    data_validade DATE NOT NULL,

    status VARCHAR(20) NOT NULL,

    id_usuario INT NOT NULL,

    id_exemplar INT NOT NULL,

    CONSTRAINT fk_reserva_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario),

    CONSTRAINT fk_reserva_exemplar
        FOREIGN KEY (id_exemplar)
        REFERENCES exemplar(id_tombo),

    CONSTRAINT chk_status
        CHECK (status IN ('ATIVA', 'FINALIZADA', 'CANCELADA')),

    CONSTRAINT chk_data_validade
        CHECK (data_validade >= data_reserva)
);

COMMENT ON TABLE reserva IS 'Tabela responsável pelo controle de reservas';
COMMENT ON COLUMN reserva.id_reserva IS 'Identificador único da reserva';
COMMENT ON COLUMN reserva.data_reserva IS 'Data em que a reserva foi realizada';
COMMENT ON COLUMN reserva.data_validade IS 'Data limite da reserva';
COMMENT ON COLUMN reserva.status IS 'Situação atual da reserva';
COMMENT ON COLUMN reserva.id_usuario IS 'Usuário responsável pela reserva';
COMMENT ON COLUMN reserva.id_exemplar IS 'Exemplar reservado';

-- =====================================================
-- B) DML - INSERÇÃO DE DADOS
-- =====================================================

-- =========================
-- USUARIOS
-- =========================

INSERT INTO usuario (nome) VALUES
('Carlos Eduardo'),
('Fernanda Lima'),
('João Pedro'),
('Amanda Souza'),
('Lucas Martins'),
('Mariana Oliveira'),
('Ricardo Alves'),
('Patrícia Gomes'),
('Bruno Henrique'),
('Juliana Costa');

-- =========================
-- EXEMPLARES
-- =========================

INSERT INTO exemplar (nome) VALUES
('Dom Casmurro'),
('O Pequeno Príncipe'),
('Clean Code'),
('Engenharia de Software Moderna'),
('Banco de Dados'),
('Java Como Programar'),
('Estruturas de Dados em C'),
('Algoritmos'),
('Design Patterns'),
('Arquitetura Limpa');

-- =========================
-- RESERVAS
-- =========================

INSERT INTO reserva
(data_reserva, data_validade, status, id_usuario, id_exemplar)
VALUES
('2026-05-01', '2026-05-05', 'ATIVA', 1, 1),

('2026-05-02', '2026-05-06', 'FINALIZADA', 2, 2),

('2026-05-03', '2026-05-07', 'CANCELADA', 3, 3),

('2026-05-04', '2026-05-08', 'ATIVA', 4, 4),

('2026-05-05', '2026-05-09', 'FINALIZADA', 5, 5),

('2026-05-06', '2026-05-10', 'ATIVA', 6, 6),

('2026-05-07', '2026-05-11', 'CANCELADA', 7, 7),

('2026-05-08', '2026-05-12', 'ATIVA', 8, 8),

('2026-05-09', '2026-05-13', 'FINALIZADA', 9, 9),

('2026-05-10', '2026-05-14', 'ATIVA', 10, 10);

-- =====================================================
-- C) CONSULTAS SQL
-- =====================================================

-- =====================================================
-- Q1 - Selecionar reservas ativas
-- =====================================================

SELECT *
FROM reserva
WHERE status = 'ATIVA';

-- =====================================================
-- Q2 - Reservas feitas entre duas datas
-- =====================================================

SELECT *
FROM reserva
WHERE data_reserva BETWEEN '2026-05-01' AND '2026-05-07';

-- =====================================================
-- Q3 - INNER JOIN entre reserva e usuário
-- Mostrar nome do usuário e status da reserva
-- =====================================================

SELECT
    u.nome AS usuario,
    r.status
FROM reserva r
INNER JOIN usuario u
ON r.id_usuario = u.id_usuario;

-- =====================================================
-- Q4 - INNER JOIN entre 3 tabelas
-- Mostrar usuário, exemplar e status
-- =====================================================

SELECT
    u.nome AS usuario,
    e.nome AS exemplar,
    r.status
FROM reserva r
INNER JOIN usuario u
ON r.id_usuario = u.id_usuario
INNER JOIN exemplar e
ON r.id_exemplar = e.id_tombo;

-- =====================================================
-- Q5 - LEFT JOIN
-- Mostrar usuários sem reservas
-- =====================================================

SELECT
    u.nome,
    r.id_reserva
FROM usuario u
LEFT JOIN reserva r
ON u.id_usuario = r.id_usuario
WHERE r.id_reserva IS NULL;

-- =====================================================
-- Q6 - GROUP BY e agregação
-- Quantidade de reservas por status
-- =====================================================

SELECT
    status,
    COUNT(*) AS quantidade
FROM reserva
GROUP BY status
HAVING COUNT(*) >= 1;

-- =====================================================
-- Q7 - Subquery não correlacionada
-- Reservas com data acima da média
-- =====================================================

SELECT *
FROM reserva
WHERE data_validade >
(
    SELECT AVG(data_validade - data_reserva)
    FROM reserva
);

-- =====================================================
-- Q8 - EXISTS
-- Usuários que possuem reservas
-- =====================================================

SELECT *
FROM usuario u
WHERE EXISTS
(
    SELECT 1
    FROM reserva r
    WHERE r.id_usuario = u.id_usuario
);

-- =====================================================
-- Q9 - VIEW
-- Criar visão de reservas completas
-- =====================================================

CREATE OR REPLACE VIEW vw_reservas_completas AS
SELECT
    r.id_reserva,
    u.nome AS usuario,
    e.nome AS exemplar,
    r.status,
    r.data_reserva
FROM reserva r
INNER JOIN usuario u
ON r.id_usuario = u.id_usuario
INNER JOIN exemplar e
ON r.id_exemplar = e.id_tombo;

SELECT * FROM vw_reservas_completas;

-- =====================================================
-- Q10 - Consulta de negócio
-- Exibir os exemplares mais reservados
-- =====================================================

SELECT
    e.nome AS exemplar,
    COUNT(r.id_reserva) AS total_reservas
FROM exemplar e
INNER JOIN reserva r
ON e.id_tombo = r.id_exemplar
GROUP BY e.nome
ORDER BY total_reservas DESC;