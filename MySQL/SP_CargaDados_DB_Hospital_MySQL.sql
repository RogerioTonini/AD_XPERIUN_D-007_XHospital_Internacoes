-- Stored Procedure para carregar dados para o banco de dados do hospital
DELIMITER $

CREATE PROCEDURE SP_CargaDados_DB_Hospital(
    IN ExtArqs VARCHAR(4) DEFAULT '.CSV',
    IN PastaArqs VARCHAR(100) DEFAULT 'D:\Users\rtoni\OneDrive\Git-Dados\Projetos\AD_XPERIUN_D-007_XHospital\Dados\',
    IN ErrorFile VARCHAR(200) DEFAULT 'ErrorLog.txt'
)
BEGIN
    -- Variáveis para a stored procedure
    DECLARE DB_TB_NOME VARCHAR(MAX);
    DECLARE CMD_SQL VARCHAR(MAX);
    DECLARE QTDTABELAS INT;
    DECLARE NUM_TABELA INT DEFAULT 1;
    DECLARE TB_NOME VARCHAR(30);
    DECLARE NOME_ARQ VARCHAR(30);
    DECLARE NOME_COL VARCHAR(MAX);
    DECLARE RES_ALTA INT DEFAULT 0;
    DECLARE RES_ACOM INT DEFAULT 0;
    DECLARE ExisteDir TINYINT;

    -- Verifica se o último caractere do caminho dos arquivos é uma barra invertida
    IF RIGHT(PastaArqs, 1) <> '\\' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O último caractere do Caminho dos Arquivos de Dados NÃO é a [\] CONTRA-BARRA';
        RETURN;
    END IF;

    -- Verifica se o diretório existe
    SET ExisteDir = (SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = 'root') AS 'existe');
    IF ExisteDir = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O diretório não existe!!!! Verificar!';
        RETURN;
    END IF;

    -- Criação da Tabela Virtual com Relação de Tabelas
    CREATE TEMPORARY TABLE LST_TABELAS (
        ID_Tabela INT,
        NomeTabela VARCHAR(30),
        NomeArqImportar VARCHAR(100)
    );

    INSERT INTO LST_TABELAS VALUES
        (1, 'T_Classe_Procedimento', 'tab_classe_procedimento'),
        (2, 'T_Convenio', 'tab_convenio'),
        (3, 'T_Faixa_Idade', 'tab_faixa_idade'),
        (4, 'T_Internacao', 'tab_internacoes'),
        (5, 'T_Medico', 'tab_medicos'),
        (6, 'T_Paciente', 'tab_paciente'),
        (7, 'T_Procedimento', 'tab_procedimento'),
        (8, 'T_Tipo_Acomodacao', NULL),
        (9, 'T_Tipo_Alta', NULL);

    -- Criação da Tabela Virtual com Relação de Campos
    CREATE TEMPORARY TABLE LST_CAMPOS (
        ID_TabelaCampo INT,
        Nome_DefCampo VARCHAR(255)
    );

    INSERT INTO LST_CAMPOS VALUES
    -- T_Classe_Procedimento
    (
        1,
        'Cod_ClasseProc INT AUTO_INCREMENT PRIMARY KEY, ' +
		'Descr_ClasseProc VARCHAR(15)'
    ),
    -- T_Convenio
    (
        2,
        'Cod_Convenio INT AUTO_INCREMENT PRIMARY KEY, Descr_Convenio VARCHAR(30)'
    ),
    -- Faixa_Idade
    (
        3,
        'ID_Faixa INT AUTO_INCREMENT PRIMARY KEY, Descr_Faixa VARCHAR(22) NOT NULL, IdadeInicio INT NOT NULL, IdadeFim INT NOT NULL'
    ),
    -- T_Internacao
    (
        4,
        'DataAdmissao_ VARCHAR(23) NOT NULL, DataAlta_ VARCHAR(23), Tipo_Alta_ VARCHAR(15), Cod_Paciente_ INT, Num_Internacao_ INT, Cod_Medico_ INT, Cod_Procedimento_ INT, Valor_ VARCHAR(20), Tipo_Acomodacao_ VARCHAR(20)'
    ),
    -- T_Medico
    (
        5,
        'Cod_Medico INT AUTO_INCREMENT PRIMARY KEY, Nome_Medico VARCHAR(40)'
    ),
    -- T_Paciente
    (
        6,
        'Cod_Paciente INT AUTO_INCREMENT PRIMARY KEY, Nome_Paciente VARCHAR(40), Sexo_Paciente VARCHAR(1), Dt_Nascimento_ VARCHAR(23), Cod_Convenio INT'
    ),
    -- T_Procedimento - cod_procedimento, procedimento,cod_classe
    (
        7,
        'Cod_Procedimento INT AUTO_INCREMENT PRIMARY KEY, Descr_Procedimento VARCHAR(50), Cod_Classe INT'
    ),
    -- T_Tipo_Acomodacao
    (
        8,
        'Cod_TipoAcomodacao INT AUTO_INCREMENT PRIMARY KEY, Descr_Acomodacao VARCHAR(50) NOT NULL'
    ),
    -- T_Tipo_Alta -
    (
        9,
        'Cod_TipoAlta INT AUTO_INCREMENT PRIMARY KEY, Descr_Alta VARCHAR(20) NOT NULL'
    );

    -- Loop de Criação de Tabelas
    SELECT COUNT(*) INTO QTDTABELAS FROM LST_TABELAS;

    WHILE NUM_TABELA <= QTDTABELAS DO
        SELECT NomeTabela, NomeArqImportar INTO TB_NOME, NOME_ARQ FROM LST_TABELAS WHERE ID_Tabela = NUM_TABELA;

        SELECT Nome_DefCampo INTO NOME_COL FROM LST_CAMPOS WHERE ID_TabelaCampo = NUM_TABELA;

        -- Verifica se a tabela existe. Se não existir Cria
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = TB_NOME) THEN
            SELECT CONCAT('A tabela: [', TB_NOME, '] JÁ EXISTE!');
        ELSE
            SELECT CONCAT('A tabela: [', TB_NOME, '] não existe!');

            SET CMD_SQL = CONCAT('CREATE TABLE ', TB_NOME, ' (', NOME_COL, ')');
            PREPARE stmt FROM CMD_SQL;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            -- Importa os arquivos CSV
            IF NUM_TABELA < 8 THEN
                SET CMD_SQL = CONCAT(
                    'LOAD DATA INFILE "', PastaArqs, NOME_ARQ, ExtArqs, '" ',
                    'INTO TABLE ', TB_NOME, ' ',
                    'FIELDS TERMINATED BY \',\' ',
                    'ENCLOSED BY '\'"',
                    'LINES TERMINATED BY \'\n\' ',
                    'IGNORE 1 ROWS'
                );

                PREPARE stmt FROM CMD_SQL;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            END IF;

            -- Altera estrutura / Insere dados na(s) Tabelas
            IF NUM_TABELA = 4 THEN -- T_Internacao
                ALTER TABLE T_Internacao
                ADD COLUMN ID_Internacao INT AUTO_INCREMENT PRIMARY KEY,
                ADD COLUMN Num_Internacao INT,
                ADD COLUMN DataAdmissao DATE,
                ADD COLUMN HoraAdmissao TIME,
                ADD COLUMN DataAlta DATE,
                ADD COLUMN HoraAlta TIME,
                ADD COLUMN Cod_Paciente INT,
                ADD COLUMN Cod_Medico INT,
                ADD COLUMN Cod_Procedimento INT,
                ADD COLUMN Cod_TipoAcomodacao INT,
                ADD COLUMN Cod_TipoAlta INT,
                ADD COLUMN ValorDespesas DECIMAL(10, 2);

                -- Atualiza a Coluna Tipo_Alta_ cuja as informações de DataAdmissao_ <> '' e NULLIF(Tipo_Alta_, '') IS NULL com a informação [Em Uso]
                UPDATE T_Internacao SET Tipo_Alta_ = 'Em Uso' WHERE DataAdmissao_ <> '' AND Tipo_Alta_ IS NULL;

                -- Atualiza a Coluna Tipo_Alta_ cuja as informações de DataAdmissao_ e DataAlta_ NÃO estão vazias com a informação [Não Registrado]
                UPDATE T_Internacao SET Tipo_Alta_ = 'Não Registrado' WHERE DataAdmissao_ <> '' AND DataAlta_ <> '' AND Tipo_Alta_ IS NULL;

                UPDATE T_Internacao
                SET
                    DataAdmissao = STR_TO_DATE(SUBSTRING(DataAdmissao_, 1, 10), '%Y-%m-%d'),
                    HoraAdmissao = STR_TO_DATE(SUBSTRING(DataAdmissao_, 12, 8), '%H:%i:%s'),
                    DataAlta = STR_TO_DATE(SUBSTRING(DataAlta_, 1, 10), '%Y-%m-%d'),
                    HoraAlta = STR_TO_DATE(SUBSTRING(DataAlta_, 12, 8), '%H:%i:%s'),
                    Cod_Paciente = Cod_Paciente_,
                    Num_Internacao = Num_Internacao_,
                    Cod_Medico = Cod_Medico_,
                    Cod_Procedimento = Cod_Procedimento_,
                    ValorDespesas = REPLACE(Valor_, ',', '.') + 0;
            END IF;

            IF NUM_TABELA = 6 THEN -- T_Paciente
                ALTER TABLE T_Paciente
                ADD COLUMN Nome_Convenio VARCHAR(30),
                ADD COLUMN Data_Nascimento DATE,
                ADD COLUMN ID_Faixa_Idade INT;

                -- Atualiza a Coluna [Nome_Convenio] com as informações da Tabela _Convenio, coluna [Descr_Convenio]
                -- e a Coluna [Data_Nascimento] somente com a data de nascimento, coluna [DT_Nascimento_] convertendo de TEXTO para DATE
                UPDATE T_Paciente
                SET
                    Nome_Convenio = (SELECT Descr_Convenio FROM T_Convenio WHERE Cod_Convenio = T_Paciente.Cod_Convenio),
                    Data_Nascimento = STR_TO_DATE(SUBSTRING(Dt_Nascimento_, 1, 10), '%Y-%m-%d');

                -- Exclui a coluna temporária [Dt_Nascimento_]
                ALTER TABLE T_Paciente DROP COLUMN Dt_Nascimento_;
            END IF;

            IF NUM_TABELA = 8 THEN -- T_Tipo_Acomodacao
                -- Atualiza tabela T_Tipo_Acomodacao com os tipos que existem na Tabela T_Internacao
                CALL SP_Ins_ValoresUnicos_CHAR('T_Internacao', 'ti', 'Tipo_Acomodacao_', 'T_Tipo_Acomodacao', 'tac', 'Descr_Acomodacao');

                -- Atualizacao da Tabela T_Internacao, coluna Cod_TipoAcomodação
                UPDATE T_Internacao
                SET Cod_TipoAcomodacao = (SELECT Cod_TipoAcomodacao FROM T_Tipo_Acomodacao WHERE Descr_Acomodacao = T_Internacao.Tipo_Acomodacao_);
                SET RES_ACOM = 1;
            END IF;

            IF NUM_TABELA = 9 THEN -- T_Tipo_Alta
                -- Atualiza tabela T_Tipo_Alta com os tipos que existem na Tabela T_Internacao
                CALL SP_Ins_ValoresUnicos_CHAR('T_Internacao', 'ti', 'Tipo_Alta_', 'T_Tipo_Alta', 'ta', 'Descr_Alta');

                -- Atualizacao da Tabela T_Internacao, coluna Cod_TipoAcomodação
                UPDATE T_Internacao
                SET Cod_TipoAlta = (SELECT Cod_TipoAlta FROM T_Tipo_Alta WHERE Descr_Alta = T_Internacao.Tipo_Alta_);
                SET RES_ALTA = 1;

                -- Atualização das colunas que contém relação com as Tabelas: T_Tipo_Acomodacao e T_Tipo_Alta
                IF RES_ACOM = 1 AND RES_ALTA = 1 THEN
                    ALTER TABLE T_Internacao
                    DROP COLUMN DataAdmissao_,
                    DROP COLUMN DataAlta_,
                    DROP COLUMN Tipo_Alta_,
                    DROP COLUMN Cod_Paciente_,
                    DROP COLUMN Num_Internacao_,
                    DROP COLUMN Cod_Medico_,
                    DROP COLUMN Cod_Procedimento_,
                    DROP COLUMN Valor_,
                    DROP COLUMN Tipo_Acomodacao_;
                    SELECT 'EXCLUSÃO das COLUNAS TEMPORÁRIAS da Tabela: [T_Internacao] realizada com SUCESSO!!!';
                END IF;
            END IF;
        END IF;

        SET NUM_TABELA = NUM_TABELA + 1;
    END WHILE;

    DROP TEMPORARY TABLE LST_TABELAS;
    DROP TEMPORARY TABLE LST_CAMPOS;
