CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_VolumenAgencias
(
    @fecha DATE,
    @agencia VARCHAR(200) = NULL,
    @zona VARCHAR(20) = NULL,
    @ruta VARCHAR(10) = NULL,
    @frecuencia INT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @agencia = NULLIF(
        REPLACE(LTRIM(RTRIM(@agencia)), ' ', ''),
        ''
    );

    IF @frecuencia NOT IN (1, 2, 3)
    BEGIN
        THROW 50001, 'La frecuencia debe ser 1, 2 o 3.', 1;
    END;

    DECLARE @fecha_inicio DATE;

    DECLARE @fecha_fin DATE

    /*
    Frecuencia:
    1 = únicamente el día consultado
    2 = lunes de la semana hasta @fecha
    3 = primer día del mes hasta @fecha
    */
    SET @fecha_inicio =
        CASE @frecuencia
            WHEN 1 THEN @fecha

            WHEN 2 THEN
                CASE
                    WHEN DATEADD(
                            DAY,
                            -(DATEDIFF(DAY, CONVERT(DATE, '19000101'), @fecha) % 7),
                            @fecha
                        ) < DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
                    THEN DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)

                    ELSE DATEADD(
                            DAY,
                            -(DATEDIFF(DAY, CONVERT(DATE, '19000101'), @fecha) % 7),
                            @fecha
                        )
                END

            WHEN 3 THEN
                DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
        END;

    SET @fecha_fin =
        CASE @frecuencia
            WHEN 1 THEN @fecha

            WHEN 2 THEN
                CASE
                    WHEN DATEADD(
                            DAY,
                            6 - (DATEDIFF(DAY, CONVERT(DATE, '19000101'), @fecha) % 7),
                            @fecha
                        ) > EOMONTH(@fecha)
                    THEN EOMONTH(@fecha)

                    ELSE DATEADD(
                            DAY,
                            6 - (DATEDIFF(DAY, CONVERT(DATE, '19000101'), @fecha) % 7),
                            @fecha
                        )
                END

            WHEN 3 THEN
                EOMONTH(@fecha)
        END;

    ;WITH Rutas AS
    (
        SELECT DISTINCT
            V.NUR,
            A.Agencia,
            A.CLO,
            V.Grupo AS Zona
        FROM PWST.CATALOGOS_Rutas_Evaluables V
        INNER JOIN PWST.CATALOGOS_Agencias A
            ON V.NUR LIKE A.Clave_NUR + '%'
        WHERE
            V.NUR <> '1125632M29'
            AND (
                @agencia IS NULL
                OR CHARINDEX(
                    ',' + CONVERT(VARCHAR(10), A.Agencia) + ',',
                    ',' + @agencia + ','
                ) > 0
            )
            AND (@zona IS NULL OR V.Grupo = @zona)
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
                ) = @ruta
            )
    ),

    RutasVentas AS
    (
        SELECT DISTINCT
            V.NUR,
            A.Agencia,
            A.CLO,
            V.Grupo AS Zona
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
            AND (@zona IS NULL OR V.Grupo = @zona)
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
                ) = @ruta
            )
    ),

    Metas AS
    (
        SELECT
            M.NUR,

            SUM(
                CASE
                    WHEN M.Fecha BETWEEN @fecha_inicio AND @fecha_fin
                    THEN M.Valor_Meta
                    ELSE 0
                END
            ) AS MetaVolumen,

            SUM(
                CASE
                    WHEN M.Fecha BETWEEN @fecha_inicio AND @fecha
                    THEN M.Valor_Meta
                    ELSE 0
                END
            ) AS ObjAlDia

        FROM PWST.SADS_SegOper_Metas M

        INNER JOIN Rutas R
            ON R.NUR = M.NUR

        WHERE
            UPPER(M.Indicador) = 'VOLUMEN'
            AND M.Fecha BETWEEN @fecha_inicio AND @fecha_fin

        GROUP BY
            M.NUR
    ),

    MetasEspecialesCLO AS
    (
        SELECT
            X.CLO,
            MAX(X.MetaGTP) AS MetaGTP,
            MAX(X.MetaMM) AS MetaMM
        FROM
        (
            SELECT DISTINCT
                R.CLO,
                R.Agencia,

                COALESCE(
                    (
                        SELECT SUM(M.Valor_Meta)
                        FROM PWST.SADS_SegOper_MetasAgencia M
                        WHERE
                            M.Agencia = R.Agencia
                            AND M.Mes =
                                DATEFROMPARTS(
                                    YEAR(@fecha),
                                    MONTH(@fecha),
                                    1
                                )
                            AND UPPER(LTRIM(RTRIM(M.Indicador)))
                                = 'VOLUMEN GTP'
                    ),
                    0
                ) AS MetaGTP,

                COALESCE(
                    (
                        SELECT SUM(M.Valor_Meta)
                        FROM PWST.SADS_SegOper_MetasAgencia M
                        WHERE
                            M.Agencia = R.Agencia
                            AND M.Mes =
                                DATEFROMPARTS(
                                    YEAR(@fecha),
                                    MONTH(@fecha),
                                    1
                                )
                            AND UPPER(LTRIM(RTRIM(M.Indicador)))
                                = 'VOLUMEN MM'
                    ),
                    0
                ) AS MetaMM

            FROM RutasVentas R
        ) X

        GROUP BY
            X.CLO
    ),

    Ventas AS
    (
        SELECT
            VD.NUR,
            VD.Fecha,
            VD.Cliente,
            VD.Cantidad,

            CASE
                WHEN GTP.Cliente IS NULL THEN 0
                ELSE 1
            END AS EsGTP,

            CASE
                WHEN EXISTS
                (
                    SELECT 1
                    FROM PWST.CATALOGOS_Vendedores V
                    WHERE
                        V.NUR = VD.NUR
                        AND V.Grupo = 'MAYOREO'
                )
                THEN 1
                ELSE 0
            END AS EsMM
        FROM PWST.POWERSTREET_Venta_Diaria VD
        INNER JOIN RutasVentas R
            ON R.NUR = VD.NUR
        LEFT JOIN PWST.CATALOGOS_Clientes_GTP GTP
            ON GTP.Cliente = VD.Cliente
        WHERE
            VD.Fecha BETWEEN
                DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
                AND @fecha
    ),

    Avances AS
    (
        SELECT
            NUR,

            SUM(
                CASE
                    WHEN EsGTP = 0
                        AND EsMM = 0
                    THEN Cantidad
                    ELSE 0
                END
            ) AS AvanceRuta,

            SUM(
                CASE
                    WHEN EsGTP = 1
                    THEN Cantidad
                    ELSE 0
                END
            ) AS InyeccionGTP,

            SUM(
                CASE
                    WHEN EsMM = 1
                    THEN Cantidad
                    ELSE 0
                END
            ) AS InyeccionMM

        FROM Ventas
        WHERE Fecha BETWEEN @fecha_inicio AND @fecha

        GROUP BY
            NUR
    ),

    ExcedentesCLO AS
    (
        SELECT
            R.CLO,

            SUM(
                CASE
                    WHEN V.EsGTP = 1
                    THEN V.Cantidad
                    ELSE 0
                END
            ) AS AvanceGTPMes,

            SUM(
                CASE
                    WHEN V.EsGTP = 1
                        AND V.Fecha < @fecha_inicio
                    THEN V.Cantidad
                    ELSE 0
                END
            ) AS AvanceGTPAntesPeriodo,

            SUM(
                CASE
                    WHEN V.EsMM = 1
                    THEN V.Cantidad
                    ELSE 0
                END
            ) AS AvanceMMMes,

            SUM(
                CASE
                    WHEN V.EsMM = 1
                        AND V.Fecha < @fecha_inicio
                    THEN V.Cantidad
                    ELSE 0
                END
            ) AS AvanceMMAntesPeriodo

        FROM Ventas V

        INNER JOIN RutasVentas R
            ON R.NUR = V.NUR

        GROUP BY
            R.CLO
    ),

    Resultado AS
    (
        SELECT
            R.NUR,
            R.CLO,

            CAST(
                CEILING(COALESCE(M.MetaVolumen, 0) * 1000) / 1000.0
                AS DECIMAL(18,3)
            ) AS MetaVolumen,

            CAST(
                COALESCE(A.AvanceRuta, 0)
                AS DECIMAL(18,3)
            ) AS AvanceCLO,

            CAST(
                CEILING(COALESCE(M.ObjAlDia, 0) * 1000) / 1000.0
                AS DECIMAL(18,3)
            ) AS ObjAlDia

        FROM Metas M

        INNER JOIN Rutas R
            ON R.NUR = M.NUR

        LEFT JOIN Avances A
            ON A.NUR = M.NUR
    )

    SELECT
        R.CLO,

        CAST(
            CEILING(SUM(R.MetaVolumen))
            AS INT
        ) AS MetaVolumen,

        CAST(
            CEILING(SUM(R.ObjAlDia))
            AS INT
        ) AS ObjAlDia,

        CAST(
            SUM(R.AvanceCLO)
            AS DECIMAL(18,3)
        ) AS AvanceCLO,

        CAST(
            CASE
                WHEN
                    MAX(E.AvanceGTPMes)
                    - MAX(ME.MetaGTP) > 0
                THEN
                    MAX(E.AvanceGTPMes)
                    - MAX(ME.MetaGTP)
                ELSE 0
            END
            -
            CASE
                WHEN
                    MAX(E.AvanceGTPAntesPeriodo)
                    - MAX(ME.MetaGTP) > 0
                THEN
                    MAX(E.AvanceGTPAntesPeriodo)
                    - MAX(ME.MetaGTP)
                ELSE 0
            END
            AS DECIMAL(18,3)
        ) AS InyeccionGTP,

        CAST(
            CASE
                WHEN
                    MAX(E.AvanceMMMes)
                    - MAX(ME.MetaMM) > 0
                THEN
                    MAX(E.AvanceMMMes)
                    - MAX(ME.MetaMM)
                ELSE 0
            END
            -
            CASE
                WHEN
                    MAX(E.AvanceMMAntesPeriodo)
                    - MAX(ME.MetaMM) > 0
                THEN
                    MAX(E.AvanceMMAntesPeriodo)
                    - MAX(ME.MetaMM)
                ELSE 0
            END
            AS DECIMAL(18,3)
        ) AS InyeccionMM,

        CAST(
            SUM(R.AvanceCLO)
            +
            (
                CASE
                    WHEN MAX(E.AvanceGTPMes) - MAX(ME.MetaGTP) > 0
                    THEN MAX(E.AvanceGTPMes) - MAX(ME.MetaGTP)
                    ELSE 0
                END
                -
                CASE
                    WHEN MAX(E.AvanceGTPAntesPeriodo) - MAX(ME.MetaGTP) > 0
                    THEN MAX(E.AvanceGTPAntesPeriodo) - MAX(ME.MetaGTP)
                    ELSE 0
                END
            )
            +
            (
                CASE
                    WHEN MAX(E.AvanceMMMes) - MAX(ME.MetaMM) > 0
                    THEN MAX(E.AvanceMMMes) - MAX(ME.MetaMM)
                    ELSE 0
                END
                -
                CASE
                    WHEN MAX(E.AvanceMMAntesPeriodo) - MAX(ME.MetaMM) > 0
                    THEN MAX(E.AvanceMMAntesPeriodo) - MAX(ME.MetaMM)
                    ELSE 0
                END
            )
            AS DECIMAL(18,3)
        ) AS AvanceTotal
    FROM Resultado R
    LEFT JOIN ExcedentesCLO E
        ON E.CLO = R.CLO
    LEFT JOIN MetasEspecialesCLO ME
        ON ME.CLO = R.CLO
    GROUP BY
        R.CLO
    ORDER BY
        R.CLO;
END;
GO 
