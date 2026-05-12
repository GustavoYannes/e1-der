-- ============================================================
-- SISTEMA DE EMPRÉSTIMOS — PostgreSQL
-- Modelo normalizado (3FN)
-- PUC Minas · Banco de Dados 2026/1
-- ============================================================


-- ============================================================
-- A) SCRIPT DDL
-- ============================================================

-- Schema (idempotente)
DROP SCHEMA IF EXISTS biblioteca CASCADE;
CREATE SCHEMA biblioteca;
SET search_path TO biblioteca;

-- ------------------------------------------------------------
-- TABELA: item
-- ------------------------------------------------------------
CREATE TABLE item (
    codigo    VARCHAR(20)  NOT NULL,
    nome      VARCHAR(100) NOT NULL,
    descricao TEXT,
    CONSTRAINT pk_item PRIMARY KEY (codigo)
);

COMMENT ON TABLE  item           IS 'Itens disponíveis para empréstimo (livros, DVDs, revistas, etc.)';
COMMENT ON COLUMN item.codigo    IS 'Código único do item (ex: LIVRO-001, DVD-003)';
COMMENT ON COLUMN item.nome      IS 'Título ou nome do item';
COMMENT ON COLUMN item.descricao IS 'Descrição complementar do item';

-- ------------------------------------------------------------
-- TABELA: usuario
-- ------------------------------------------------------------
CREATE TABLE usuario (
    id_usuario  SERIAL       NOT NULL,
    nome        VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL,
    CONSTRAINT pk_usuario PRIMARY KEY (id_usuario),
    CONSTRAINT uq_email   UNIQUE      (email),
    CONSTRAINT chk_email  CHECK       (email LIKE '%@%')
);

COMMENT ON TABLE  usuario            IS 'Usuários cadastrados que podem realizar empréstimos';
COMMENT ON COLUMN usuario.id_usuario IS 'Identificador único do usuário (gerado automaticamente)';
COMMENT ON COLUMN usuario.nome       IS 'Nome completo do usuário';
COMMENT ON COLUMN usuario.email      IS 'E-mail único do usuário — deve conter @';

-- ------------------------------------------------------------
-- TABELA: emprestimo
-- ------------------------------------------------------------
CREATE TABLE emprestimo (
    id                SERIAL      NOT NULL,
    id_usuario        INTEGER     NOT NULL,
    cod_item          VARCHAR(20) NOT NULL,
    status            VARCHAR(20) NOT NULL,
    data_inicio       DATE        NOT NULL,
    data_retorno      DATE,
    data_fim_previsto DATE        NOT NULL,
    CONSTRAINT pk_emprestimo    PRIMARY KEY (id),
    CONSTRAINT fk_emp_usuario   FOREIGN KEY (id_usuario)
                                    REFERENCES usuario(id_usuario)
                                    ON DELETE RESTRICT,
    CONSTRAINT fk_emp_item      FOREIGN KEY (cod_item)
                                    REFERENCES item(codigo)
                                    ON DELETE RESTRICT,
    CONSTRAINT chk_status       CHECK (status IN ('ativo', 'devolvido', 'atrasado')),
    CONSTRAINT chk_data_retorno CHECK (
        data_retorno IS NULL OR data_retorno >= data_inicio
    ),
    CONSTRAINT chk_data_fim     CHECK (data_fim_previsto >= data_inicio)
);

COMMENT ON TABLE  emprestimo                   IS 'Registros de empréstimos realizados';
COMMENT ON COLUMN emprestimo.id                IS 'Identificador único do empréstimo';
COMMENT ON COLUMN emprestimo.id_usuario        IS 'FK — usuário que realizou o empréstimo';
COMMENT ON COLUMN emprestimo.cod_item          IS 'FK — item emprestado';
COMMENT ON COLUMN emprestimo.status            IS 'Situação: ativo | devolvido | atrasado';
COMMENT ON COLUMN emprestimo.data_inicio       IS 'Data de início do empréstimo';
COMMENT ON COLUMN emprestimo.data_retorno      IS 'Data efetiva de devolução (NULL se não devolvido)';
COMMENT ON COLUMN emprestimo.data_fim_previsto IS 'Prazo acordado para devolução';