END $

-- Stored Procedure para verificar se um diretório existe
DELIMITER $
CREATE PROCEDURE fxDiretorioExiste(
    IN Caminho VARCHAR(255)
)
BEGIN
    DECLARE Resp INT;
    DECLARE Comando VARCHAR(300);
    SET Comando = CONCAT('dir "', Caminho, '"');
    -- Executar o comando usando xp_cmdshell
    -- EXEC @Resp = xp_cmdshell @Comando, NO_OUTPUT;
    -- Retornar 1 se o diretório existir (comando executado com sucesso), caso contrário 0
    -- RETURN 
    -- CASE WHEN @Resp = 0 THEN 1 ELSE 0 
    -- END;
END $

-- Stored Procedure para inserir valores únicos de uma coluna em outra tabela
DELIMITER $
CREATE PROCEDURE SP_Ins_ValoresUnicos_CHAR(
    IN Tb_Origem VARCHAR(30),
    IN Alias_Tb_Origem VARCHAR(5),
    IN Coluna_Origem VARCHAR(50),
    IN Tb_Destino VARCHAR(30),
    IN Alias_Tb_Dest VARCHAR(5),
    IN Coluna_Destino VARCHAR(50)
)
BEGIN
    DECLARE CMD_SQL VARCHAR(MAX);

    -- Verifica se a tabela de destino já possui dados
    SET CMD_SQL = CONCAT(
        'IF EXISTS (SELECT 1 FROM ', Tb_Destino, ') THEN ',
        'INSERT INTO ', Tb_Destino, ' (', Coluna_Destino, ') ',
        'SELECT DISTINCT ', Alias_Tb_Origem, '.', Coluna_Origem, ' ',
        'FROM ', Tb_Origem, ' ', Alias_Tb_Origem, ' ',
        'WHERE NOT EXISTS ( ',
        'SELECT 1 ',
        'FROM ', Tb_Destino, ' ', Alias_Tb_Dest, ' ',
        'WHERE ', Alias_Tb_Dest, '.', Coluna_Destino, ' = ', Alias_Tb_Origem, '.', Coluna_Origem, ' ',
        ') AND ', Alias_Tb_Origem, '.', Coluna_Origem, ' IS NOT NULL ',
        'END ELSE ',
        'INSERT INTO ', Tb_Destino, ' (', Coluna_Destino, ') ',
        'SELECT DISTINCT ', Alias_Tb_Origem, '.', Coluna_Origem, ' ',
        'FROM ', Tb_Origem, ' ', Alias_Tb_Origem, ' ',
        'WHERE ', Alias_Tb_Origem, '.', Coluna_Origem, ' IS NOT NULL'
    );

    PREPARE stmt FROM CMD_SQL;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END $
