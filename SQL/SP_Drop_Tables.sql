SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_Drop_Tables]
AS
BEGIN
    DECLARE 
         @CMD_SQL      NVARCHAR(MAX)
        , @TB_NOME     NVARCHAR(30)  -- Nome da Tabela a ser criada
        , @NUM_TABELA  INT = 1
        , @QTD_TABELAS INT = 1

    DECLARE 
        @LST_TABELAS TABLE(
            ID_Tabela INT
            , NomeTabela VARCHAR(60)
        )

    INSERT INTO 
        @LST_TABELAS
    VALUES
        (1, 'T_Classe_Procedimento')
        , (2, 'T_Convenio')
        , (3, 'T_Faixa_Idade')
        , (4, 'T_Internacao')
        , (5, 'T_Medico')
        , (6, 'T_Paciente')
        , (7, 'T_Procedimento')
        , (8, 'T_Tipo_Acomodacao')
        , (9, 'T_Tipo_Alta')
    -- Loop de Criação de Tabelas
    SELECT 
        @QTD_TABELAS = COUNT(*)
    FROM 
        @LST_TABELAS

    WHILE @NUM_TABELA <= @QTD_TABELAS
    BEGIN
        SELECT TOP (1)
            @TB_NOME = NomeTabela
        FROM 
            @LST_TABELAS
        WHERE 
            ID_Tabela = @NUM_TABELA

        SET @CMD_SQL = N'
            IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[' + @TB_NOME + N']'') AND type in (N''U'')) 
                DROP TABLE ' + N'[dbo].[' + @TB_NOME + '] '
        EXEC sp_executesql @CMD_SQL
        SET @NUM_TABELA += 1
    END
END
GO
