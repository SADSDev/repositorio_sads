CREATE OR ALTER PROCEDURE PWST.CATALOGOS_ObtenerFrecuenciasReporte
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        FrecuenciaId,
        Frecuencia
    FROM PWST.CATALOGOS_Frecuencias_Reportes
    ORDER BY FrecuenciaId;
END;
GO