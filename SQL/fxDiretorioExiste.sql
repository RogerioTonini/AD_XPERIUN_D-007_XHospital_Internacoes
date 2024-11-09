SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fxDiretorioExiste](@Caminho VARCHAR(255))
    RETURNS BIT
AS
BEGIN
	DECLARE @Resp INT
	DECLARE @Comando NVARCHAR(300) = 'dir "' + @Caminho + '"'

	-- Executar o comando usando xp_cmdshell
	EXEC @Resp = xp_cmdshell @Comando, NO_OUTPUT
	
	-- Retornar 1 se o diretório existir (comando executado com sucesso), caso contrário 0
	RETURN 
		CASE WHEN @Resp = 0 THEN 1 ELSE 0 
		END
END
GO
