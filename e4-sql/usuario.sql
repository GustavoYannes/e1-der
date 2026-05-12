-- 1. DDL - Criação das Tabelas

-- Tabela: ENDERECO 
CREATE TABLE ENDERECO (
    id_endereco SERIAL PRIMARY KEY,
    cep CHAR(9) NOT NULL,
    logradouro VARCHAR(120) NOT NULL,
    numero VARCHAR(10) NOT NULL,
    bairro VARCHAR(60) NOT NULL,
    cidade VARCHAR(60) NOT NULL,
    
    CONSTRAINT ck_cep_formato CHECK (cep ~ '^[0-9]{5}-[0-9]{3}$')
);

-- Tabela: USUARIO
CREATE TABLE USUARIO (
    id_usuario SERIAL PRIMARY KEY,
    primeiro_nome VARCHAR(50) NOT NULL,
    sobrenome VARCHAR(80) NOT NULL,
    cpf CHAR(14) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    data_nascimento DATE NOT NULL,
    data_cadastro DATE NOT NULL DEFAULT CURRENT_DATE,
    tipo_usuario VARCHAR(20) NOT NULL,
    id_endereco INTEGER NOT NULL,

    CONSTRAINT fk_usuario_endereco 
        FOREIGN KEY (id_endereco) 
        REFERENCES ENDERECO(id_endereco)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    
    CONSTRAINT ck_usuario_tipo 
        CHECK (tipo_usuario IN ('ALUNO', 'PROFESSOR', 'FUNCIONARIO')),
    
    CONSTRAINT ck_data_nascimento 
        CHECK (data_nascimento < CURRENT_DATE)
);

-- Tabela: TELEFONE_USUARIO 
CREATE TABLE TELEFONE_USUARIO (
    id_usuario INTEGER NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    
    CONSTRAINT pk_telefone_usuario PRIMARY KEY (id_usuario, telefone),
    CONSTRAINT fk_telefone_usuario 
        FOREIGN KEY (id_usuario) 
        REFERENCES USUARIO(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 2. DML - Dados de Teste 

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

INSERT INTO TELEFONE_USUARIO (id_usuario, telefone) VALUES
(1, '(31) 98888-7777'), (1, '(31) 3333-2222'),
(2, '(31) 97777-6666'),
(3, '(31) 96666-5555'),
(4, '(31) 3444-1111'),
(5, '(31) 95555-4444'),
(6, '(31) 94444-3333'),
(7, '(31) 93333-2222'),
(8, '(31) 92222-1111'),
(9, '(31) 91111-0000'),
(10, '(31) 90000-9999');


-- 3. Consultas SQL 

-- Q1: Listar usuários do tipo 'ALUNO' (Seleção Simples)
SELECT primeiro_nome, sobrenome, email 
FROM USUARIO 
WHERE tipo_usuario = 'ALUNO';

-- Q2: Buscar usuários nascidos entre 1990 e 2000 (BETWEEN)
SELECT primeiro_nome, data_nascimento 
FROM USUARIO 
WHERE data_nascimento BETWEEN '1990-01-01' AND '2000-12-31';

-- Q3: Exibir nome do usuário e o logradouro onde mora (INNER JOIN 2 tabelas)
SELECT u.primeiro_nome, e.logradouro, e.cidade
FROM USUARIO u
INNER JOIN ENDERECO e ON u.id_endereco = e.id_endereco;

-- Q4: Listar usuários e seus respectivos telefones (INNER JOIN)
SELECT u.primeiro_nome, t.telefone
FROM USUARIO u
INNER JOIN TELEFONE_USUARIO t ON u.id_usuario = t.id_usuario;

-- Q5: Listar endereços que ainda não possuem usuários vinculados (LEFT JOIN)
SELECT e.logradouro, u.id_usuario
FROM ENDERECO e
LEFT JOIN USUARIO u ON e.id_endereco = u.id_endereco
WHERE u.id_usuario IS NULL;

-- Q6: Quantidade de usuários por cidade com mais de 2 registros (GROUP BY + HAVING)
SELECT e.cidade, COUNT(u.id_usuario) AS total
FROM ENDERECO e
INNER JOIN USUARIO u ON e.id_endereco = u.id_endereco
GROUP BY e.cidade
HAVING COUNT(u.id_usuario) >= 2;

-- Q7: Listar usuários que moram em cidades que começam com 'Belo' (Subquery no WHERE)
SELECT primeiro_nome, email 
FROM USUARIO 
WHERE id_endereco IN (
    SELECT id_endereco FROM ENDERECO WHERE cidade LIKE 'Belo%'
);

-- Q8: Verificar se existem usuários cadastrados sem telefone (EXISTS)
SELECT u.primeiro_nome 
FROM USUARIO u
WHERE NOT EXISTS (
    SELECT 1 FROM TELEFONE_USUARIO t WHERE t.id_usuario = u.id_usuario
);

-- Q9: Criar VIEW com o perfil completo do usuário
CREATE OR REPLACE VIEW vw_perfil_usuario AS
SELECT u.id_usuario, u.primeiro_nome, u.cpf, u.tipo_usuario, e.cidade, e.cep
FROM USUARIO u
JOIN ENDERECO e ON u.id_endereco = e.id_endereco;

SELECT * FROM vw_perfil_usuario;

-- Q10: Consulta de negócio: Ranking de usuários mais antigos por tipo (ORDER BY)
SELECT primeiro_nome, tipo_usuario, data_cadastro
FROM USUARIO
ORDER BY data_cadastro ASC, tipo_usuario DESC;
