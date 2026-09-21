CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_Simulaciones 
(
    @mes INT, 
    @anio INT, 
    @agencia INT 
) 
AS 
BEGIN 

    SET NOCOUNT ON;
    -----------------------------------------------------------
    -- METAS DIARIAS
    -----------------------------------------------------------

    SELECT
        M.NUR,
        M.Fecha,
        M.Valor_Meta AS Meta_Volumen
    INTO #metas_diarias

    FROM PWST.SADS_SegOper_Metas AS M

    INNER JOIN PWST.CATALOGOS_Agencias AS A
        ON M.NUR LIKE '%' + A.Clave_NUR + '%'

    WHERE
        M.Indicador = 'VOLUMEN'
        AND A.Agencia = @agencia
        AND M.Fecha BETWEEN
            DATEFROMPARTS(@anio, @mes, 1)
            AND EOMONTH(DATEFROMPARTS(@anio, @mes, 1));
    -------------------------------------------------------
    -- RESULT SET 1
    -- Distribuciones de simulaciones de venta
    -------------------------------------------------------
    SELECT 
        S.NUR, 
        S.Simulacion,
        MONTH(S.Fecha) AS Mes, 
        SUM(M.Meta_Volumen * S.Error) AS Volumen_Simulado_Mensual 
    FROM PWST.ANALYTICS_SimulacionesVentas AS S 
    INNER JOIN #metas_diarias AS M 
        ON S.NUR = M.NUR 
        AND S.Fecha = M.Fecha 
    GROUP BY 
        S.NUR, 
        S.Simulacion, 
        MONTH(S.Fecha);
    
END