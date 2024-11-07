SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_MensagemErro]
    @@@error        INT
    , @TipoMensagem CHAR(1)
    , @Tabela       VARCHAR(30)
    , @NomeColuna   VARCHAR(MAX)
AS
BEGIN
    DECLARE 
        @InicioMensSucesso VARCHAR(15) = 'Atualização da '
        , @FimMensSucesso  VARCHAR(42) = '] criada(s) / realizada(s) com SUCESSO!!!'
        , @InicioMensErro  VARCHAR(26) = 'NÃO foi possível realizar '
        , @FimMensErro     VARCHAR(15) = ']. Verificar!!!'
        , @MensTabela      VARCHAR(11) = 'da Tabela ['
        , @MensColuna      VARCHAR(14) = '], Coluna(s) ['

    SET @TipoMensagem = UPPER(@TipoMensagem)

    PRINT '' 
    IF @TipoMensagem = 'C' -- Criação de tabela
    BEGIN
        IF @@@error <> 0
            PRINT @InicioMensErro + @MensTabela + @Tabela + @FimMensErro
        ELSE
            PRINT 'Tabela [' + @Tabela + @FimMensSucesso
    END
    ELSE IF @TipoMensagem = 'U' -- UPLOAD de tabela
    BEGIN
        IF @@@error <> 0
            PRINT @InicioMensErro + 'UPLOAD na Tabela [' + @Tabela + @FimMensErro
        ELSE
            PRINT 'UPLOAD ' + @MensTabela + @Tabela + @FimMensSucesso
    END
    ELSE IF @TipoMensagem LIKE '[AE]' -- [A] - Atualização de dados: JOIN / [E] Alteração na estrutura da Tabela (Criação/Exclusão de colunas)
    BEGIN
        IF @@@error <> 0
            PRINT @InicioMensErro + @MensTabela + @Tabela + @MensColuna + @NomeColuna + @FimMensErro
        ELSE
            PRINT @InicioMensSucesso + @MensTabela + @Tabela + @MensColuna + @NomeColuna + @FimMensSucesso
    END
END
GO
