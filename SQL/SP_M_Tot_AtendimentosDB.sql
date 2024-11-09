/************************************************************************************************
Criado por: Rogerio Tonini
Data......: 07/11/2024
Objetivo..: Totalizar o total de atendimentos, Tabela: [T_Internacao], agrupados por:
Paciente, DataAdmissao, Hora Admissao, Data Alta, Hora Alta,
Código do Procedimento, Código do Tipo de Alta

Motivo: Devido a falta de informações na base de dados, foi necessário optar por esta solução
************************************************************************************************/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_M_Tot_AtendimentosDB]
AS
BEGIN
    SELECT COUNT(*) AS TotalRegistros 
    FROM (
        SELECT 
            COUNT(*) AS QdtEventos
        FROM 
            T_Internacao
        GROUP BY
            Cod_Paciente
            , DataAdmissao
            , HoraAdmissao
            , DataAlta
            , HoraAlta
            , Cod_Procedimento
            , Cod_TipoAlta
    ) AS ResultadosAgrupados
END
GO