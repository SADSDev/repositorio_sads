CREATE OR ALTER PROCEDURE CATALOGOS.ObtenerFrecuenciasReporte
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        FrecuenciaId,
        Frecuencia
    FROM CATALOGOS.Frecuencias_Reportes
    ORDER BY FrecuenciaId;
END;
GO