SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_Cria_DB_XPERIUN_HealthLab]
	-- Configuração do nome do Banco de Dados, Diretórios e Extensão dos Arquivos a serem importados
	@ExtArqs		NVARCHAR(4)    = '.CSV',																														-- Extensão dos arquivos a serem importados
	@Database	NVARCHAR(30) = 'DB_XPERIUN_HealthLab',																					-- Nome do Banco de Dados
	@PastaDB		NVARCHAR(80) = 'D:\SGBD\MS-SQL-Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\',		-- Pasta onde será criado o Banco de Dados
	@PastaArqs	NVARCHAR(80) = 'D:\Users\rtoni\OneDrive\Git-Dados\Projetos\XPERIUN-HealthLab\'		-- Pasta onde estão os arquivos a serem importados
AS
BEGIN
	-- Declaração das variáveis
	DECLARE
		@DB_TB_NOME	NVARCHAR(MAX),	-- Concatena @Database + '.dbo' + @TB_NOME
		@CMD_SQL			NVARCHAR(MAX),	-- Variável que contém comando a ser executado
		@QTDTABELAS		INT,								-- Quantidade Total de Tabelas a serem criadas
		@NUM_TABELA	INT,								-- Numero da Tabela
		@TB_NOME			NVARCHAR(30),		-- Nome da Tabela a ser criada 
		@NOME_ARQ		NVARCHAR(30),		-- Nome do arquivo a ser importado
		@NOME_COL		NVARCHAR(MAX) 	-- Definição dos Campos na Tabela Virtual @LSTCAMPOS 

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
			EXEC sp_executesql @CMD_SQL
			IF @@ERROR <> 0
				BEGIN
					PRINT 'NÃO foi possível criar o Banco de dados: ' + @Database + '. Favor verificar com o Responsável.'
					RETURN
				END
			PRINT 'Banco de dados: ' + @Database + ' criado com sucesso!'
		END
		SET @CMD_SQL  = N'USE ' + QUOTENAME(@Database)
		EXECUTE(@CMD_SQL)
		-- Criação da Tabela Virtual com Relação de Tabelas
		DECLARE 
			@LST_TABELAS 
		TABLE(
				ID_Tabela INT, 
				NomeTabela VARCHAR(60), 
				NomeArqImportar VARCHAR(100)
		)
		INSERT INTO 
			@LST_TABELAS 
		VALUES
			(1, 'T_Classe_Procedimento', 'tab_classe_procedimento'),
			(2, 'T_Convenio',  'tab_convenio'),
			(3, 'T_Internacao', 'tab_internacoes'),
			(4, 'T_Medico', 'tab_medicos'),
			(5, 'T_Paciente', 'tab_paciente'),
			(6, 'T_Procedimento', 'tab_procedimento')

		IF @@ERROR <> 0
			BEGIN
				PRINT 'NÃO foi possível criar Tabela Virtual: Relação das Tabelas. Favor verificar com o Responsável.'
				RETURN
			END
		PRINT 'Tabela Virtual: Relação das Tabelas criada com sucesso!'
		-- Criação da Tabela Virtual com Relação de Campos
		DECLARE 
			@LST_CAMPOS 
		TABLE( 
				ID_TabelaCampo INT, 
				Nome_DefCampo NVARCHAR(MAX) 
		)
		INSERT INTO 
			@LST_CAMPOS 
		VALUES
			-- T_Classe_Procedimento
			(1, '[Cod_ClasseProc]	[int] IDENTITY(1,1) NOT NULL,' + 
				'[Descr_ClasseProc]	[nvarchar](15) NOT NULL'
			),
			-- T_Convenio
			(2, '[Cod_Convenio]	  [int] IDENTITY(1, 1) NOT NULL, ' +
				'[Descr_Convenio] [nvarchar](30) NOT NULL'
			),
			-- T_Internacao
			(3, '[Data_Admissao_TMP] [nvarchar](23) NOT NULL, ' +
				'[Data_Alta_TMP]	 [nvarchar](23),' +
				'[Tipo_Alta]		 [nvarchar](15), ' +
				'[Cod_Paciente]		 [int] NOT NULL, ' +
				'[Num_Internacao]	 [int] NOT NULL, ' +
				'[Cod_Medico]		 [int] NOT NULL, ' +
				'[Cod_Procedimento]	 [int] NOT NULL, ' + 
				'[Valor_TMP]		 [nvarchar] (20), ' +
				'[Tp_Acomodacao]	 [nvarchar](20)'
			),
			-- T_Medico
			(4, '[Cod_Medico]	[int]IDENTITY(1, 1) NOT NULL, ' +
				'[Nome_Medico] 	[nvarchar](40) NOT NULL '
			),
			-- T_Paciente
			(5, '[Cod_Paciente]	 [int]IDENTITY(1, 1) NOT NULL, ' +
				'[Nome_Paciente] [nvarchar](40), ' +
				'[Sexo_Paciente] [varchar](1), ' +
				'[Dt_Nascimento] [nvarchar](23), ' +
				'[Cod_Convenio]	 [int] NOT NULL'
			),
			-- T_Procedimento - cod_procedimento,procedimento,cod_classe
			(6, '[Cod_Proc]	  [int]IDENTITY(1, 1) NOT NULL, ' +
				'[Descr_Proc] [nvarchar](50), ' +
				'[Cod_Classe] [int]' 
			)
		IF @@ERROR <>  0
			BEGIN
				PRINT 'NÃO foi possível criar Tabela Virtual: Relação dos Campos das Tabelas. Favor verificar com o Responsável.'
				RETURN
			END
		PRINT 'Tabela Virtual : Relação dos Campos das Tabelas criada com sucesso!'
		-- Loop de Criação de Tabelas
		SET @NUM_TABELA = 1
		SELECT @QTDTABELAS = COUNT(*) FROM @LST_TABELAS

		WHILE @NUM_TABELA <= @QTDTABELAS 
			BEGIN
				SELECT TOP(1) @TB_NOME = NomeTabela, @NOME_ARQ = NomeArqImportar FROM @LST_TABELAS WHERE ID_Tabela = @NUM_TABELA
				SELECT TOP(1) @NOME_COL = Nome_DefCampo FROM @LST_CAMPOS WHERE ID_TabelaCampo = @NUM_TABELA

				SET @DB_TB_NOME =  @Database + '.dbo.'  + @TB_NOME
				PRINT @DB_TB_NOME
				-- Verifica se a tabela existe. Se não existir Cria
				IF EXISTS (SELECT 1 FROM sys.tables WHERE name = @TB_NOME)
					PRINT 'A tabela: [' + @DB_TB_NOME + '] JÁ EXISTE!'
				ELSE
					BEGIN
						PRINT 'A tabela: [' + @DB_TB_NOME + '] não existe!'

						SET @CMD_SQL = N'CREATE TABLE ' + @DB_TB_NOME  + ' (' + @NOME_COL + ')'
						PRINT @CMD_SQL

						EXEC sp_executesql @CMD_SQL
						IF @@ERROR <> 0
							BEGIN
								PRINT 'NÃO foi possível criar Tabela: ' + @TB_NOME + '. Favor verificar com o Responsável.'
							END
						ELSE
							PRINT 'Tabela: ' + @TB_NOME + ' criada com sucesso!'
					END
				-- Importa os arquivos CSV
				SET @CMD_SQL = 
					'BULK INSERT '  + 
						@TB_NOME +
					' FROM ' + 
						'"' + @PastaArqs + @NOME_ARQ + @ExtArqs  + '"' +
					' WITH (
						FIELDTERMINATOR = '','',
						ROWTERMINATOR = ''\n'',
						FIRSTROW = 2,
						CODEPAGE = ''65001'',
						FORMAT = ''CSV''
					)'
				PRINT @CMD_SQL
				EXEC sp_executesql @CMD_SQL
				SET @NUM_TABELA += 1
			END
END
GO
