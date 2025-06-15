CREATE PROCEDURE SP_TrataErro(
    IN error          INT
    , IN TipoMensagem CHAR(1)
    , IN Tabela       VARCHAR(30)
    , IN NomeColuna   VARCHAR(100)
)
BEGIN
    DECLARE InicioMensSucesso VARCHAR(15) DEFAULT 'Atualização da ';
    DECLARE FimMensSucesso    VARCHAR(42) DEFAULT '] criada(s) / realizada(s) com SUCESSO!!!';
    DECLARE InicioMensErro    VARCHAR(26) DEFAULT 'NÃO foi possível realizar ';
    DECLARE FimMensErro       VARCHAR(15) DEFAULT ']. Verificar!!!';
    DECLARE MensTabela        VARCHAR(11) DEFAULT 'da Tabela [';
    DECLARE MensColuna        VARCHAR(14) DEFAULT '], Coluna(s) [';

    SET TipoMensagem = UPPER(TipoMensagem);

    SELECT '';

    IF TipoMensagem = 'C' THEN -- Criação de tabela
        IF error <> 0 THEN
            SELECT CONCAT(InicioMensErro, MensTabela, Tabela, FimMensErro);
        ELSE
            SELECT CONCAT('Tabela [', Tabela, FimMensSucesso);
        END IF;
    ELSEIF TipoMensagem = 'U' THEN -- UPLOAD de tabela
        IF error <> 0 THEN
            SELECT CONCAT(InicioMensErro, 'UPLOAD na Tabela [', Tabela, FimMensErro);
        ELSE
            SELECT CONCAT('UPLOAD ', MensTabela, Tabela, FimMensSucesso);
        END IF;
    ELSEIF TipoMensagem IN ('A', 'E') THEN -- [A] - Atualização de dados: JOIN / [E] Alteração na estrutura da Tabela (Criação/Exclusão de colunas)
        IF error <> 0 THEN
            SELECT CONCAT(InicioMensErro, MensTabela, Tabela, MensColuna, NomeColuna, FimMensErro);
        ELSE
            SELECT CONCAT(InicioMensSucesso, MensTabela, Tabela, MensColuna, NomeColuna, FimMensSucesso);
        END IF;
    END IF;
END $