-- Índices
CREATE INDEX idx_emp_usuario ON emprestimo(id_usuario);
CREATE INDEX idx_emp_item    ON emprestimo(cod_item);
CREATE INDEX idx_emp_status  ON emprestimo(status);


-- ============================================================
-- B) SCRIPT DML — DADOS DE TESTE
-- ============================================================

-- Itens (12 registros)
INSERT INTO item (codigo, nome, descricao) VALUES
    ('LIVRO-001', 'Dom Casmurro',                   'Romance de Machado de Assis, 1899'),
    ('LIVRO-002', 'O Cortiço',                      'Naturalismo de Aluísio Azevedo, 1890'),
    ('LIVRO-003', 'Capitães da Areia',               'Jorge Amado — meninos de rua em Salvador'),
    ('LIVRO-004', 'A Hora da Estrela',               'Clarice Lispector — Macabéa e sua tragédia'),
    ('LIVRO-005', 'Grande Sertão: Veredas',          'Guimarães Rosa — sertão e existência'),
    ('LIVRO-006', 'Memórias Póstumas de Brás Cubas', 'Machado de Assis — narrador defunto'),
    ('LIVRO-007', 'Iracema',                         'José de Alencar — lenda do Ceará'),
    ('DVD-001',   'Cidade de Deus',                  'Filme de Fernando Meirelles, 2002'),
    ('DVD-002',   'Central do Brasil',               'Filme de Walter Salles, 1998'),
    ('DVD-003',   'Tropa de Elite',                  'Filme de José Padilha, 2007'),
    ('REV-001',   'Scientific American Brasil',      'Edição especial: Inteligência Artificial'),
    ('REV-002',   'Pesquisa FAPESP',                 'Edição 340 — Ciência e Tecnologia');

-- Usuários (10 registros)
INSERT INTO usuario (nome, email) VALUES
    ('Ana Paula Ferreira',    'ana.ferreira@email.com'),
    ('Bruno Oliveira Santos', 'bruno.santos@email.com'),
    ('Carla Mendes Rocha',    'carla.rocha@email.com'),
    ('Diego Costa Lima',      'diego.lima@email.com'),
    ('Eduarda Vieira Nunes',  'eduarda.nunes@email.com'),
    ('Felipe Alves Martins',  'felipe.martins@email.com'),
    ('Gabriela Souza Pinto',  'gabriela.pinto@email.com'),
    ('Henrique Barbosa',      'henrique.barbosa@email.com'),
    ('Isabela Cardoso Melo',  'isabela.melo@email.com'),
    ('João Pedro Teixeira',   'joao.teixeira@email.com');

-- Empréstimos (15 registros — ativos, devolvidos e atrasados)
INSERT INTO emprestimo (id_usuario, cod_item, status, data_inicio, data_retorno, data_fim_previsto) VALUES
    -- ativos
    (1,  'LIVRO-001', 'ativo',     '2025-05-01', NULL,         '2025-05-15'),
    (2,  'LIVRO-003', 'ativo',     '2025-05-05', NULL,         '2025-05-20'),
    (3,  'DVD-001',   'ativo',     '2025-05-10', NULL,         '2025-05-17'),
    (7,  'REV-001',   'ativo',     '2025-05-08', NULL,         '2025-05-22'),
    (9,  'LIVRO-007', 'ativo',     '2025-05-12', NULL,         '2025-05-26'),
    -- devolvidos
    (1,  'DVD-002',   'devolvido', '2025-04-01', '2025-04-10', '2025-04-15'),
    (4,  'LIVRO-002', 'devolvido', '2025-04-05', '2025-04-18', '2025-04-20'),
    (5,  'LIVRO-005', 'devolvido', '2025-04-10', '2025-04-22', '2025-04-25'),
    (6,  'REV-002',   'devolvido', '2025-04-12', '2025-04-19', '2025-04-26'),
    (8,  'DVD-003',   'devolvido', '2025-04-15', '2025-04-28', '2025-04-29'),
    (10, 'LIVRO-006', 'devolvido', '2025-03-20', '2025-04-02', '2025-04-03'),
    -- atrasados
    (2,  'LIVRO-004', 'atrasado',  '2025-04-20', NULL,         '2025-05-04'),
    (3,  'LIVRO-006', 'atrasado',  '2025-04-18', NULL,         '2025-05-02'),
    (6,  'DVD-001',   'atrasado',  '2025-04-25', NULL,         '2025-05-09'),
    (10, 'LIVRO-001', 'atrasado',  '2025-04-22', NULL,         '2025-05-06');


