CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_MaxMin
(
    @mes INT,
    @anio INT,
    @agencia INT
)
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @MesInicio DATE;
    DECLARE @MesSiguiente DATE;

    SET @MesInicio = DATEADD(
        MONTH,
        @mes - 1,
        DATEADD(YEAR, @anio - 1900, 0)
    );

    SET @MesSiguiente = DATEADD(MONTH, 1, @MesInicio);

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
                            DATEADD(
                                MONTH,
                                DATEDIFF(MONTH, 0, M.Fecha),
                                0
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
                @MesInicio
                AND DATEADD(DAY, -1, @MesSiguiente)
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
                            DATEADD(MONTH, DATEDIFF(MONTH, 0, M.Fecha), 0)
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
                                DATEADD(
                                    MONTH,
                                    DATEDIFF(MONTH, 0, S.Fecha),
                                    0
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
                S.Fecha >= @MesInicio
                AND S.Fecha < @MesSiguiente
        ),
        Ordenadas AS
        (
            SELECT
                NUR,
                Semana_Mes,
                Error,
                ROW_NUMBER() OVER
                (
                    PARTITION BY NUR, Semana_Mes
                    ORDER BY Error
                ) AS Orden,
                COUNT(*) OVER
                (
                    PARTITION BY NUR, Semana_Mes
                ) AS Total
            FROM Simulaciones
        ),
        Posiciones AS
        (
            SELECT DISTINCT
                NUR,
                Semana_Mes,
                CAST(1 + (Total - 1) * 0.15 AS DECIMAL(19,10)) AS Pos15,
                CAST(1 + (Total - 1) * 0.80 AS DECIMAL(19,10)) AS Pos80
            FROM Ordenadas
        ),
        Valores AS
        (
            SELECT
                O.NUR,
                O.Semana_Mes,
                P.Pos15,
                P.Pos80,
                MAX(
                    CASE
                        WHEN O.Orden = FLOOR(P.Pos15)
                            THEN O.Error
                    END
                ) AS P15Inferior,
                MAX(
                    CASE
                        WHEN O.Orden = CEILING(P.Pos15)
                            THEN O.Error
                    END
                ) AS P15Superior,
                MAX(
                    CASE
                        WHEN O.Orden = FLOOR(P.Pos80)
                            THEN O.Error
                    END
                ) AS P80Inferior,
                MAX(
                    CASE
                        WHEN O.Orden = CEILING(P.Pos80)
                            THEN O.Error
                    END
                ) AS P80Superior
            FROM Ordenadas O
            INNER JOIN Posiciones P
                ON P.NUR = O.NUR
                AND P.Semana_Mes = O.Semana_Mes
            GROUP BY
                O.NUR,
                O.Semana_Mes,
                P.Pos15,
                P.Pos80
        ),
        Percentiles AS
        (
            SELECT
                NUR,
                Semana_Mes,
                CAST(
                    P15Inferior
                    + (Pos15 - FLOOR(Pos15))
                        * (P15Superior - P15Inferior)
                    AS DECIMAL(18,6)
                ) AS P15,
                CAST(
                    P80Inferior
                    + (Pos80 - FLOOR(Pos80))
                        * (P80Superior - P80Inferior)
                    AS DECIMAL(18,6)
                ) AS Pmax
            FROM Valores
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
            @MesInicio,
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
