CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_VolumenAgencias
(
    @fecha DATE,
    @agencia VARCHAR(200) = NULL,
    @zona VARCHAR(200) = NULL,
    @ruta VARCHAR(200) = NULL,
    @frecuencia INT
)
AS
BEGIN
SET NOCOUNT ON;

    SET @agencia = NULLIF(REPLACE(LTRIM(RTRIM(@agencia)), ' ', ''), '');
    SET @zona = NULLIF(LTRIM(RTRIM(@zona)), '');
    SET @ruta = NULLIF(LTRIM(RTRIM(@ruta)), '');

    DECLARE @Mes DATE = DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1);

    DECLARE @UnaAgencia BIT =
        CASE
            WHEN @agencia IS NOT NULL
             AND CHARINDEX(',', @agencia) = 0
            THEN 1
            ELSE 0
        END;

    IF @frecuencia NOT IN (1, 2, 3)
        THROW 50001, 'La frecuencia debe ser 1, 2 o 3.', 1;

    DECLARE @FechaInicio DATE =
        CASE @frecuencia
            WHEN 1 THEN @fecha
            WHEN 2 THEN
                CASE
                    WHEN DATEADD(
                        DAY,
                        -(DATEDIFF(DAY, '19000101', @fecha) % 7),
                        @fecha
                    ) < @Mes
                    THEN @Mes
                    ELSE DATEADD(
                        DAY,
                        -(DATEDIFF(DAY, '19000101', @fecha) % 7),
                        @fecha
                    )
                END
            WHEN 3 THEN @Mes
        END;

    DECLARE @FechaFin DATE =
        CASE @frecuencia
            WHEN 1 THEN @fecha
            WHEN 2 THEN
                CASE
                    WHEN DATEADD(
                        DAY,
                        6 - (DATEDIFF(DAY, '19000101', @fecha) % 7),
                        @fecha
                    ) > EOMONTH(@fecha)
                    THEN EOMONTH(@fecha)
                    ELSE DATEADD(
                        DAY,
                        6 - (DATEDIFF(DAY, '19000101', @fecha) % 7),
                        @fecha
                    )
                END
            WHEN 3 THEN EOMONTH(@fecha)
        END;

    /* =====================================================
       UNA SOLA AGENCIA: RESULTADO POR GRUPO
       ===================================================== */

    IF @UnaAgencia = 1
    BEGIN
        ;WITH RutasNormales AS
        (
            SELECT DISTINCT
                V.NUR,
                V.Grupo AS Zona,
                CAST(0 AS BIT) AS EsMayoreo
            FROM PWST.CATALOGOS_Rutas_Evaluables V
            INNER JOIN PWST.CATALOGOS_Agencias A
                ON V.NUR LIKE A.Clave_NUR + '%'
            WHERE A.Agencia = TRY_CONVERT(INT, @agencia)
              AND V.Grupo <> 'MAYOREO'
              AND NOT EXISTS
              (
                  SELECT 1
                  FROM PWST.CATALOGOS_Vendedores VM
                  WHERE VM.NUR = V.NUR
                    AND VM.Grupo = 'MAYOREO'
              )
        ),
        RutasMayoreo AS
        (
            SELECT DISTINCT
                V.NUR,
                'MAYOREO' AS Zona,
                CAST(1 AS BIT) AS EsMayoreo
            FROM PWST.CATALOGOS_Vendedores V
            INNER JOIN PWST.CATALOGOS_Agencias A
                ON V.NUR LIKE A.Clave_NUR + '%'
            WHERE A.Agencia = TRY_CONVERT(INT, @agencia)
              AND V.Grupo = 'MAYOREO'
        )
        SELECT
            NUR,
            Zona,
            EsMayoreo
        INTO #RutasSector
        FROM RutasNormales

        UNION ALL

        SELECT
            NUR,
            Zona,
            EsMayoreo
        FROM RutasMayoreo;

        CREATE INDEX IX_RutasSector_NUR
            ON #RutasSector (NUR);

        SELECT
            VD.Fecha,
            VD.NUR,
            VD.Cantidad,
            CASE
                WHEN G.Cliente IS NULL THEN 0
                ELSE 1
            END AS EsGTP,
            R.EsMayoreo
        INTO #VentasSector
        FROM PWST.POWERSTREET_Venta_Diaria VD
        INNER JOIN #RutasSector R
            ON R.NUR = VD.NUR
        LEFT JOIN PWST.CATALOGOS_Clientes_GTP G
            ON G.Cliente = VD.Cliente
        WHERE VD.Fecha BETWEEN @Mes AND @fecha;

        CREATE INDEX IX_VentasSector_FechaNUR
            ON #VentasSector (Fecha, NUR);

        DECLARE
            @MetaGTP DECIMAL(18,3),
            @MetaMM DECIMAL(18,3),
            @AvanceGTPPeriodo DECIMAL(18,3),
            @AvanceGTPMes DECIMAL(18,3),
            @AvanceGTPAntes DECIMAL(18,3),
            @AvanceMMMes DECIMAL(18,3),
            @ExcedenteGTP DECIMAL(18,3);

        SELECT
            @MetaGTP =
                COALESCE(
                    SUM(
                        CASE
                            WHEN UPPER(LTRIM(RTRIM(Indicador)))
                                = 'VOLUMEN GTP'
                            THEN Valor_Meta
                            ELSE 0
                        END
                    ),
                    0
                ),
            @MetaMM =
                COALESCE(
                    SUM(
                        CASE
                            WHEN UPPER(LTRIM(RTRIM(Indicador)))
                                = 'VOLUMEN MM'
                            THEN Valor_Meta
                            ELSE 0
                        END
                    ),
                    0
                )
        FROM PWST.SADS_SegOper_MetasAgencia
        WHERE Agencia = TRY_CONVERT(INT, @agencia)
          AND Mes = @Mes;

        SELECT
            @AvanceGTPPeriodo =
                COALESCE(
                    SUM(
                        CASE
                            WHEN EsGTP = 1
                             AND Fecha BETWEEN @FechaInicio AND @fecha
                            THEN Cantidad
                            ELSE 0
                        END
                    ),
                    0
                ),
            @AvanceGTPMes =
                COALESCE(
                    SUM(
                        CASE
                            WHEN EsGTP = 1
                            THEN Cantidad
                            ELSE 0
                        END
                    ),
                    0
                ),
            @AvanceGTPAntes =
                COALESCE(
                    SUM(
                        CASE
                            WHEN EsGTP = 1
                             AND Fecha < @FechaInicio
                            THEN Cantidad
                            ELSE 0
                        END
                    ),
                    0
                ),
            @AvanceMMMes =
                COALESCE(
                    SUM(
                        CASE
                            WHEN EsMayoreo = 1
                                THEN Cantidad
                            ELSE 0
                        END
                    ),
                    0
                )
        FROM #VentasSector;

        SET @ExcedenteGTP =
            CASE
                WHEN @AvanceGTPMes - @MetaGTP > 0
                    THEN @AvanceGTPMes - @MetaGTP
                ELSE 0
            END
            -
            CASE
                WHEN @AvanceGTPAntes - @MetaGTP > 0
                    THEN @AvanceGTPAntes - @MetaGTP
                ELSE 0
            END;

        ;WITH Sectores AS
        (
            SELECT DISTINCT Zona
            FROM #RutasSector
            WHERE
                @zona IS NULL
                OR EXISTS
                (
                    SELECT 1
                    FROM STRING_SPLIT(@zona, CHAR(44)) Z
                    WHERE LTRIM(RTRIM(Z.value)) = Zona
                )
        ),
        RutasFiltradas AS
        (
            SELECT R.*
            FROM #RutasSector R
            WHERE
                (
                    @zona IS NULL
                    OR EXISTS
                    (
                        SELECT 1
                        FROM STRING_SPLIT(@zona, CHAR(44)) Z
                        WHERE LTRIM(RTRIM(Z.value)) = R.Zona
                    )
                )
                AND
                (
                    @ruta IS NULL
                    OR CONCAT(
                        'R',
                        SUBSTRING(
                            R.NUR,
                            PATINDEX('%[A-Z]%', R.NUR) + 1,
                            LEN(R.NUR)
                        )
                    ) IN
                    (
                        SELECT LTRIM(RTRIM(value))
                        FROM STRING_SPLIT(@ruta, CHAR(44))
                    )
                )
        ),
        MetasRuta AS
        (
            SELECT
                M.NUR,
                SUM(
                    CASE
                        WHEN M.Fecha BETWEEN @FechaInicio AND @FechaFin
                            THEN M.Valor_Meta
                        ELSE 0
                    END
                ) AS MetaVolumen,
                SUM(
                    CASE
                        WHEN M.Fecha BETWEEN @FechaInicio AND @fecha
                            THEN M.Valor_Meta
                        ELSE 0
                    END
                ) AS ObjAlDia
            FROM PWST.SADS_SegOper_Metas M
            INNER JOIN #RutasSector R
                ON R.NUR = M.NUR
            WHERE R.EsMayoreo = 0
              AND UPPER(M.Indicador) = 'VOLUMEN'
              AND M.Fecha BETWEEN @FechaInicio AND @FechaFin
            GROUP BY M.NUR
        ),
        MetasSector AS
        (
            SELECT
                R.Zona,
                SUM(COALESCE(M.MetaVolumen, 0)) AS MetaVolumen,
                SUM(COALESCE(M.ObjAlDia, 0)) AS ObjAlDia
            FROM RutasFiltradas R
            LEFT JOIN MetasRuta M
                ON M.NUR = R.NUR
            WHERE R.EsMayoreo = 0
            GROUP BY R.Zona
        ),
        AvancesSector AS
        (
            SELECT
                R.Zona,
                SUM(
                    CASE
                        WHEN R.EsMayoreo = 1
                            THEN V.Cantidad
                        WHEN V.EsGTP = 0
                            THEN V.Cantidad
                        ELSE 0
                    END
                ) AS AvanceCLO,
                SUM(
                    CASE
                        WHEN V.EsGTP = 1
                            THEN V.Cantidad
                        ELSE 0
                    END
                ) AS AvanceGTP
            FROM RutasFiltradas R
            LEFT JOIN #VentasSector V
                ON V.NUR = R.NUR
            AND V.Fecha BETWEEN @FechaInicio AND @fecha
            GROUP BY R.Zona
        )

        SELECT
            S.Zona AS CLO,

            CAST(
                CEILING(
                    CASE
                        WHEN S.Zona = 'MAYOREO'
                            THEN @MetaMM
                        ELSE COALESCE(M.MetaVolumen, 0)
                    END
                ) AS INT
            ) AS MetaVolumen,

            CAST(
                CASE
                    WHEN S.Zona = 'MAYOREO'
                        THEN 0
                    ELSE COALESCE(M.ObjAlDia, 0)
                END
                AS INT
            ) AS ObjAlDia,

            CAST(COALESCE(A.AvanceCLO, 0) AS DECIMAL(18,3))
                AS AvanceCLO,

            CAST(
                CASE
                    WHEN @AvanceGTPPeriodo = 0
                        THEN 0
                    ELSE
                        @ExcedenteGTP
                        * COALESCE(A.AvanceGTP, 0)
                        / NULLIF(@AvanceGTPPeriodo, 0)
                END
                AS DECIMAL(18,3)
            ) AS InyeccionGTP,

            CAST(
                CASE
                    WHEN S.Zona = 'MAYOREO'
                     AND @AvanceMMMes > @MetaMM
                        THEN
                            CASE
                                WHEN @frecuencia IN (1, 2)
                                    THEN COALESCE(A.AvanceCLO, 0)
                                WHEN @frecuencia = 3
                                    THEN COALESCE(A.AvanceCLO, 0) - @MetaMM
                                ELSE 0
                            END
                    ELSE 0
                END
                AS DECIMAL(18,3)
            ) AS InyeccionMM
        FROM Sectores S
        LEFT JOIN MetasSector M
            ON M.Zona = S.Zona
        LEFT JOIN AvancesSector A
            ON A.Zona = S.Zona
        ORDER BY S.Zona;

        DROP TABLE #VentasSector;
        DROP TABLE #RutasSector;
        RETURN;
    END;

    /* =====================================================
       VARIAS AGENCIAS O AGENCIA NULL: RESULTADO POR CLO
       ===================================================== */

    SELECT DISTINCT
        V.NUR,
        A.Agencia,
        A.CLO,
        V.Grupo AS Zona
    INTO #RutasGlobal
    FROM PWST.CATALOGOS_Rutas_Evaluables V
    INNER JOIN PWST.CATALOGOS_Agencias A
        ON V.NUR LIKE A.Clave_NUR + '%'
    WHERE
        (
            @agencia IS NULL
            OR CHARINDEX(
                ',' + CONVERT(VARCHAR(10), A.Agencia) + ',',
                ',' + @agencia + ','
            ) > 0
        )
        AND
        (
            @zona IS NULL
            OR EXISTS
            (
                SELECT 1
                FROM STRING_SPLIT(@zona, CHAR(44)) Z
                WHERE LTRIM(RTRIM(Z.value)) = V.Grupo
            )
        )
        AND
        (
            @ruta IS NULL
            OR CONCAT(
                'R',
                SUBSTRING(
                    V.NUR,
                    PATINDEX('%[A-Z]%', V.NUR) + 1,
                    LEN(V.NUR)
                )
            ) IN
            (
                SELECT LTRIM(RTRIM(value))
                FROM STRING_SPLIT(@ruta, CHAR(44))
            )
        );

    SELECT
        VD.Fecha,
        VD.NUR,
        VD.Cantidad,
        CASE WHEN G.Cliente IS NULL THEN 0 ELSE 1 END AS EsGTP,
        CASE WHEN VM.NUR IS NULL THEN 0 ELSE 1 END AS EsMM
    INTO #VentasGlobal
    FROM PWST.POWERSTREET_Venta_Diaria VD
    INNER JOIN #RutasGlobal R
        ON R.NUR = VD.NUR
    LEFT JOIN PWST.CATALOGOS_Clientes_GTP G
        ON G.Cliente = VD.Cliente
    LEFT JOIN
    (
        SELECT DISTINCT NUR
        FROM PWST.CATALOGOS_Vendedores
        WHERE Grupo = 'MAYOREO'
    ) VM
        ON VM.NUR = VD.NUR
    WHERE VD.Fecha BETWEEN @Mes AND @fecha;

    ;WITH MetasRuta AS
    (
        SELECT
            M.NUR,
            SUM(
                CASE
                    WHEN M.Fecha BETWEEN @FechaInicio AND @FechaFin
                        THEN M.Valor_Meta
                    ELSE 0
                END
            ) AS MetaVolumen,
            SUM(
                CASE
                    WHEN M.Fecha BETWEEN @FechaInicio AND @fecha
                        THEN M.Valor_Meta
                    ELSE 0
                END
            ) AS ObjAlDia
        FROM PWST.SADS_SegOper_Metas M
        INNER JOIN #RutasGlobal R
            ON R.NUR = M.NUR
        WHERE R.NUR <> '1125632M29'
          AND UPPER(M.Indicador) = 'VOLUMEN'
          AND M.Fecha BETWEEN @FechaInicio AND @FechaFin
        GROUP BY M.NUR
    ),
    AvancesRuta AS
    (
        SELECT
            NUR,
            SUM(
                CASE
                    WHEN EsGTP = 0 AND EsMM = 0
                        THEN Cantidad
                    ELSE 0
                END
            ) AS AvanceCLO
        FROM #VentasGlobal
        WHERE Fecha BETWEEN @FechaInicio AND @fecha
        GROUP BY NUR
    ),
    MetasEspeciales AS
    (
        SELECT
            A.CLO,
            MAX(
                CASE
                    WHEN UPPER(LTRIM(RTRIM(M.Indicador)))
                        = 'VOLUMEN GTP'
                    THEN M.Valor_Meta
                    ELSE 0
                END
            ) AS MetaGTP,
            MAX(
                CASE
                    WHEN UPPER(LTRIM(RTRIM(M.Indicador)))
                        = 'VOLUMEN MM'
                    THEN M.Valor_Meta
                    ELSE 0
                END
            ) AS MetaMM
        FROM PWST.SADS_SegOper_MetasAgencia M
        INNER JOIN PWST.CATALOGOS_Agencias A
            ON A.Agencia = M.Agencia
        WHERE M.Mes = @Mes
          AND M.Indicador IN ('VOLUMEN GTP', 'VOLUMEN MM')
          AND
          (
              @agencia IS NULL
              OR CHARINDEX(
                  ',' + CONVERT(VARCHAR(10), M.Agencia) + ',',
                  ',' + @agencia + ','
              ) > 0
          )
        GROUP BY A.CLO
    ),
    Excedentes AS
    (
        SELECT
            R.CLO,
            SUM(CASE WHEN V.EsGTP = 1 THEN V.Cantidad ELSE 0 END)
                AS AvanceGTPMes,
            SUM(
                CASE
                    WHEN V.EsGTP = 1 AND V.Fecha < @FechaInicio
                        THEN V.Cantidad
                    ELSE 0
                END
            ) AS AvanceGTPAntes,
            SUM(CASE WHEN V.EsMM = 1 THEN V.Cantidad ELSE 0 END)
                AS AvanceMMMes,
            SUM(
                CASE
                    WHEN V.EsMM = 1 AND V.Fecha < @FechaInicio
                        THEN V.Cantidad
                    ELSE 0
                END
            ) AS AvanceMMAntes
        FROM #VentasGlobal V
        INNER JOIN #RutasGlobal R
            ON R.NUR = V.NUR
        GROUP BY R.CLO
    )
    SELECT
        R.CLO,
        CAST(CEILING(SUM(COALESCE(M.MetaVolumen, 0))) AS INT)
            AS MetaVolumen,
        CAST(CEILING(SUM(COALESCE(M.ObjAlDia, 0))) AS INT)
            AS ObjAlDia,
        CAST(SUM(COALESCE(A.AvanceCLO, 0)) AS DECIMAL(18,3))
            AS AvanceCLO,
        CAST(
            CASE WHEN MAX(E.AvanceGTPMes) - MAX(ME.MetaGTP) > 0
                 THEN MAX(E.AvanceGTPMes) - MAX(ME.MetaGTP)
                 ELSE 0 END
            -
            CASE WHEN MAX(E.AvanceGTPAntes) - MAX(ME.MetaGTP) > 0
                 THEN MAX(E.AvanceGTPAntes) - MAX(ME.MetaGTP)
                 ELSE 0 END
            AS DECIMAL(18,3)
        ) AS InyeccionGTP,
        CAST(
            CASE WHEN MAX(E.AvanceMMMes) - MAX(ME.MetaMM) > 0
                 THEN MAX(E.AvanceMMMes) - MAX(ME.MetaMM)
                 ELSE 0 END
            -
            CASE WHEN MAX(E.AvanceMMAntes) - MAX(ME.MetaMM) > 0
                 THEN MAX(E.AvanceMMAntes) - MAX(ME.MetaMM)
                 ELSE 0 END
            AS DECIMAL(18,3)
        ) AS InyeccionMM
    FROM #RutasGlobal R
    LEFT JOIN MetasRuta M
        ON M.NUR = R.NUR
    LEFT JOIN AvancesRuta A
        ON A.NUR = R.NUR
    LEFT JOIN Excedentes E
        ON E.CLO = R.CLO
    LEFT JOIN MetasEspeciales ME
        ON ME.CLO = R.CLO
    WHERE R.NUR <> '1125632M29'
    GROUP BY R.CLO
    ORDER BY R.CLO;

    DROP TABLE #VentasGlobal;
    DROP TABLE #RutasGlobal;
END;
GO
