USE [DB_Hospital]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_Ins_ValoresUnicos_CHAR]
    @Tb_Origem         NVARCHAR(30)
    , @Alias_Tb_Origem NVARCHAR(5)
    , @Coluna_Origem   NVARCHAR(50)
    , @Tb_Destino      NVARCHAR(30)
    , @Alias_Tb_Dest   NVARCHAR(5)
    , @Coluna_Destino  NVARCHAR(50)
AS
BEGIN
    DECLARE 
        @CMD_SQL NVARCHAR(MAX)

    -- Verifica se a tabela de destino já possui dados
    SET @CMD_SQL = N'
        IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@Tb_Destino) + N') 
        BEGIN
            -- Se T_Tipo_Alta já possui dados, insere apenas os novos valores
            INSERT INTO ' 
                + QUOTENAME(@Tb_Destino) + N' (' + QUOTENAME(@Coluna_Destino) + N') 
            SELECT DISTINCT ' 
                + QUOTENAME(@Alias_Tb_Origem) + N'.' + QUOTENAME(@Coluna_Origem) + N' 
            FROM ' 
                + QUOTENAME(@Tb_Origem) + N' ' + QUOTENAME(@Alias_Tb_Origem) + N'
            WHERE NOT EXISTS 
                ( 
                    SELECT 1 
                    FROM ' 
                        + QUOTENAME(@Tb_Destino) + N' ' + QUOTENAME(@Alias_Tb_Dest) + N'
                    WHERE ' 
                        + QUOTENAME(@Alias_Tb_Dest)   + N'.' + QUOTENAME(@Coluna_Destino) + N' = ' 
                        + QUOTENAME(@Alias_Tb_Origem) + N'.' + QUOTENAME(@Coluna_Origem) + N'
                ) 
            AND NULLIF(' + QUOTENAME(@Alias_Tb_Origem) + N'.' + QUOTENAME(@Coluna_Origem) + N', '''') IS NOT NULL
        END
        ELSE 
        BEGIN
            -- Se T_Tipo_Alta está vazia, insere todos os valores        
            INSERT INTO ' 
                + QUOTENAME(@Tb_Destino) + N' (' + QUOTENAME(@Coluna_Destino) + N') 
            SELECT DISTINCT ' 
                + QUOTENAME(@Alias_Tb_Origem) + N'.' + QUOTENAME(@Coluna_Origem) + N' 
            FROM ' 
                + QUOTENAME(@Tb_Origem) + N' ' + QUOTENAME(@Alias_Tb_Origem) + N'
            WHERE 
                NULLIF(' + QUOTENAME(@Alias_Tb_Origem) + N'.' + QUOTENAME(@Coluna_Origem) + N', '''') IS NOT NULL
        END'
    EXEC sp_executesql @CMD_SQL
END
GO