-- ============================================================
-- C) CONSULTAS SQL — 10 QUERIES OBRIGATÓRIAS
-- ============================================================

-- ------------------------------------------------------------
-- Q1 — Projeção e seleção simples
-- Empréstimos ativos ou atrasados iniciados em maio/2025
-- Operadores: AND, OR, BETWEEN
-- ------------------------------------------------------------
SELECT e.id,
       u.nome                AS usuario,
       e.cod_item,
       e.status,
       e.data_inicio,
       e.data_fim_previsto
  FROM emprestimo e
  JOIN usuario u ON u.id_usuario = e.id_usuario
 WHERE (e.status = 'ativo' OR e.status = 'atrasado')
   AND e.data_inicio BETWEEN '2025-05-01' AND '2025-05-31'
 ORDER BY e.data_inicio;

-- ------------------------------------------------------------
-- Q2 — Projeção e seleção simples
-- Usuários cujo nome contém 'a' (ILIKE) e e-mail NÃO é
-- de domínio corporativo (NOT LIKE)
-- Operadores: ILIKE, NOT LIKE
-- ------------------------------------------------------------
SELECT u.id_usuario,
       u.nome,
       u.email
  FROM usuario u
 WHERE u.nome  ILIKE '%a%'
   AND u.email NOT LIKE '%@pucminas.br'
 ORDER BY u.nome;

-- ------------------------------------------------------------
-- Q3 — INNER JOIN (3 tabelas)
-- Todos os empréstimos com nome do usuário e nome do item
-- ------------------------------------------------------------
SELECT e.id,
       u.nome   AS usuario,
       i.nome   AS item,
       e.status,
       e.data_inicio,
       e.data_fim_previsto
  FROM emprestimo e
  JOIN usuario u ON u.id_usuario = e.id_usuario
  JOIN item    i ON i.codigo     = e.cod_item
 ORDER BY e.data_inicio DESC;

-- ------------------------------------------------------------
-- Q4 — INNER JOIN (3 tabelas)
-- Empréstimos devolvidos com duração real em dias
-- ------------------------------------------------------------
SELECT e.id,
       u.nome                               AS usuario,
       i.nome                               AS item,
       e.data_inicio,
       e.data_retorno,
       (e.data_retorno - e.data_inicio)     AS dias_emprestado
  FROM emprestimo e
  JOIN usuario u ON u.id_usuario = e.id_usuario
  JOIN item    i ON i.codigo     = e.cod_item
 WHERE e.status = 'devolvido'
 ORDER BY dias_emprestado DESC;

-- ------------------------------------------------------------
-- Q5 — LEFT OUTER JOIN
-- Todos os itens e, se houver, o empréstimo ativo vinculado
-- Itens sem empréstimo ativo aparecem com NULL
-- ------------------------------------------------------------
SELECT i.codigo,
       i.nome                  AS item,
       e.id                    AS id_emprestimo,
       u.nome                  AS usuario_atual,
       e.data_fim_previsto
  FROM item i
  LEFT JOIN emprestimo e ON e.cod_item   = i.codigo
                        AND e.status     = 'ativo'
  LEFT JOIN usuario    u ON u.id_usuario = e.id_usuario
 ORDER BY usuario_atual NULLS LAST;

