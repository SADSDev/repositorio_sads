CREATE OR ALTER PROCEDURE PWST.CATALOGOS_ObtenerSupervisores
(
    @agencia INT=NULL 
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT
        Grupo AS Zona
    FROM PWST.CATALOGOS_Vendedores
    WHERE (@agencia IS NULL OR Agencia = @agencia)
    AND Grupo != 'MAYOREO'
    ORDER BY Grupo;
END;
GO