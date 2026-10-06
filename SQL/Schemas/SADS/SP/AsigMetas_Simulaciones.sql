CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_Simulaciones 
(
    @mes INT, 
    @anio INT, 
    @agencia INT 
) 
AS 
BEGIN 

    SET NOCOUNT ON;
    
    DECLARE @fecha DATE;

    SET @fecha = DATEFROMPARTS(@anio, @mes, 1);

    -------------------------------------------------------
    -- RESULT SET 1
    -- Distribuciones de simulaciones de venta
    -------------------------------------------------------
    SELECT
        S.NUR,
        CAST(ROUND(S.Volumen_Simulado_Mensual,0) AS INT) AS Volumen_Simulado_Mensual 
    FROM PWST.ANALYTICS_SimulacionesVentasMensuales S
    LEFT JOIN PWST.CATALOGOS_Agencias A
        ON S.NUR LIKE A.Clave_NUR + '%'
    WHERE 
        A.Agencia = @agencia
        AND S.Mes = @fecha;
    
END