-- ------------------------------------------------------------
-- Q6 — Agrupamento e agregação
-- Total de empréstimos por usuário, com contagem por status
-- e média de dias até devolução
-- HAVING: apenas quem tem mais de 1 empréstimo
-- ------------------------------------------------------------
SELECT u.nome                                          AS usuario,
       COUNT(e.id)                                     AS total_emprestimos,
       COUNT(CASE WHEN e.status = 'devolvido' THEN 1 END) AS devolvidos,
       COUNT(CASE WHEN e.status = 'atrasado'  THEN 1 END) AS atrasados,
       ROUND(AVG(e.data_retorno - e.data_inicio)
             FILTER (WHERE e.data_retorno IS NOT NULL), 1)
                                                       AS media_dias_devolucao
  FROM usuario    u
  JOIN emprestimo e ON e.id_usuario = u.id_usuario
 GROUP BY u.id_usuario, u.nome
HAVING COUNT(e.id) > 1
 ORDER BY total_emprestimos DESC;

-- ------------------------------------------------------------
-- Q7 — Subquery não correlacionada
-- Empréstimos cujo item já foi emprestado mais de uma vez
-- (subconsulta no WHERE com IN)
-- ------------------------------------------------------------
SELECT e.id,
       u.nome  AS usuario,
       i.nome  AS item,
       e.status
  FROM emprestimo e
  JOIN usuario u ON u.id_usuario = e.id_usuario
  JOIN item    i ON i.codigo     = e.cod_item
 WHERE e.cod_item IN (
     SELECT cod_item
       FROM emprestimo
      GROUP BY cod_item
     HAVING COUNT(*) > 1
 )
 ORDER BY e.cod_item, e.data_inicio;

-- ------------------------------------------------------------
-- Q8 — Subquery correlacionada com EXISTS
-- Usuários que possuem pelo menos um empréstimo atrasado
-- ------------------------------------------------------------
SELECT u.id_usuario,
       u.nome,
       u.email
  FROM usuario u
 WHERE EXISTS (
     SELECT 1
       FROM emprestimo e
      WHERE e.id_usuario = u.id_usuario
        AND e.status = 'atrasado'
 )
 ORDER BY u.nome;

-- ------------------------------------------------------------
-- Q9 — CTE (WITH)
-- Ranking de usuários por quantidade de empréstimos atrasados,
-- com data do primeiro atraso e do prazo mais recente
-- ------------------------------------------------------------
WITH atrasos_por_usuario AS (
    SELECT u.id_usuario,
           u.nome,
           COUNT(e.id)            AS total_atrasados,
           MIN(e.data_inicio)     AS primeiro_atraso,
           MAX(e.data_fim_previsto) AS ultimo_prazo
      FROM usuario    u
      JOIN emprestimo e ON e.id_usuario = u.id_usuario
                       AND e.status     = 'atrasado'
     GROUP BY u.id_usuario, u.nome
),
ranking AS (
    SELECT *,
           RANK() OVER (ORDER BY total_atrasados DESC) AS posicao
      FROM atrasos_por_usuario
)
SELECT posicao,
       nome,
       total_atrasados,
       primeiro_atraso,
       ultimo_prazo
  FROM ranking
 ORDER BY posicao;

-- ------------------------------------------------------------
-- Q10 — Consulta de negócio livre
-- Relatório de cobrança: itens atrasados com dias de atraso,
-- dados do responsável e histórico de pontualidade do usuário
-- (subqueries correlacionadas para enriquecer o relatório)
-- ------------------------------------------------------------
SELECT i.codigo,
       i.nome                                              AS item,
       u.nome                                             AS usuario_responsavel,
       u.email,
       e.data_inicio,
       e.data_fim_previsto,
       (CURRENT_DATE - e.data_fim_previsto)               AS dias_em_atraso,
       (SELECT COUNT(*)
          FROM emprestimo e2
         WHERE e2.id_usuario = u.id_usuario
           AND e2.status     = 'devolvido')               AS total_devolucoes_ok,
       (SELECT COUNT(*)
          FROM emprestimo e3
         WHERE e3.id_usuario = u.id_usuario
           AND e3.status     = 'atrasado')                AS total_reincidencias
  FROM emprestimo e
  JOIN item    i ON i.codigo     = e.cod_item
  JOIN usuario u ON u.id_usuario = e.id_usuario
 WHERE e.status = 'atrasado'
 ORDER BY dias_em_atraso DESC;
