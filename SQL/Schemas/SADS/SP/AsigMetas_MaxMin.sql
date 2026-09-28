CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_MaxMin  
(  
    @mes INT,   
    @anio INT,   
    @agencia INT   
)   
AS   
BEGIN   
  
    SET NOCOUNT ON;  
    -----------------------------------------------------------  
    -- METAS SEMANALES  
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
  
        CEILING(SUM(M.Valor_Meta)) AS Meta_Volumen  
  
    INTO #metas_semanales  
  
    FROM PWST.SADS_SegOper_Metas AS M   
  
    INNER JOIN PWST.CATALOGOS_Agencias AS A   
        ON M.NUR LIKE '%' + A.Clave_NUR + '%'   
  
    WHERE   
        M.Indicador = 'VOLUMEN'   
        AND M.Fecha BETWEEN  
            DATEFROMPARTS(@anio, @mes, 1)  
            AND EOMONTH(DATEFROMPARTS(@anio, @mes, 1))  
        AND A.Agencia = @agencia   
  
    GROUP BY   
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
        ) / 7 + 1;  
    -----------------------------------------------------------
    -- Rutas unicas
    ----------------------------------------------------------
    SELECT DISTINCT
        NUR
    INTO #NUR
    FROM #metas_semanales
  
    -----------------------------------------------------------
    -- MAX / MIN ERROR
    -----------------------------------------------------------

    ;WITH Simulaciones AS
    (
        SELECT
            S.NUR,
            S.Error,
            (
                DAY(S.Fecha)
                +
                (
                    (
                        DATEPART(
                            WEEKDAY,
                            DATEFROMPARTS(
                                YEAR(S.Fecha),
                                MONTH(S.Fecha),
                                1
                            )
                        )
                        + @@DATEFIRST - 2
                    ) % 7
                )
                - 1
            ) / 7 + 1 AS Semana_Mes
        FROM PWST.ANALYTICS_SimulacionesVentas AS S
        INNER JOIN
        (
            SELECT DISTINCT NUR
            FROM #metas_semanales
        ) N
            ON N.NUR = S.NUR
        WHERE
            S.Fecha BETWEEN
                DATEFROMPARTS(@anio, @mes, 1)
                AND EOMONTH(DATEFROMPARTS(@anio, @mes, 1))
    ),
    Percentiles AS
    (
        SELECT
            NUR,
            Semana_Mes,
            Error,
            PERCENTILE_CONT(0.95)
                WITHIN GROUP (ORDER BY Error)
                OVER (
                    PARTITION BY NUR, Semana_Mes
                ) AS P95
        FROM Simulaciones
    )
    SELECT
        NUR,
        Semana_Mes,
        CASE
            WHEN MIN(Error) = 0
            THEN MIN(CASE WHEN Error > 0 THEN Error END)
            ELSE MIN(Error)
        END AS Minimo,
        MAX(P95) AS Maximo
    INTO #maximo_minimo
    FROM Percentiles
    GROUP BY
        NUR,
        Semana_Mes;
  

    -------------------------------------------------------  
    -- RESULT SET 3  
    -- Min / P95 error semanal  
    -------------------------------------------------------  
  
    SELECT   
        M.NUR,   
        M.Semana_Mes,   
        CAST(CEILING(M.Meta_Volumen) AS INT) AS Meta_Volumen,   
        MM.Minimo,   
        MM.Maximo  
    FROM #metas_semanales AS M  
    LEFT JOIN #maximo_minimo AS MM  
        ON M.NUR = MM.NUR  
        AND M.Semana_Mes = MM.Semana_Mes  
    ORDER BY   
        M.NUR,   
        M.Semana_Mes;  
END;  
  