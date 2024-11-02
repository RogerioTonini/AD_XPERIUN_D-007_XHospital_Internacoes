-- ALTER TABLE 
    -- T_Internacao
-- ADD 
    -- Data_Admissao date,
    -- Hora_Admissao time,
    -- Data_Alta     date,
    -- Hora_Alta     time,
    -- ValorDespesa  money

-- UPDATE 
    -- T_Internacao
-- SET 
    -- Data_Admissao = CAST( SUBSTRING( LTRIM(RTRIM(Data_Admissao_TMP)), 1, 10) AS date),
    -- Hora_Admissao = CAST( SUBSTRING( LTRIM(RTRIM(Data_Admissao_TMP)), 12, 8) + '.' + SUBSTRING(LTRIM(RTRIM(DataAdmissao_TMP)), 21, 3)AS time)
    -- Data_Alta     = CAST( SUBSTRING( LTRIM(RTRIM(Data_Alta_TMP)), 1, 10) AS date),
    -- Hora_Alta     = CAST( SUBSTRING( LTRIM(RTRIM(Data_Alta_TMP)), 12, 8) + '.' + SUBSTRING(LTRIM(RTRIM(DataAlta_TMP)), 21, 3)AS time)
    -- ValorDespesa  = CAST( SUBSTRING( LTRIM(RTRIM(Valor_TMP)), 1, CHARINDEX( ',', LTRIM(RTRIM(Valor_TMP)) ) - 1 ) + '.' + 
    --                      SUBSTRING( LTRIM(RTRIM(Valor_TMP)), CHARINDEX(',', LTRIM(RTRIM(Valor_TMP))) + 1, LEN(LTRIM(RTRIM(Valor_TMP))) - CHARINDEX(',', LTRIM(RTRIM(Valor_TMP))) ) AS MONEY)

-- **************************************************************************************
     -- LEN(LTRIM(RTRIM(Valor_TMP)))
     -- Descobrir a quantidade total de caracteres
     -- Descobrir a posição da vírgula (sentido esquerda para a direita)
     -- Substituir a vírgula pelo ponto
     -- Converter nvarchar para money

-- DECLARE @document VARCHAR(64)
-- SELECT @document = ' 1234,67 '
-- SELECT
    -- SUBSTRING( LTRIM(RTRIM(@document)), 1, CHARINDEX( ',', LTRIM(RTRIM(@document)) ) - 1 ) + '.' + 
    -- SUBSTRING( LTRIM(RTRIM(@document)), CHARINDEX(',', LTRIM(RTRIM(@document))) + 1, LEN(LTRIM(RTRIM(@document))) - CHARINDEX(',', LTRIM(RTRIM(@document))) )
-- **************************************************************************************

-- Comando para RENOMEAR COLUNAS
-- EXEC sp_rename 'T_Internacao.Data_Admissao', 'DataAdmissao_TMP', 'COLUMN'
-- EXEC sp_rename 'T_Internacao.Data_Alta',     'DataAlta_TMP',     'COLUMN'










