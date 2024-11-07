SELECT COUNT(*) AS TotalRegistros 
FROM (
    SELECT 
        Num_Internacao
        , Cod_Paciente
        , SUM(ValorDespesas) AS Total_Despesas
        , COUNT(*) AS QdtEventos
    FROM 
        T_Internacao
    GROUP BY
        Cod_Paciente
        , Num_Internacao
        , DataAdmissao
        , HoraAdmissao
        , DataAlta
        , HoraAlta
        , Cod_Procedimento
        , Cod_TipoAlta
) AS ResultadosAgrupados