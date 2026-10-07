CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_EsfuerzoDiario 
(  
    @mes INT,   
    @anio INT,   
    @agencia INT   
)   
AS   
BEGIN   
  
    SET NOCOUNT ON;  
  
    -----------------------------------------------------------  
    -- METAS diarias  
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
    -- RESULT SET 2  
    -- Distribución de esfuerzo diario  
    -------------------------------------------------------  
    SELECT
        M.NUR,
        M.Fecha,
        SUM(M.Meta_Volumen)
            / SUM(SUM(M.Meta_Volumen)) OVER (
                PARTITION BY M.NUR
            ) AS Esfuerzo
    FROM #metas_diarias AS M
    GROUP BY
        M.NUR,
        M.Fecha
    ORDER BY
        M.NUR,
        M.Fecha;

END
  
  