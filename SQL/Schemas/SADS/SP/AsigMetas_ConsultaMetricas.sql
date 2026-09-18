CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_ConsultaMetricasExistentes 
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


    -----------------------------------------------------------
    -- MAX / MIN ERROR
    -----------------------------------------------------------

    SELECT
        V.NUR,
        V.Semana_Mes,
        CASE
            WHEN MIN(V.Error) = 0
            THEN MIN(CASE WHEN V.Error > 0 THEN V.Error END)
            ELSE MIN(V.Error)
        END AS Minimo,
        MAX(V.P95) AS Maximo
    INTO #maximo_minimo
    FROM
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
            ) / 7 + 1 AS Semana_Mes,

            PERCENTILE_CONT(0.95)
                WITHIN GROUP (ORDER BY S.Error)
                OVER
                (
                    PARTITION BY
                        S.NUR,
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
                        ) / 7 + 1
                ) AS P95

        FROM PWST.ANALYTICS_SimulacionesVentas AS S

        INNER JOIN #metas_semanales AS M
            ON S.NUR = M.NUR

        WHERE
            S.Fecha BETWEEN
                DATEFROMPARTS(@anio, @mes, 1)
                AND EOMONTH(DATEFROMPARTS(@anio, @mes, 1))
    ) V

    GROUP BY
        V.NUR,
        V.Semana_Mes;

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
    -------------------------------------------------------
    -- RESULT SET 2
    -- Distribución de esfuerzo diario
    -------------------------------------------------------
    SELECT 
        M.NUR, 
        M.Fecha, 
        M.Meta_Volumen
            / SUM(M.Meta_Volumen) OVER (
                PARTITION BY M.NUR
            ) AS Esfuerzo
    FROM #metas_diarias AS M
    ORDER BY 
        M.NUR, 
        M.Fecha;


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

--------------------------------------
-- RESULT SET 4
-- METAS MENSUALES
--------------------------------------
SELECT
    ISNULL(CAST(MAX(Indicador) AS INT),0) AS Indicador,
    ISNULL(CAST(MAX(Valor_Meta) AS INT),0) AS Valor_Meta
FROM PWST.SADS_SegOper_MetasAgencia
WHERE Agencia=@agencia
AND MONTH(Mes)=@mes
AND YEAR(Mes)=@anio