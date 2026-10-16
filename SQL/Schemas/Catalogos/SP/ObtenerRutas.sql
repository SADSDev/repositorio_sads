CREATE OR ALTER PROCEDURE PWST.CATALOGOS_ObtenerRutas
(
    @agencia INT=NULL,
    @zona VARCHAR(20)=NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        'R' + SUBSTRING(NUR, PATINDEX('%[A-Z]%', NUR) + 1, LEN(NUR)) AS Ruta
    FROM PWST.CATALOGOS_Vendedores
    WHERE
        (@agencia IS NULL OR Agencia = @agencia)
        AND (@zona IS NULL OR Grupo = @zona)
        AND Evaluable=1
    ORDER BY Ruta;
END;
GO