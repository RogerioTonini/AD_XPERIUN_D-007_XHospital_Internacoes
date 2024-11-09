/************************************************************************************************
Criado por: Rogerio Tonini
Data......: 07/11/2024
Objetivo..: Totalizar o Faturamento [ValorDespesas], Tabela: [T_Internacao]
************************************************************************************************/
USE [DB_Hospital]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_M_ValorFaturamento]
AS
BEGIN
    SELECT 
        ROUND( SUM( ValorDespesas ), 2 )
         AS VlrFaturamento 
    FROM 
        T_Internacao
END
GO