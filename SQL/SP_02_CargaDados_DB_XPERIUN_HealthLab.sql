SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_02_CargaDados_DB_XPERIUN_HealthLab]
    @ExtArqs     NVARCHAR(4)   = '.CSV'                                                                           -- Extensão dos arquivos a serem importados
    , @PastaArqs NVARCHAR(100) = 'D:\Git-Projetos\Projetos_Estudos\AD_XPERIUN_D-007_XHospital_Internacoes\Dados\' -- Pasta onde estão os arquivos a serem importados
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
            , @RES_ALTA   INT = 1       -- Resultado da operação de atualização das tabelas: T_Acomodacao e T_Internacao
            , @RES_ACOM   INT = 1       -- Resultado da operação de atualização das tabelas: T_Alta e T_Internacao
            , @RESP       VARCHAR
            , @ExisteDir  BIT = dbo.fxDiretorioExiste(@PastaArqs)
            
    --SELECT @RESP = SUBSTRING(@PastaArqs, LEN(@PastaArqs), 1)
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
        , (3, 'T_Internacao',        'tab_internacoes')
        , (4, 'T_Medico',             'tab_medicos')
        , (5, 'T_Paciente',           'tab_paciente')
        , (6, 'T_Procedimento',       'tab_procedimento')
        , (7, 'T_Tipo_Acomodacao',    NULL)
        , (8, 'T_Tipo_Alta',          NULL)
    IF @@ERROR <> 0
    BEGIN
        PRINT 'NÃO foi possível criar Tabela Virtual: Relação das Tabelas. Favor verificar com o Responsável.'
        RETURN
    END
    PRINT 'Tabela Virtual: Relação das Tabelas criada com sucesso!'
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
    -- T_Internacao
    , (
        3
        , '[DataAdmissao_TMP]     [nvarchar](23) NOT NULL, ' 
        + '[DataAlta_TMP]         [nvarchar](23), '
        + '[Tipo_Alta_TMP]        [nvarchar](15), ' 
        + '[Cod_Paciente_TMP]     [int], ' 
        + '[Num_Internacao_TMP]   [int], '
        + '[Cod_Medico_TMP]       [int], ' 
        + '[Cod_Procedimento_TMP] [int], ' 
        + '[Valor_TMP]            [nvarchar](20), '
        + '[Tipo_Acomodacao_TMP]  [nvarchar](20)'
    )
    -- T_Medico
    , (
        4 
        , '[Cod_Medico]  [int]IDENTITY(1,1) NOT NULL, ' 
        + '[Nome_Medico] [nvarchar](40)'
    )
    -- T_Paciente
    , (
        5 
        , '[Cod_Paciente]  [int]IDENTITY(1,1) NOT NULL, ' 
        + '[Nome_Paciente] [nvarchar](40), '
        + '[Sexo_Paciente] [varchar](1), '  
        + '[Dt_Nascimento] [nvarchar](23), ' 
        + '[Cod_Convenio]  [int]'
    )
    -- T_Procedimento - cod_procedimento, procedimento,cod_classe
    , (
        6
        , '[Cod_Procedimento]   [int]IDENTITY(1,1) NOT NULL, '
        + '[Descr_Procedimento] [nvarchar](50), '
        + '[Cod_Classe]         [int]'
    )
    -- T_Tipo_Acomodacao
    , (
        7
        , '[Cod_TipoAcomodacao] [int]IDENTITY(1,1) NOT NULL, ' 
        + '[Descr_Acomodacao]   [nvarchar](50) NOT NULL'
    )
    -- T_Tipo_Alta - 
    , (
        8
        , '[Cod_TipoAlta] [int]IDENTITY(1,1) NOT NULL, ' 
        + '[Descr_Alta]   [nvarchar](20) NOT NULL'
    )
    IF @@ERROR <> 0
    BEGIN
        PRINT 'NÃO foi possível criar Tabela Virtual: Relação dos Campos das Tabelas. Favor verificar com o Responsável.'
        RETURN
    END
    PRINT 'Tabela Virtual : Relação dos Campos das Tabelas criada com sucesso!'
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
            EXEC SP_MensagemErro @@ERROR, 'C', @TB_NOME, ''
            --
            IF @@ERROR = 0
            BEGIN
                -- Importa os arquivos CSV
                IF @NUM_TABELA < 7
                BEGIN
                    SET @CMD_SQL =
						'BULK INSERT '  + 
							@TB_NOME +
						' FROM ' + 
							'"' + @PastaArqs + @NOME_ARQ + @ExtArqs  + '"' +
						' WITH (
							FIELDTERMINATOR = '',''
							, ROWTERMINATOR = ''\n''
							, FIRSTROW = 2
							, CODEPAGE = ''65001''
							, FORMAT = ''' + SUBSTRING(@ExtArqs, 2, 3) + '''
						)'
                    EXEC sp_executesql @CMD_SQL
                    EXEC SP_MensagemErro @@ERROR, 'U', @TB_NOME, ''
                END
                -- Altera estrutura da(s) Tabelas / Insere dados na(s) Tabelas
                IF @NUM_TABELA = 3 -- T_Internacao
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
                    EXEC SP_MensagemErro @@ERROR, 'E', @TB_NOME
                        , 'ID_Internacao, Num_Internacao, DataAdmissao, HoraAdmissao, DataAlta, HoraAlta, Cod_Paciente, Cod_Medico, Cod_Procedimento, Cod_TipoAcomodacao, Cod_TipoAlta, ValorDespesas'
                    IF @@ERROR = 0
                    BEGIN
                        -- Atualiza a Coluna Tipo_Alta_TMP cuja as informações de DataAdmissao_TMP <> '' e NULLIF(Tipo_Alta_TMP, '') IS NULL com a informação [Em Uso]
                        UPDATE 
                            T_Internacao
                        SET 
                            Tipo_Alta_TMP = 'Em Uso'
                        WHERE 
                            NULLIF( DataAdmissao_TMP, '' ) IS NOT NULL 
                            AND NULLIF( DataAlta_TMP, '' ) IS NULL
                        --
                        EXEC SP_MensagemErro @@ERROR, 'E', @TB_NOME, 'Tipo_Alta_TMP'
                        IF @@ERROR = 0
                        BEGIN
                            -- Atualiza a Coluna Tipo_Alta_TMP cuja as informações de DataAdmissao_TMP e DataAlta_TMP NÃO estão vazias com a informação [Não Registrado]
                            UPDATE 
                                T_Internacao
                            SET 
                                Tipo_Alta_TMP = 'Não Registrado'
                            WHERE 
                                NULLIF( DataAdmissao_TMP, '' ) IS NOT NULL 
                                AND NULLIF( DataAlta_TMP, '' ) IS NOT NULL
                                AND NULLIF( Tipo_Alta_TMP, '' ) IS NULL
                            --
                            EXEC SP_MensagemErro @@ERROR, 'E', @TB_NOME, 'DataAdmissao_TMP, DataAlta_TMP, Tipo_Alta_TMP'
                            --
                            UPDATE 
                                T_Internacao
                            SET 
                                DataAdmissao       = CAST(SUBSTRING( LTRIM( RTRIM( DataAdmissao_TMP ) ), 1, 10 ) AS date )
                                , HoraAdmissao     = CAST(SUBSTRING( LTRIM( RTRIM( DataAdmissao_TMP ) ), 12, 8 ) + '.' + SUBSTRING( LTRIM( RTRIM( DataAdmissao_TMP ) ), 21, 3 ) AS time )
                                , DataAlta         = CAST(SUBSTRING( LTRIM( RTRIM( DataAlta_TMP ) ), 1, 10 ) AS date )
                                , HoraAlta         = CAST(SUBSTRING( LTRIM( RTRIM( DataAlta_TMP ) ), 12, 8 ) + '.' + SUBSTRING( LTRIM( RTRIM( DataAlta_TMP ) ), 21, 3 ) AS time )
                                , Cod_Paciente     = Cod_Paciente_TMP
                                , Num_Internacao   = Num_Internacao_TMP
                                , Cod_Medico       = Cod_Medico_TMP
                                , Cod_Procedimento = Cod_Procedimento_TMP
                                , ValorDespesas    = CONVERT( MONEY, REPLACE( Valor_TMP, ',', '.' ) )
                            --
                            EXEC SP_MensagemErro @@ERROR, 'U', @TB_NOME, ''
                        END
                    END
                END
                --
                IF @NUM_TABELA = 5
                BEGIN
                    ALTER TABLE 
                        T_Paciente
                    ADD 
                        Nome_Convenio NVARCHAR(30)
                    --
                    EXEC SP_MensagemErro @@ERROR, 'U', @TB_NOME, 'Nome_Convenio'
                    IF @@ERROR = 0
                    BEGIN
                        -- Atualiza a Coluna [NomeConvenio] com as informações da Tabela _Convenio, coluna Descr_Convenio
                        UPDATE 
                            T_Paciente
                        SET 
                            Nome_Convenio = tc.Descr_Convenio
                        FROM 
                            T_Convenio tc
                        LEFT JOIN 
                            T_Paciente tp
                                ON tc.Cod_Convenio = LTRIM(RTRIM( tp.Cod_Convenio ) )
                        --
                        EXEC SP_MensagemErro @@ERROR, 'U', @TB_NOME, 'Cod_Convenio'
                    END                
                END
                --
                IF @NUM_TABELA = 7 -- T_Tipo_Acomodacao
                BEGIN
                    -- Atualiza tabela T_Tipo_Acomodacao com os tipos que existem na Tabela T_Internacao
                    EXEC SP_Ins_ValoresUnicos_CHAR
                        'T_Internacao'
                        , 'ti'
                        , 'Tipo_Acomodacao_TMP'
                        , 'T_Tipo_Acomodacao'
                        , 'tac'
                        , 'Descr_Acomodacao'
                    --
                    EXEC SP_MensagemErro @@ERROR, 'A', @TB_NOME, 'Tipo_Acomodacao_TMP'
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
                                ON tac.Descr_Acomodacao = LTRIM(RTRIM( ti.Tipo_Acomodacao_TMP ) )
                        --
                        EXEC SP_MensagemErro @@ERROR, 'A', @TB_NOME, 'Cod_TipoAcomodacao'
                        IF @@ERROR =  0
                            SET @RES_ACOM = 1
                    END
                END
                --
                IF @NUM_TABELA = 8 -- T_Tipo_Alta
                BEGIN
                    -- Atualiza tabela T_Tipo_Alta com os tipos que existem na Tabela T_Internacao
                    EXEC SP_Ins_ValoresUnicos_CHAR
                        'T_Internacao'
                        , 'ti'
                        , 'Tipo_Alta_TMP'
                        , 'T_Tipo_Alta'
                        , 'ta'
                        , 'Descr_Alta'
                    --
                    EXEC SP_MensagemErro @@ERROR, 'A', @TB_NOME, 'Tipo_Alta_TMP'
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
                                ON tal.Descr_Alta = LTRIM( RTRIM( ti.Tipo_Alta_TMP ) )
                        --
                        EXEC SP_MensagemErro @@ERROR, 'A', @TB_NOME, 'Cod_TipoAlta'
                        IF @@ERROR = 0
                            SET @RES_ALTA = 1
                    END
                    --
                    IF @RES_ACOM = 1 AND @RES_ALTA = 1
                    BEGIN
                        -- Atualização das colunas que contém relação com as Tabelas: T_Tipo_Acomodacao e T_Tipo_Alta
                        SET @TB_NOME = 'T_Internacao'
                        ALTER TABLE 
                            T_Internacao
                        DROP COLUMN 
                            DataAdmissao_TMP
                            , DataAlta_TMP
                            , Tipo_Alta_TMP
                            , Cod_Paciente_TMP
                            , Num_Internacao_TMP
                            , Cod_Medico_TMP
                            , Cod_Procedimento_TMP
                            , Valor_TMP
                            , Tipo_Acomodacao_TMP
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
