SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[fxCalc_Periodo]
    (
        @TipoCalculo   NVARCHAR(1)  -- Tipo de cálculo a realizar: 'Y' para YEAR, 'M' para MONTH, 'D' para DAY
        , @DataInicial DATE
        , @DataFinal   DATE
    )
RETURNS INT
AS
BEGIN
    DECLARE @Result  INT

    SET @TipoCalculo = UPPER(@TipoCalculo)

    -- Validações
    IF ISNULL(@TipoCalculo, '') = '' 
        OR @TipoCalculo NOT LIKE '[DMY]' 
        OR @DataInicial > @DataFinal
    BEGIN
        RETURN NULL  -- Retorna NULL se qualquer condição for inválida
    END
    -- Define o intervalo para DATEDIFF
    SET @Result = 
        CASE 
            WHEN @TipoCalculo = 'D' THEN DATEDIFF(DAY,   @DataInicial, @DataFinal)
            WHEN @TipoCalculo = 'M' THEN DATEDIFF(MONTH, @DataInicial, @DataFinal)
            WHEN @TipoCalculo = 'Y' THEN DATEDIFF(YEAR,  @DataInicial, @DataFinal)
        END
    -- Ajusta para anos completos, se necessário
    IF @TipoCalculo = 'Y' 
        AND 
        ( 
            MONTH( @DataInicial ) > MONTH( @DataFinal ) 
            OR 
            ( 
                MONTH( @DataInicial ) = MONTH( @DataFinal ) 
                AND DAY( @DataInicial ) > DAY( @DataFinal ) 
            ) 
        )
        SET @Result -= 1

    RETURN @Result
END
GO