DELIMITER ;

-- Stored Procedure para tratar erros
DELIMITER $

CREATE PROCEDURE SP_TrataErro(
    IN error INT,
    IN TipoMensagem CHAR(1),
    IN Tabela VARCHAR(30),
    IN NomeColuna VARCHAR(MAX)
)
BEGIN
    DECLARE InicioMensSucesso VARCHAR(15) DEFAULT 'Atualização da ';
    DECLARE FimMensSucesso VARCHAR(42) DEFAULT '] criada(s) / realizada(s) com SUCESSO!!!';
    DECLARE InicioMensErro VARCHAR(26) DEFAULT 'NÃO foi possível realizar ';
    DECLARE FimMensErro VARCHAR(15) DEFAULT ']. Verificar!!!';
    DECLARE MensTabela VARCHAR(11) DEFAULT 'da Tabela [';
    DECLARE MensColuna VARCHAR(14) DEFAULT '], Coluna(s) [';

    SET TipoMensagem = UPPER(TipoMensagem);

    SELECT '';

    IF TipoMensagem = 'C' THEN -- Criação de tabela
        IF error <> 0 THEN
            SELECT CONCAT(InicioMensErro, MensTabela, Tabela, FimMensErro);
        ELSE
            SELECT CONCAT('Tabela [', Tabela, FimMensSucesso);
        END IF;
    ELSEIF TipoMensagem = 'U' THEN -- UPLOAD de tabela
        IF error <> 0 THEN
            SELECT CONCAT(InicioMensErro, 'UPLOAD na Tabela [', Tabela, FimMensErro);
        ELSE
            SELECT CONCAT('UPLOAD ', MensTabela, Tabela, FimMensSucesso);
        END IF;
    ELSEIF TipoMensagem IN ('A', 'E') THEN -- [A] - Atualização de dados: JOIN / [E] Alteração na estrutura da Tabela (Criação/Exclusão de colunas)
        IF error <> 0 THEN
            SELECT CONCAT(InicioMensErro, MensTabela, Tabela, MensColuna, NomeColuna, FimMensErro);
        ELSE
            SELECT CONCAT(InicioMensSucesso, MensTabela, Tabela, MensColuna, NomeColuna, FimMensSucesso);
        END IF;
    END IF;
END 
$
DELIMITER ;