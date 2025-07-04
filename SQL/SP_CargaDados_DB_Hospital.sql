SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_CargaDados_DB_Hospital]
    @ExtArqs     NVARCHAR(4)   = '.CSV'                                                                        -- Extensão dos arquivos a serem importados
    , @PastaArqs NVARCHAR(100) = 'D:\Users\rtoni\OneDrive\Git-Dados\Projetos\AD_XPERIUN_D-007_XHospital\Dados\' -- Pasta onde estão os arquivos a serem importados
    , @ErrorFile NVARCHAR(200) = 'ErrorLog.txt'
AS
BEGIN
    -- Declaração das variáveis
    DECLARE @DB_TB_NOME   NVARCHAR(MAX) -- Concatena @Database + '.dbo' + @TB_NOME
            , @CMD_SQL    NVARCHAR(MAX) -- Variável que contém comando a ser executado
            , @QTDTABELAS INT           -- Quantidade Total de Tabelas a serem criadas
            , @NUM_TABELA INT = 1       -- Numero da Tabela
            , @TB_NOME    NVARCHAR(30)  -- Nome da Tabela a ser criada 
            , @NOME_ARQ   NVARCHAR(30)  -- Nome do arquivo a ser importado
            , @NOME_COL   NVARCHAR(MAX) -- Definição dos Campos na Tabela Virtual @LSTCAMPOS 
            , @RES_ALTA   INT = 0       -- Resultado da operação de atualização das tabelas: T_Acomodacao e T_Internacao
            , @RES_ACOM   INT = 0       -- Resultado da operação de atualização das tabelas: T_Alta e T_Internacao
            , @ExisteDir  BIT = dbo.fxDiretorioExiste(@PastaArqs)
            
    IF SUBSTRING(@PastaArqs, LEN(@PastaArqs), 1) <> '\'
    BEGIN
        PRINT 'O último caractere do Caminho dos Arquivos de Dados NÃO é a [\] CONTRA-BARRA'
        RETURN
    END

    IF @ExisteDir <> 1
    BEGIN
        PRINT 'O diretório não existe!!!! Verificar!'
        RETURN
    END
    -- Criação da Tabela Virtual com Relação de Tabelas
    DECLARE @LST_TABELAS TABLE
        (
            ID_Tabela INT
            , NomeTabela VARCHAR(30)
            , NomeArqImportar VARCHAR(100)
        )
    INSERT INTO 
        @LST_TABELAS
    VALUES
        (1, 'T_Classe_Procedimento', 'tab_classe_procedimento')
        , (2, 'T_Convenio',          'tab_convenio')
        , (3, 'T_Faixa_Idade',       'tab_faixa_idade')
        , (4, 'T_Internacao',        'tab_internacoes')   -- antiga 3 
        , (5, 'T_Medico',            'tab_medicos')       -- antiga 4
        , (6, 'T_Paciente',          'tab_paciente')      -- antiga 5
        , (7, 'T_Procedimento',      'tab_procedimento')  -- antiga 6
        , (8, 'T_Tipo_Acomodacao',   NULL)                -- antiga 7
        , (9, 'T_Tipo_Alta',         NULL)                -- antiga 8
    IF @@ERROR <> 0
    BEGIN
        PRINT 'NÃO foi possível criar Tabela Virtual: Relação das Tabelas. Favor verificar com o Responsável.'
        RETURN
    END
    -- Criação da Tabela Virtual com Relação de Campos
    DECLARE @LST_CAMPOS TABLE
        (
            ID_TabelaCampo INT
            , Nome_DefCampo NVARCHAR(MAX)
        )
    INSERT INTO 
        @LST_CAMPOS
    VALUES
    -- T_Classe_Procedimento
    (
        1 
        , '[Cod_ClasseProc]   [int] IDENTITY(1,1) NOT NULL,' 
        + '[Descr_ClasseProc] [nvarchar](15)'
    )
    -- T_Convenio
    , (
        2
        , '[Cod_Convenio]   [int] IDENTITY(1,1) NOT NULL, ' 
        + '[Descr_Convenio] [nvarchar](30)'
    )
    -- Faixa_Idade
    , (
        3
        , '[ID_Faixa]    [int] IDENTITY(1,1) NOT NULL, ' 
        + '[Descr_Faixa] [nvarchar](22) NOT NULL, '
        + '[IdadeInicio] [int] NOT NULL, '
        + '[IdadeFim]    [int] NOT NULL'
    )
    -- T_Internacao
    , (
        4
        , '[DataAdmissao_]     [nvarchar](23) NOT NULL, ' 
        + '[DataAlta_]         [nvarchar](23), '
        + '[Tipo_Alta_]        [nvarchar](15), ' 
        + '[Cod_Paciente_]     [int], ' 
        + '[Num_Internacao_]   [int], '
        + '[Cod_Medico_]       [int], ' 
        + '[Cod_Procedimento_] [int], ' 
        + '[Valor_]            [nvarchar](20), '
        + '[Tipo_Acomodacao_]  [nvarchar](20)'
    )
    -- T_Medico
    , (
        5 
        , '[Cod_Medico]  [int]IDENTITY(1,1) NOT NULL, ' 
        + '[Nome_Medico] [nvarchar](40)'
    )
    -- T_Paciente
    , (
        6 
        , '[Cod_Paciente]   [int]IDENTITY(1,1) NOT NULL, ' 
        + '[Nome_Paciente]  [nvarchar](40), '
        + '[Sexo_Paciente]  [varchar](1), '  
        + '[Dt_Nascimento_] [nvarchar](23), ' 
        + '[Cod_Convenio]   [int]'
    )
    -- T_Procedimento - cod_procedimento, procedimento,cod_classe
    , (
        7
        , '[Cod_Procedimento]   [int]IDENTITY(1,1) NOT NULL, '
        + '[Descr_Procedimento] [nvarchar](50), '
        + '[Cod_Classe]         [int]'
    )
    -- T_Tipo_Acomodacao
    , (
        8
        , '[Cod_TipoAcomodacao] [int]IDENTITY(1,1) NOT NULL, ' 
        + '[Descr_Acomodacao]   [nvarchar](50) NOT NULL'
    )
    -- T_Tipo_Alta - 
    , (
        9
        , '[Cod_TipoAlta] [int]IDENTITY(1,1) NOT NULL, ' 
        + '[Descr_Alta]   [nvarchar](20) NOT NULL'
    )
    IF @@ERROR <> 0
    BEGIN
        PRINT 'NÃO foi possível criar Tabela Virtual: Relação dos Campos das Tabelas. Favor verificar com o Responsável.'
        RETURN
    END
    PRINT 'Tabelas Virtuais: Relação das Tabelas / Campos das Tabelas criada com sucesso!!!'
    --
    -- Loop de Criação de Tabelas
    SELECT 
        @QTDTABELAS = COUNT(*)
    FROM 
        @LST_TABELAS

    WHILE @NUM_TABELA <= @QTDTABELAS
    BEGIN
        SELECT TOP (1)
            @TB_NOME = NomeTabela,
            @NOME_ARQ = NomeArqImportar
        FROM 
            @LST_TABELAS
        WHERE 
            ID_Tabela = @NUM_TABELA

        SELECT TOP (1)
            @NOME_COL = Nome_DefCampo
        FROM 
            @LST_CAMPOS
        WHERE 
            ID_TabelaCampo = @NUM_TABELA
        --
        -- Verifica se a tabela existe. Se não existir Cria
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = @TB_NOME)
            PRINT 'A tabela: [' + @TB_NOME + '] JÁ EXISTE!'
        ELSE
        BEGIN
            PRINT 'A tabela: [' + @TB_NOME + '] não existe!'

            SET @CMD_SQL = N'CREATE TABLE ' + @TB_NOME + ' (' + @NOME_COL + ')'
            EXEC sp_executesql @CMD_SQL
            EXEC SP_TrataErro @@ERROR, 'C', @TB_NOME, ''
            --
            IF @@ERROR = 0
            BEGIN
                -- Importa os arquivos CSV
                IF @NUM_TABELA < 8
                BEGIN
                    SET @CMD_SQL =
						'BULK INSERT '  + 
							@TB_NOME +
						' FROM ' + 
							'"' + @PastaArqs + @NOME_ARQ + @ExtArqs  + '"' +
						' WITH (
							FIELDTERMINATOR = '',''
							, ROWTERMINATOR = ''\n''
							, FIRSTROW  = 2
							, CODEPAGE  = ''65001''
							, FORMAT    = ''' + SUBSTRING(@ExtArqs, 2, 3) + '''
                            , MAXERRORS = 500
                            , ERRORFILE = ''' + @PastaArqs + @ErrorFile + '''
                            , KEEPNULLS
						)'
                    EXEC sp_executesql @CMD_SQL
                    EXEC SP_TrataErro @@ERROR, 'U', @TB_NOME, ''
                END
                -- Altera estrutura / Insere dados na(s) Tabelas
                --
                IF @NUM_TABELA = 4 -- T_Internacao
                BEGIN
                    ALTER TABLE 
                        T_Internacao
                    ADD 
                        ID_Internacao        INT IDENTITY(1,1) NOT NULL
                        , Num_Internacao     INT
                        , DataAdmissao       DATE
                        , HoraAdmissao       TIME
                        , DataAlta           DATE
                        , HoraAlta           TIME
                        , Cod_Paciente       INT
                        , Cod_Medico         INT
                        , Cod_Procedimento   INT
                        , Cod_TipoAcomodacao INT
                        , Cod_TipoAlta       INT
                        , ValorDespesas      MONEY
                    --
                    EXEC SP_TrataErro @@ERROR, 'E', @TB_NOME
                        , 'ID_Internacao, Num_Internacao, DataAdmissao, HoraAdmissao, DataAlta, HoraAlta, Cod_Paciente, Cod_Medico, Cod_Procedimento, Cod_TipoAcomodacao, Cod_TipoAlta, ValorDespesas'
                    IF @@ERROR = 0
                    BEGIN
                        -- Atualiza a Coluna Tipo_Alta_ cuja as informações de DataAdmissao_ <> '' e NULLIF(Tipo_Alta_, '') IS NULL com a informação [Em Uso]
                        UPDATE 
                            T_Internacao
                        SET 
                            Tipo_Alta_ = 'Em Uso'
                        WHERE 
                            NULLIF( DataAdmissao_, '' ) IS NOT NULL 
                            AND NULLIF( DataAlta_, '' ) IS NULL
                        --
                        EXEC SP_TrataErro @@ERROR, 'E', @TB_NOME, 'Tipo_Alta_'
                        IF @@ERROR = 0
                        BEGIN
                            -- Atualiza a Coluna Tipo_Alta_ cuja as informações de DataAdmissao_ e DataAlta_ NÃO estão vazias com a informação [Não Registrado]
                            UPDATE 
                                T_Internacao
                            SET 
                                Tipo_Alta_ = 'Não Registrado'
                            WHERE 
                                NULLIF( DataAdmissao_, '' ) IS NOT NULL 
                                AND NULLIF( DataAlta_, '' ) IS NOT NULL
                                AND NULLIF( Tipo_Alta_, '' ) IS NULL
                            --
                            EXEC SP_TrataErro @@ERROR, 'E', @TB_NOME, 'DataAdmissao_, DataAlta_, Tipo_Alta_'
                            --
                            IF @@ERROR = 0
                            BEGIN
                                UPDATE 
                                    T_Internacao
                                SET 
                                    DataAdmissao       = CAST(SUBSTRING( LTRIM( RTRIM( DataAdmissao_ ) ), 1, 10 ) AS date )
                                    , HoraAdmissao     = CAST(SUBSTRING( LTRIM( RTRIM( DataAdmissao_ ) ), 12, 8 ) + '.' + SUBSTRING( LTRIM( RTRIM( DataAdmissao_ ) ), 21, 3 ) AS time )
                                    , DataAlta         = CAST(SUBSTRING( LTRIM( RTRIM( DataAlta_ ) ), 1, 10 ) AS date )
                                    , HoraAlta         = CAST(SUBSTRING( LTRIM( RTRIM( DataAlta_ ) ), 12, 8 ) + '.' + SUBSTRING( LTRIM( RTRIM( DataAlta_ ) ), 21, 3 ) AS time )
                                    , Cod_Paciente     = Cod_Paciente_
                                    , Num_Internacao   = Num_Internacao_
                                    , Cod_Medico       = Cod_Medico_
                                    , Cod_Procedimento = Cod_Procedimento_
                                    , ValorDespesas    = CONVERT( MONEY, REPLACE( Valor_, ',', '.' ) )
                                --
                                EXEC SP_TrataErro @@ERROR, 'U', @TB_NOME, ''
                            END
                        END
                    END
                END
                --
                IF @NUM_TABELA = 6 -- T_Paciente
                BEGIN
                    ALTER TABLE 
                        T_Paciente
                    ADD 
                        Nome_Convenio     NVARCHAR(30)
                        , Data_Nascimento DATE
                        , ID_Faixa_Idade  INT
                    --
                    EXEC SP_TrataErro @@ERROR, 'E', @TB_NOME, 'Nome_Convenio, Data_Nascimento'
                    IF @@ERROR = 0
                    BEGIN
                        -- Atualiza a Coluna [Nome_Convenio] com as informações da Tabela _Convenio, coluna [Descr_Convenio]
                        -- e a Coluna [Data_Nascimento] somente com a data de nascimento, coluna [DT_Nascimento_] convertendo de TEXTO para DATE
                        UPDATE 
                            T_Paciente
                        SET 
                            Nome_Convenio     = tc.Descr_Convenio
                            , Data_Nascimento = CAST(SUBSTRING( LTRIM( RTRIM( Dt_Nascimento_ ) ), 1, 10 ) AS date )
                        FROM 
                            T_Convenio tc
                        LEFT JOIN 
                            T_Paciente tp
                                ON tc.Cod_Convenio = LTRIM(RTRIM( tp.Cod_Convenio ) )
                        --
                        EXEC SP_TrataErro @@ERROR, 'U', @TB_NOME, 'Cod_Convenio'
                        --
                        -- Exclui a coluna temporária [Dt_Nascimento_]
                        ALTER TABLE 
                            T_Paciente
                        DROP COLUMN 
                            Dt_Nascimento_
                        EXEC SP_TrataErro @@ERROR, 'E', @TB_NOME, 'Dt_Nascimento_'
                    END                
                END
                --
                IF @NUM_TABELA = 8 -- T_Tipo_Acomodacao
                BEGIN
                    -- Atualiza tabela T_Tipo_Acomodacao com os tipos que existem na Tabela T_Internacao
                    EXEC SP_Ins_ValoresUnicos_CHAR 'T_Internacao', 'ti', 'Tipo_Acomodacao_', 'T_Tipo_Acomodacao', 'tac', 'Descr_Acomodacao'
                    EXEC SP_TrataErro @@ERROR, 'A', @TB_NOME, 'Tipo_Acomodacao_'
                    IF @@ERROR = 0
                    BEGIN
                        -- Atualizacao da Tabela T_Internacao, coluna Cod_TipoAcomodação
                        UPDATE 
                            T_Internacao
                        SET 
                            Cod_TipoAcomodacao = tac.Cod_TipoAcomodacao
                        FROM 
                            T_Tipo_Acomodacao tac
                        LEFT JOIN 
                            T_Internacao ti
                                ON tac.Descr_Acomodacao = LTRIM(RTRIM( ti.Tipo_Acomodacao_ ) )
                        --
                        EXEC SP_TrataErro @@ERROR, 'A', @TB_NOME, 'Cod_TipoAcomodacao'
                        IF @@ERROR =  0
                            SET @RES_ACOM = 1
                    END
                END
                --
                IF @NUM_TABELA = 9 -- T_Tipo_Alta
                BEGIN
                    -- Atualiza tabela T_Tipo_Alta com os tipos que existem na Tabela T_Internacao
                    EXEC SP_Ins_ValoresUnicos_CHAR 'T_Internacao', 'ti', 'Tipo_Alta_', 'T_Tipo_Alta', 'ta', 'Descr_Alta'                    
                    IF @@ERROR = 0
                    BEGIN
                        -- Atualizacao da Tabela T_Internacao, coluna Cod_TipoAcomodação
                        UPDATE 
                            T_Internacao
                        SET 
                            Cod_TipoAlta = tal.Cod_TipoAlta
                        FROM 
                            T_Tipo_Alta tal
                        LEFT JOIN 
                            T_Internacao ti
                                ON tal.Descr_Alta = LTRIM( RTRIM( ti.Tipo_Alta_ ) )
                        --
                        EXEC SP_TrataErro @@ERROR, 'A', @TB_NOME, 'Cod_TipoAlta'
                        IF @@ERROR = 0
                            SET @RES_ALTA = 1
                    END
                    -- Atualização das colunas que contém relação com as Tabelas: T_Tipo_Acomodacao e T_Tipo_Alta
                    IF @RES_ACOM = 1 AND @RES_ALTA = 1
                    BEGIN
                        ALTER TABLE 
                            T_Internacao
                        DROP COLUMN 
                            DataAdmissao_
                            , DataAlta_
                            , Tipo_Alta_
                            , Cod_Paciente_
                            , Num_Internacao_
                            , Cod_Medico_
                            , Cod_Procedimento_
                            , Valor_
                            , Tipo_Acomodacao_
                        IF @@ERROR <> 0
                            PRINT 'NÃO foi possível EXCLUIR as COLUNAS TEMPORÁRIAS da Tabela: [' + @TB_NOME + ']. Verificar!!!'
                        ELSE
                            PRINT 'EXCLUSÃO das COLUNAS TEMPORÁRIAS da Tabela: [' + @TB_NOME + '] realizada com SUCESSO!!!'
                    END
                END
            END
        END
        SET @NUM_TABELA += 1
    END
END
GO
