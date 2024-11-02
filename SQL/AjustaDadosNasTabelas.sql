USE DB_XPERIUN_HealthLab
ALTER TABLE 
	T_InternacaoTMP
ADD 
	Cod_TipoAlta INT

-- T_Tipo_AcomodacaoTMP 
-- Criar coluna Cod_TipoAcomodacao para criar relacionamento com a table T_Tipo_Acomodacao
-- ALTER TABLE 
	-- T_InternacaoTMP
-- ADD 
	-- Cod_TipoAcomodacao INT,
	-- Cod_TipoAlta INT


-- UPDATE 
	-- T_InternacaoTMP
-- SET 
	-- Cod_TipoAcomodacao = ta.Cod_TipoAcomodacao
-- FROM 
	-- T_InternacaoTMP ti
-- INNER JOIN T_Tipo_Acomodacao ta ON ti.Descr_Acomodacao = ta.Descr_Acomodacao


-- T_Tipo_Alta - (8, '[Cod_TipoAlta]	[int]IDENTITY(1, 1) NOT NULL [Descr_TipoAlta] [nvarchar](20) NOT NULL')
--INSERT INTO 
--	T_Tipo_Alta
--SELECT DISTINCT 
--	A.Tipo_Alta
--FROM
--	T_Internacao A
--WHERE
--	A.Tipo_Alta <> ''

-- T_Tipo_Acomodacao - (9, '[Cod_TpAcomodacao]	[int]IDENTITY(1, 1) NOT NULL, [Descr_Acomodacao] [nvarchar](50) NOT NULL')
-- INSERT INTO 
-- 	T_Tipo_Acomodacao 
--SELECT DISTINCT 
-- 	LTRIM(RTRIM(A.Tp_Acomodacao))
--FROM
-- 	T_Internacao A
--WHERE
--	A.Tp_Acomodacao <> '' 

--select * from T_Tipo_Alta
--select * from T_Tipo_Acomodacao 

-- OK - 31/10/2024 - 21:21

--EXEC sp_rename 'T_InternacaoTMP.Tp_Acomodacao', 'Descr_Internacao', 'COLUMN';
--EXEC sp_rename 'T_Tipo_Acomodacao.Tipo_Internacao', 'Cod_TipoAcomodacao', 'COLUMN';

-- OK - 01/11/2024 - 10:56

--(3, 'T_Internacao_TMP', 'tab_internacoes'),
--(3, '[DataAdmissao_TMP] [nvarchar](23) NOT NULL, [DataAlta_TMP] [nvarchar](23),
--	    [Tipo_Alta] [nvarchar](15),                                          [Cod_Paciente] [int] NOT NULL,
--	    [Num_Internacao] [int] NOT NULL,                          [Cod_Medico] [int] NOT NULL, 
--	    [Cod_Procedimento] [int] NOT NULL,                      [Valor_TMP] [nvarchar] (20), 
--	    [Tp_Acomodacao] [nvarchar](20))

--	(7, 'T_Internacao', NULL),
-- (7, '[Cod_Internacao]	[int]IDENTITY(1,1) NOT NULL, [DataAdmissao] [date] NOT NULL, 
--	      [HoraAdmissao] [time] NOT NULL,                          [DataAlta] [date],
--	      [HoraAlta] [time],                                                        [Tipo_Alta] [nvarchar](15), 
--	      [Cod_Paciente] [int] NOT NULL,                              [Num_Internacao] [int] NOT NULL,
--	      [Cod_Medico] [int] NOT NULL,                                [Cod_Procedimento] [int] NOT NULL,
--	      [Cod_Acomodacao] [int] NOT NULL,                     [ValorDespesas] [money])

-- Observacoes Colunas:
	-- Tipo_alta - Não possui dados vazios
	-- Cod_Paciente - Não possui dados vazios
	-- Num_Internacao - Não possui dados vazios
	-- Cod_Medico
	-- Cod_Procedimento

--INSERT INTO 
--	T_Internacao (
--		DataAdmissao, HoraAdmissao,
--		DataAlta,           	HoraAlta,
--		Cod_Paciente,  Num_Internacao,
--		Cod_Medico,    Cod_Procedimento,
--		ValorDespesas
--	)
--SELECT 
--	CAST( SUBSTRING(  LTRIM (RTRIM( A.DataAdmissao_TMP ) ), 1, 10 ) AS date ),
--	CAST( SUBSTRING( LTRIM( RTRIM( A.DataAdmissao_TMP ) ), 12, 8 )  + '.' + SUBSTRING( LTRIM( RTRIM( A.DataAdmissao_TMP ) ), 21, 3 ) AS time ),
--	CAST( SUBSTRING( LTRIM( RTRIM( A.DataAlta_TMP ) ), 1, 10 ) AS date ),
--	CAST( SUBSTRING( LTRIM( RTRIM( A.DataAlta_TMP ) ), 12, 8 ) +  '.' + SUBSTRING( LTRIM( RTRIM( A.DataAlta_TMP ) ), 21, 3 ) AS time ),
--	A.Cod_Paciente,
--	A.Num_Internacao,
--	A.Cod_Medico,
--	A.Cod_Procedimento,
--	CONVERT( MONEY, REPLACE( Valor_TMP, ',', '.' ) )
--FROM 
--	T_Internacao_TMP ti_tmp
--WHERE
--	DataAdmissao_TMP <> ''

--SELECT *FROM T_Internacao_tmp


-- Data_Admissao = CAST( SUBSTRING(  LTRIM (RTRIM(  Int_TMP.DataAdmissao_TMP ) ), 1, 10 ) AS date ) FROM T_Internacao_TMP Int_TMP
--	Hora_Admissao = CAST( SUBSTRING( LTRIM( RTRIM( DataAdmissao_TMP ) ), 12, 8 )  + '.' + SUBSTRING( LTRIM( RTRIM( DataAdmissao_TMP ) ), 21, 3 ) AS time ),
--	Data_Alta            = CAST( SUBSTRING( LTRIM( RTRIM( DataAlta_TMP ) ), 1, 10 )            AS date ),
--	Hora_Alta           = CAST( SUBSTRING( LTRIM( RTRIM( DataAlta_TMP ) ), 12, 8 ) +  '.' + SUBSTRING( LTRIM( RTRIM( DataAlta_TMP ) ), 21, 3 ) AS time ),
--	ValorDespesa     = CONVERT( MONEY, REPLACE( Valor_TMP, ',', '.' ) )

--select DataAdmissao from T_Internacao