CREATE OR ALTER PROCEDURE CATALOGOS.ObtenerSupervisores
(
    @agencia INT=NULL 
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT
        Grupo AS Zona
    FROM CATALOGOS.Vendedores
    WHERE (@agencia IS NULL OR Agencia = @agencia)
    ORDER BY Grupo;
END;
GO