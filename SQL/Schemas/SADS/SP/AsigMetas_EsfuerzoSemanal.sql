CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_EsfuerzoSemanal 
(  
    @mes INT,   
    @anio INT,   
    @agencia INT   
)   
AS   
BEGIN   
  
    SET NOCOUNT ON;  
  
    -----------------------------------------------------------  
    -- METAS semanales  
    -----------------------------------------------------------  
  
    SELECT  
        M.NUR,  
        (  
            DAY(M.Fecha)   
            +   
            (  
                (  
                    DATEPART(  
                        WEEKDAY,  
                        DATEFROMPARTS(  
                            YEAR(M.Fecha),  
                            MONTH(M.Fecha),  
                            1  
                        )  
                    )  
                    + @@DATEFIRST - 2  
                ) % 7  
            )  
            - 1  
        ) / 7 + 1 AS Semana_Mes,  
        M.Valor_Meta AS Meta_Volumen  
    INTO #metas_semanales  
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
    -- Distribución de esfuerzo semanal  
    -------------------------------------------------------  
    SELECT
        M.NUR,
        CAST(M.Semana_Mes AS INT) AS Semana_Mes,
        SUM(M.Meta_Volumen)
            / SUM(SUM(M.Meta_Volumen)) OVER (
                PARTITION BY M.NUR
            ) AS Esfuerzo
    FROM #metas_semanales AS M
    GROUP BY
        M.NUR,
        M.Semana_Mes
    ORDER BY
        M.NUR,
        M.Semana_Mes;

END
  
  