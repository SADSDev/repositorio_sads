CREATE OR ALTER PROCEDURE CATALOGOS.ObtenerRutas
(
    @agencia INT=NULL,
    @zona VARCHAR(20)=NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        'R' + SUBSTRING(NUR, PATINDEX('%[A-Z]%', NUR) + 1, LEN(NUR)) AS Ruta
    FROM CATALOGOS.Rutas_Evaluables
    WHERE
        (@agencia IS NULL OR Agencia = @agencia)
        AND (@zona IS NULL OR Grupo = @zona)
    ORDER BY Ruta;
END;
GO