CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_MaxMin
(
    @mes INT,
    @anio INT,
    @agencia INT
)
AS
BEGIN

    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM PWST.ANALYTICS_PercentilesVentasSemanales
        WHERE YEAR(Mes) = @anio
          AND MONTH(Mes) = @mes
          AND Agencia = @agencia
    )
    BEGIN
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
            ) / 7 + 1 AS Semana_Mes
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
                S.Fecha >= DATEFROMPARTS(@anio, @mes, 1)
                AND S.Fecha < DATEADD(
                    MONTH,
                    1,
                    DATEFROMPARTS(@anio, @mes, 1)
                )
        ),
        Percentiles AS
        (
            SELECT
                NUR,
                Semana_Mes,
                PERCENTILE_CONT(0.15)
                    WITHIN GROUP (ORDER BY Error)
                    OVER (
                        PARTITION BY NUR, Semana_Mes
                    ) AS P15,
                PERCENTILE_CONT(0.80)
                    WITHIN GROUP (ORDER BY Error)
                    OVER (
                        PARTITION BY NUR, Semana_Mes
                    ) AS Pmax
            FROM Simulaciones
        )
        SELECT
            NUR,
            Semana_Mes,
            MAX(P15) AS Minimo,
            MAX(Pmax) AS Maximo
        INTO #maximo_minimo
        FROM Percentiles
        GROUP BY
            NUR,
            Semana_Mes;

        -----------------------------------------------------------
        -- GUARDAR EN TABLA HISTORICA
        -----------------------------------------------------------
        INSERT INTO PWST.ANALYTICS_PercentilesVentasSemanales
        (
            Mes,
            Agencia,
            NUR,
            Semana_Mes,
            PMin,
            PMax
        )
        SELECT
            DATEFROMPARTS(@anio, @mes, 1),
            @agencia,
            MM.NUR,
            MM.Semana_Mes,
            MM.Minimo,
            MM.Maximo
        FROM #maximo_minimo AS MM;

        -----------------------------------------------------------
        -- RESULT SET
        -----------------------------------------------------------

        SELECT
            M.NUR,
            M.Semana_Mes,
            MM.Minimo,
            MM.Maximo
        FROM #metas_semanales AS M
        LEFT JOIN #maximo_minimo AS MM
            ON M.NUR = MM.NUR
            AND M.Semana_Mes = MM.Semana_Mes
        ORDER BY
            M.NUR,
            M.Semana_Mes;
    END

    ELSE
    BEGIN
        -----------------------------------------------------------
        -- CONSULTAR PERCENTILES HISTORICOS
        -----------------------------------------------------------
        SELECT
            NUR,
            Semana_Mes,
            PMin AS Minimo,
            PMax AS Maximo
        FROM PWST.ANALYTICS_PercentilesVentasSemanales
        WHERE YEAR(Mes) = @anio
          AND MONTH(Mes) = @mes
          AND Agencia = @agencia
        ORDER BY
            NUR,
            Semana_Mes;

    END;

END;
GO