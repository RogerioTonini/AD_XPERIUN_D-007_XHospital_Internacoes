SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_02_CargaDados_DB_XPERIUN_HealthLab]
	@ExtArqs   NVARCHAR(4)  = '.CSV',  -- Extensão dos arquivos a serem importados
	@PastaArqs NVARCHAR(100) = 'D:\Git-Projetos\Projetos_Estudos\AD_XPERIUN_D-007_XHospital_Internacoes\Dados\'  -- Pasta onde estão os arquivos a serem importados
AS
BEGIN
	-- Declaração das variáveis
	DECLARE
		@DB_TB_NOME NVARCHAR(MAX), -- Concatena @Database + '.dbo' + @TB_NOME
		@CMD_SQL NVARCHAR(MAX),    -- Variável que contém comando a ser executado
		@QTDTABELAS INT,           -- Quantidade Total de Tabelas a serem criadas
		@NUM_TABELA INT = 1,       -- Numero da Tabela
		@TB_NOME NVARCHAR(30),     -- Nome da Tabela a ser criada 
		@NOME_ARQ NVARCHAR(30),    -- Nome do arquivo a ser importado
		@NOME_COL NVARCHAR(MAX),   -- Definição dos Campos na Tabela Virtual @LSTCAMPOS 
		@RES_ALTA INT = 1,         -- Resultado da operação de atualização das tabelas: T_Acomodacao e T_Internacao
		@RES_ACOM INT = 1,         -- Resultado da operação de atualização das tabelas: T_Alta e T_Internacao
		@RESP VARCHAR,
		@ExisteDir BIT = dbo.fxDiretorioExiste(@PastaArqs)

	SELECT @RESP = SUBSTRING(@PastaArqs, LEN(@PastaArqs), 1)
	IF @RESP <> '\'
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
		(2, 'T_Convenio', 'tab_convenio'),
		(3, 'T_Internacao', 'tab_internacoes'),
		(4, 'T_Medico', 'tab_medicos'),
		(5, 'T_Paciente', 'tab_paciente'),
		(6, 'T_Procedimento', 'tab_procedimento'),
		(7, 'T_Tipo_Acomodacao', NULL), 
		(8, 'T_Tipo_Alta', NULL)
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
		(1, '[Cod_ClasseProc] [int] IDENTITY(1,1) NOT NULL,' + 
			'[Descr_ClasseProc] [nvarchar](15)'
		),
		-- T_Convenio
		(2, '[Cod_Convenio] [int] IDENTITY(1, 1) NOT NULL, ' +
			'[Descr_Convenio] [nvarchar](30)'
		),
		-- T_Internacao
		(3, '[DataAdmissao_TMP] [nvarchar](23) NOT NULL, ' +
			'[DataAlta_TMP] [nvarchar](23),' +
			'[Tipo_Alta_TMP] [nvarchar](15), ' +
			'[Cod_Paciente_TMP] [int], ' +
			'[Num_Internacao_TMP] [int], ' +
			'[Cod_Medico_TMP] [int], ' +
			'[Cod_Procedimento_TMP] [int], ' + 
			'[Valor_TMP] [nvarchar] (20), ' +
			'[Tipo_Acomodacao_TMP] [nvarchar](20) '
		),
		-- T_Medico
		(4, '[Cod_Medico] [int]IDENTITY(1,1) NOT NULL, ' +
			'[Nome_Medico] [nvarchar](40)'
		),
		-- T_Paciente
		(5, '[Cod_Paciente] [int]IDENTITY(1,1) NOT NULL, ' +
			'[Nome_Paciente] [nvarchar](40), ' +
			'[Sexo_Paciente] [varchar](1), ' +
			'[Dt_Nascimento] [nvarchar](23), ' +
			'[Cod_Convenio] [int]'
		),
		-- T_Procedimento - cod_procedimento, procedimento,cod_classe
		(6, '[Cod_Proc]	[int]IDENTITY(1,1) NOT NULL, ' +
			'[Descr_Proc] [nvarchar](50), ' +
			'[Cod_Classe] [int]' 
		), 
		-- T_Tipo_Acomodacao - 
		(7, '[Cod_TipoAcomodacao]	[int]IDENTITY(1, 1) NOT NULL, ' +
			'[Descr_Acomodacao] [nvarchar](50) NOT NULL'
		),
		-- T_Tipo_Alta - 
		(8, '[Cod_TipoAlta]	[int]IDENTITY(1, 1) NOT NULL, ' +
			'[Descr_TipoAlta] [nvarchar](20) NOT NULL'
		)
	IF @@ERROR <>  0
		BEGIN
			PRINT 'NÃO foi possível criar Tabela Virtual: Relação dos Campos das Tabelas. Favor verificar com o Responsável.'
			RETURN
		END
	PRINT 'Tabela Virtual : Relação dos Campos das Tabelas criada com sucesso!'

	-- Loop de Criação de Tabelas
	SELECT @QTDTABELAS = COUNT(*) FROM @LST_TABELAS

	WHILE @NUM_TABELA <= @QTDTABELAS 
	BEGIN
		SELECT TOP(1) 
			@TB_NOME = NomeTabela, 
			@NOME_ARQ = NomeArqImportar 
		FROM 
			@LST_TABELAS 
		WHERE 
			ID_Tabela = @NUM_TABELA

		SELECT TOP(1) 
			@NOME_COL = Nome_DefCampo 
		FROM 
			@LST_CAMPOS 
		WHERE 
			ID_TabelaCampo = @NUM_TABELA

		-- Verifica se a tabela existe. Se não existir Cria
		IF EXISTS(SELECT 1 FROM sys.tables WHERE name = @TB_NOME)
			PRINT 'A tabela: [' + @TB_NOME + '] JÁ EXISTE!'
		ELSE
		BEGIN
			PRINT 'A tabela: [' + @TB_NOME + '] não existe!'

			SET @CMD_SQL = N'CREATE TABLE ' + @TB_NOME  + ' (' + @NOME_COL + ')'
			EXEC sp_executesql @CMD_SQL
			IF @@ERROR <> 0
				PRINT 'NÃO foi possível criar Tabela: ' + @TB_NOME + '. Favor verificar com o Responsável.'
			ELSE
			BEGIN
				PRINT 'Tabela: ' + @TB_NOME + ' criada com sucesso!'
 				-- Importa os arquivos CSV
				IF @NUM_TABELA < 7
				BEGIN
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
					EXEC sp_executesql @CMD_SQL
					IF @@ERROR <> 0
						PRINT 'NÃO foi possível realizar UPLOAD na Tabela: ' + @TB_NOME + '. Verificar!'
					ELSE
						PRINT 'UPLOAD na Tabela: ' + @TB_NOME + ' realizada com sucesso!'
				END
				-- Altera estrutura da(s) Tabelas / Insere dados na(s) Tabelas
				IF @NUM_TABELA = 3 -- T_Internacao
				BEGIN
					ALTER TABLE 
							T_Internacao
					ADD 
						ID_Internacao INT IDENTITY(1,1) NOT NULL,
						Num_Internacao INT, 
						DataAdmissao DATE, 
						HoraAdmissao TIME, 
						DataAlta DATE,
						HoraAlta TIME,
						Cod_Paciente INT,
						Cod_Medico INT,
						Cod_Procedimento INT,
						Cod_TipoAcomodacao INT,
						Cod_TipoAlta INT,
						ValorDespesas MONEY
					IF @@ERROR <> 0
						PRINT 'NÃO foi possível realizar as alterações na estrutura da Tabela: ' + @TB_NOME + '. Verificar!!!'
					ELSE
					BEGIN
						PRINT 'Alterações realizadas com SUCESSO na Tabela: ' + @TB_NOME + ' !!!'
						-- Atualiza a Coluna Tipo_Alta_TMP cuja as informações de DataAdmissao_TMP <> '' e NULLIF(Tipo_Alta_TMP, '') IS NULL com a informação [Em Uso]
						UPDATE
							T_Internacao
						SET
							Tipo_Alta_TMP = 'Em Uso'
						WHERE
							NULLIF( DataAdmissao_TMP, '' ) IS NOT NULL AND 	
							NULLIF( DataAlta_TMP, '' ) IS NULL
						IF @@ERROR <> 0
							PRINT 'NÃO foi possível atualizar a coluna [Tipo_Alta_TMP] com a informação [Em Uso] na Tabela: ' + @TB_NOME + '. Verificar!!!'
						ELSE
							PRINT 'Alterações realizadas com SUCESSO na coluna [Tipo_Alta_TMP] com a informação [Em Uso] na Tabela: ' + @TB_NOME + ' !!!'
						-- Atualiza a Coluna Tipo_Alta_TMP cuja as informações de DataAdmissao_TMP e DataAlta_TMP NÃO estão vazias com a informação [Não Registrado]
						UPDATE
							T_Internacao
						SET
							Tipo_Alta_TMP = 'Não Registrado'
						WHERE
                            NULLIF( DataAdmissao_TMP, '' ) IS NOT NULL AND
                            NULLIF( DataAlta_TMP, '' ) IS NOT NULL AND
                            NULLIF( Tipo_Alta_TMP, '' ) IS NULL 
						IF @@ERROR <> 0
							PRINT 'NÃO foi possível atualizar a coluna [Tipo_Alta_TMP] com a informação [Não Registrado] na Tabela: ' + @TB_NOME + '. Verificar!!!'
						ELSE
							PRINT 'Alterações realizadas com SUCESSO na coluna [Tipo_Alta_TMP] com a informação [Não Registrado] na Tabela: ' + @TB_NOME + ' !!!'
						-- Atualiza os demais Colunas definitivas com os dados das Colunas Temporárias, tratando os dados quando necessário
						UPDATE 
							T_Internacao
						SET
							DataAdmissao = CAST( SUBSTRING( LTRIM( RTRIM( DataAdmissao_TMP ) ), 1, 10 ) AS date ),
							HoraAdmissao = CAST( SUBSTRING( LTRIM( RTRIM( DataAdmissao_TMP ) ), 12, 8 ) + '.' + SUBSTRING( LTRIM( RTRIM( DataAdmissao_TMP ) ), 21, 3 ) AS time ),
							DataAlta = CAST( SUBSTRING( LTRIM( RTRIM( DataAlta_TMP ) ), 1, 10 ) AS date ),
							HoraAlta = CAST( SUBSTRING( LTRIM( RTRIM( DataAlta_TMP ) ), 12, 8 ) + '.' + SUBSTRING( LTRIM( RTRIM( DataAlta_TMP ) ), 21, 3 ) AS time ),
							Cod_Paciente = Cod_Paciente_TMP,
							Num_Internacao = Num_Internacao_TMP,
							Cod_Medico = Cod_Medico_TMP,
							Cod_Procedimento = Cod_Procedimento_TMP,
							ValorDespesas = CONVERT( MONEY, REPLACE( Valor_TMP, ',', '.' ) )
						IF @@ERROR <> 0
							PRINT 'NÃO foi possível realizar as atualizações dos dados das colunas temporárias para as definitivas da Tabela: ' + @TB_NOME + '. Verificar!!!'
						ELSE
							PRINT 'Atualizações dos dados das colunas temporárias para as definitivas realizadas com SUCESSO na Tabela: ' + @TB_NOME + ' !!!'
					END
				END
				IF @NUM_TABELA = 7  -- T_Tipo_Acomodacao
				BEGIN
					INSERT INTO 
						T_Tipo_Acomodacao
					SELECT DISTINCT 
						LTRIM( RTRIM( ti.Tipo_Acomodacao_TMP ) )
					FROM
						T_Internacao ti
					WHERE
						NULLIF( ti.Tipo_Acomodacao_TMP, '' ) IS NOT NULL
					IF @@ERROR <> 0
						PRINT 'NÃO foi possível realizar as alterações na estrutura da Tabela: ' + @TB_NOME + '. Verificar!!!'
					ELSE
					BEGIN
						PRINT 'Alterações realizadas com SUCESSO na Tabela: ' + @TB_NOME + ' !!!'
						UPDATE  -- Atualizacao da Tabela T_Internacao, coluna Cod_TipoAcomodação
							T_Internacao
						SET 
							Cod_TipoAcomodacao = tac.Cod_TipoAcomodacao
						FROM 
							T_Tipo_Acomodacao tac
						INNER JOIN T_Internacao ti ON 
							tac.Descr_Acomodacao = LTRIM( RTRIM( ti.Tipo_Acomodacao_TMP ) )								
						IF @@ERROR <> 0
							PRINT 'NÃO foi possível realizar a atualização da Tabela: [' + @TB_NOME + '], coluna [Cod_TipoAcomodacao]. Verificar!!!'
						ELSE
							PRINT 'Atualização da Tabela: [' + @TB_NOME + '], coluna [Cod_TipoAcomodacao] realizadas com SUCESSO!!!'
						SET @RES_ACOM = 1
					END
				END
				IF @NUM_TABELA = 8  -- T_Tipo_Alta
				BEGIN
					-- Inserindo Tipos de Alta NÃO contemplado na Tabela T_Internacao
					INSERT INTO 
						T_Tipo_Alta ( Descr_TipoAlta )
					VALUES
							( 'Em Uso' ), 
                            ( 'Não Registrado' )
					-- Inserindo Tipos de Alta que existem na Tabela T_Internacao
					INSERT INTO 
						T_Tipo_Alta
					SELECT DISTINCT 
						ti.Tipo_Alta_TMP
					FROM
						T_Internacao ti
					WHERE
						NULLIF( ti.Tipo_Alta_TMP, '' ) IS NOT NULL
					IF @@ERROR <> 0
						PRINT 'NÃO foi possível realizar as alterações na estrutura da Tabela: ' + @TB_NOME + '. Verificar!!!'
					ELSE
					BEGIN
						PRINT 'Alterações realizadas com SUCESSO na Tabela: ' + @TB_NOME + ' !!!'
                        -- Atualizacao da Tabela T_Internacao, coluna Cod_TipoAcomodação
						UPDATE
							T_Internacao
						SET 
							Cod_TipoAlta = tal.Cod_TipoAlta
						FROM 
							T_Tipo_Alta tal
						INNER JOIN T_Internacao ti ON 
							tal.Descr_TipoAlta = LTRIM( RTRIM( ti.Tipo_Alta_TMP ) )
						IF @@ERROR <> 0
							PRINT 'NÃO foi possível realizar a atualização da Tabela: [' + @TB_NOME + '], coluna [Cod_TipoAlta]. Verificar!!!'
						ELSE
						BEGIN
							PRINT 'Atualização da Tabela: [' + @TB_NOME + '], coluna [Cod_TipoAlta] realizadas com SUCESSO!!!'
							SET @RES_ALTA = 1
						END
					END
					-- Atualização das colunas que contém relação com as Tabelas: T_Tipo_Acomodacao e T_Tipo_Alta
					IF @RES_ACOM = 1 AND @RES_ALTA = 1
					BEGIN
						ALTER TABLE 
							T_Internacao
						DROP COLUMN
							DataAdmissao_TMP,
							DataAlta_TMP,
							Tipo_Alta_TMP,
							Cod_Paciente_TMP,
							Num_Internacao_TMP,
							Cod_Medico_TMP,
							Cod_Procedimento_TMP,
							Valor_TMP,
							Tipo_Acomodacao_TMP
					END
				END
			END
		END
		SET @NUM_TABELA += 1
	END
END
GO
