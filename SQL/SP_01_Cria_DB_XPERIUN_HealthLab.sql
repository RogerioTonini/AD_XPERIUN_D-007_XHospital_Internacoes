SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_01_Cria_DB_XPERIUN_HealthLab]
	-- Configuração do nome do Banco de Dados, Diretórios e Extensão dos Arquivos a serem importados
	@Database NVARCHAR(30) = 'DB_XPERIUN_HealthLab', -- Nome do Banco de Dados
	@PastaDB NVARCHAR(80) = 'D:\SGBD\MS-SQL-Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\'	-- Pasta onde será criado o Banco de Dados
AS
BEGIN
	-- Declaração das variáveis
	DECLARE
		@CMD_SQL NVARCHAR(MAX)	-- Variável que contém comando a ser executado

	-- Criação do Banco de Dados
	IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = @Database)
		PRINT 'Banco de dados: ' + @Database + ' já EXISTE!'
	ELSE
		BEGIN
        SET @CMD_SQL = N'
            CREATE DATABASE ' + @Database + ' ON (
                NAME = ''' + @Database + '_Data'',
                FILENAME = ''' + @PastaDB + @Database + '.mdf'',
                SIZE = 5MB,
                MAXSIZE = 25MB,
                FILEGROWTH = 15%
            )
            LOG ON (
                NAME = ''' + @Database + '_Log'',
                FILENAME = ''' + @PastaDB + @Database + '_log.ldf'',
                SIZE = 5MB,
                MAXSIZE = 25MB,
                FILEGROWTH = 5MB
            )'
        SET @CMD_SQL += 'ALTER DATABASE ' + @Database + ' SET RECOVERY SIMPLE'
        EXEC sp_executesql @CMD_SQL
        IF @@ERROR <> 0
        BEGIN
            PRINT 'NÃO foi possível criar o Banco de dados: ' + @Database + '. Favor verificar com o Responsável.'
            RETURN
        END
        PRINT 'Banco de dados: ' + @Database + ' criado com sucesso!'
		END
END
GO
