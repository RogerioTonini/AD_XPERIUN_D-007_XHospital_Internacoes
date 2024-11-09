USE DB_Hospital

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_M_Idade_Paciente_Admissao]
AS
BEGIN
    SELECT 
        tp.Nome_Paciente
        , tp.Data_Nascimento
        , ti.DataAdmissao
        -- Acha a diferença em Qtde de Anos da Data Inicial: [tp].[Data_Nascimento] e da Data Final: [ti].[DataAdmissao]
        , dbo.fxCalc_Periodo( 'Y', tp.Data_Nascimento, ti.DataAdmissao ) AS Idade_Anos
        -- Acha a diferença em Qtde de Dias da Data Inicial: [tp].[Data_Nascimento] e da Data Final: [ti].[DataAdmissao]
        , dbo.fxCalc_Periodo
            ( 'D', DATEADD( YEAR, dbo.fxCalc_Periodo( 'Y', tp.Data_Nascimento, ti.DataAdmissao ), tp.Data_Nascimento ), ti.DataAdmissao ) AS Idade_Dias
        , tf.Descr_Faixa
    FROM 
        T_Internacao ti
    LEFT JOIN 
        T_Paciente tp ON ti.Cod_Paciente = tp.Cod_Paciente
    LEFT JOIN
        T_Faixa_Idade tf ON 
            dbo.fxCalc_Periodo( 'Y', tp.Data_Nascimento, ti.DataAdmissao ) >= tf.IdadeInicio 
        AND dbo.fxCalc_Periodo( 'Y', tp.Data_Nascimento, ti.DataAdmissao ) <= tf.IdadeFim
END