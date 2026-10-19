CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_VolumenEspecialAgencias
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

    SET @agencia = NULLIF(
        REPLACE(LTRIM(RTRIM(@agencia)), ' ', ''),
        ''
    );

    SET @zona = NULLIF(LTRIM(RTRIM(@zona)), '');
    SET @ruta = NULLIF(LTRIM(RTRIM(@ruta)), '');

    DECLARE @UnaAgencia BIT =
        CASE
            WHEN @agencia IS NOT NULL
                 AND CHARINDEX(',', @agencia) = 0
            THEN 1
            ELSE 0
        END;

    DECLARE @FechaInicioPeriodo DATE;

    IF @frecuencia = 1
    BEGIN
        SET @FechaInicioPeriodo = @fecha;
    END
    ELSE IF @frecuencia = 2
    BEGIN
        SET @FechaInicioPeriodo =
            CASE
                WHEN DATEADD(
                        DAY,
                        -((DATEDIFF(DAY, '19000101', @fecha)) % 7),
                        @fecha
                     ) < DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
                THEN DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
                ELSE DATEADD(
                        DAY,
                        -((DATEDIFF(DAY, '19000101', @fecha)) % 7),
                        @fecha
                     )
            END;
    END
    ELSE IF @frecuencia = 3
    BEGIN
        SET @FechaInicioPeriodo =
            DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1);
    END
    ELSE
    BEGIN
        THROW 50001, 'La frecuencia debe ser 1, 2 o 3.', 1;
    END;

    ;WITH RutasSector AS
    (
        SELECT DISTINCT
            V.NUR,
            A.Agencia,
            A.CLO,
            V.Grupo AS Zona
        FROM PWST.CATALOGOS_Vendedores V
        INNER JOIN PWST.CATALOGOS_Agencias A
            ON V.NUR LIKE A.Clave_NUR + '%'
        WHERE
            @UnaAgencia = 1
            AND CHARINDEX(
                ',' + CONVERT(VARCHAR(10), A.Agencia) + ',',
                ',' + @agencia + ','
            ) > 0
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
            )

        UNION

        SELECT DISTINCT
            V.NUR,
            A.Agencia,
            A.CLO,
            V.Grupo AS Zona
        FROM PWST.CATALOGOS_Vendedores V
        INNER JOIN PWST.CATALOGOS_Agencias A
            ON V.NUR LIKE A.Clave_NUR + '%'
        WHERE
            @UnaAgencia = 1
            AND V.Grupo = 'MAYOREO'
            AND CHARINDEX(
                ',' + CONVERT(VARCHAR(10), A.Agencia) + ',',
                ',' + @agencia + ','
            ) > 0
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
            )
    ),

    MetasGlobales AS
    (
        SELECT
            M.Agencia,
            MAX(A.CLO) AS CLO,
            SUM(
                CASE
                    WHEN M.Indicador = 'VOLUMEN GTP'
                        THEN M.Valor_Meta
                    ELSE 0
                END
            ) AS Meta_GTP,
            SUM(
                CASE
                    WHEN M.Indicador = 'VOLUMEN MM'
                        THEN M.Valor_Meta
                    ELSE 0
                END
            ) AS Meta_MM
        FROM PWST.SADS_SegOper_MetasAgencia M
        LEFT JOIN PWST.CATALOGOS_Agencias A
            ON A.Agencia = M.Agencia
        WHERE
            (
                @agencia IS NULL
                OR CHARINDEX(
                    ',' + CONVERT(VARCHAR(10), M.Agencia) + ',',
                    ',' + @agencia + ','
                ) > 0
            )
            AND M.Mes = DATEFROMPARTS(
                YEAR(@fecha),
                MONTH(@fecha),
                1
            )
            AND M.Indicador IN ('VOLUMEN GTP', 'VOLUMEN MM')
        GROUP BY
            M.Agencia
    ),

    VentasGlobales AS
    (
        SELECT
            VD.NUR,
            A.Agencia,
            VD.Cantidad,
            CASE
                WHEN GTP.Cliente IS NULL THEN 0
                ELSE 1
            END AS EsGTP,
            CASE
                WHEN V.NUR IS NULL THEN 0
                ELSE 1
            END AS EsMayoreo
        FROM PWST.POWERSTREET_Venta_Diaria VD
        LEFT JOIN PWST.CATALOGOS_Clientes_GTP GTP
            ON GTP.Cliente = VD.Cliente
        LEFT JOIN PWST.CATALOGOS_Agencias A
            ON LEFT(
                VD.NUR,
                PATINDEX('%[A-Z]%', VD.NUR) - 1
            ) = A.Clave_NUR
        LEFT JOIN PWST.CATALOGOS_Vendedores V
            ON V.NUR = VD.NUR
            AND V.Grupo = 'MAYOREO'
        WHERE
            VD.Fecha BETWEEN @FechaInicioPeriodo AND @fecha
            AND
            (
                @agencia IS NULL
                OR CHARINDEX(
                    ',' + CONVERT(VARCHAR(10), A.Agencia) + ',',
                    ',' + @agencia + ','
                ) > 0
            )
    ),

    AvancesGlobales AS
    (
        SELECT
            Agencia,
            SUM(CASE WHEN EsGTP = 1 THEN Cantidad ELSE 0 END) AS Avance_GTP,
            SUM(CASE WHEN EsMayoreo = 1 THEN Cantidad ELSE 0 END) AS Avance_MM
        FROM VentasGlobales
        GROUP BY Agencia
    ),

    AvancesSector AS
    (
        SELECT
            R.Agencia,
            R.Zona,
            SUM(
                CASE
                    WHEN GTP.Cliente IS NOT NULL THEN VD.Cantidad
                    ELSE 0
                END
            ) AS Avance_GTP,
            SUM(
                CASE
                    WHEN V.NUR IS NOT NULL THEN VD.Cantidad
                    ELSE 0
                END
            ) AS Avance_MM
        FROM RutasSector R
        INNER JOIN PWST.POWERSTREET_Venta_Diaria VD
            ON VD.NUR = R.NUR
        LEFT JOIN PWST.CATALOGOS_Clientes_GTP GTP
            ON GTP.Cliente = VD.Cliente
        LEFT JOIN PWST.CATALOGOS_Vendedores V
            ON V.NUR = VD.NUR
            AND V.Grupo = 'MAYOREO'
        WHERE VD.Fecha BETWEEN @FechaInicioPeriodo AND @fecha
        GROUP BY
            R.Agencia,
            R.Zona
    ),

    Sectores AS
    (
        SELECT DISTINCT
            Agencia,
            Zona
        FROM RutasSector
    )

    SELECT
        S.Agencia,
        S.Zona AS CLO,
        CAST(M.Meta_GTP AS INT) AS Meta_GTP,
        CAST(COALESCE(ASec.Avance_GTP, 0) AS DECIMAL(10,3)) AS Avance_GTP,
        CAST(
            COALESCE(ASec.Avance_GTP, 0) * 1.0
            / NULLIF(AG.Avance_GTP, 0)
            AS DECIMAL(10,4)
        ) AS Alcance_GTP,
        CAST(
            CASE
                WHEN COALESCE(AG.Avance_GTP, 0) = 0 THEN 0
                ELSE
                    CASE
                        WHEN AG.Avance_GTP > M.Meta_GTP
                            THEN AG.Avance_GTP - M.Meta_GTP
                        ELSE 0
                    END
                    * COALESCE(ASec.Avance_GTP, 0) * 1.0
                    / NULLIF(AG.Avance_GTP, 0)
            END
            AS DECIMAL(10,3)
        ) AS Excedente_GTP,
        CAST(M.Meta_MM AS INT) AS Meta_MM,
        CAST(COALESCE(ASec.Avance_MM, 0) AS DECIMAL(10,3)) AS Avance_MM,
        CAST(
            COALESCE(ASec.Avance_MM, 0) * 1.0
            / NULLIF(M.Meta_MM, 0)
            AS DECIMAL(10,4)
        ) AS Alcance_MM,
        CAST(
            CASE
                WHEN COALESCE(AG.Avance_MM, 0) = 0 THEN 0
                ELSE
                    CASE
                        WHEN AG.Avance_MM > M.Meta_MM
                            THEN AG.Avance_MM - M.Meta_MM
                        ELSE 0
                    END
                    * COALESCE(ASec.Avance_MM, 0) * 1.0
                    / NULLIF(AG.Avance_MM, 0)
            END
            AS DECIMAL(10,3)
        ) AS Excedente_MM
    FROM Sectores S
    INNER JOIN MetasGlobales M
        ON M.Agencia = S.Agencia
    LEFT JOIN AvancesSector ASec
        ON ASec.Agencia = S.Agencia
        AND ASec.Zona = S.Zona
    LEFT JOIN AvancesGlobales AG
        ON AG.Agencia = S.Agencia
    WHERE @UnaAgencia = 1

    UNION ALL

    SELECT
        M.Agencia,
        M.CLO,
        CAST(M.Meta_GTP AS INT) AS Meta_GTP,
        CAST(COALESCE(AG.Avance_GTP, 0) AS DECIMAL(10,3)) AS Avance_GTP,
        CAST(
            AG.Avance_GTP * 1.0
            / NULLIF(M.Meta_GTP, 0)
            AS DECIMAL(10,4)
        ) AS Alcance_GTP,
        CAST(
            CASE
                WHEN AG.Avance_GTP > M.Meta_GTP
                    THEN AG.Avance_GTP - M.Meta_GTP
                ELSE 0
            END
            AS DECIMAL(10,3)
        ) AS Excedente_GTP,
        CAST(M.Meta_MM AS INT) AS Meta_MM,
        CAST(COALESCE(AG.Avance_MM, 0) AS DECIMAL(10,3)) AS Avance_MM,
        CAST(
            AG.Avance_MM * 1.0
            / NULLIF(M.Meta_MM, 0)
            AS DECIMAL(10,4)
        ) AS Alcance_MM,
        CAST(
            CASE
                WHEN AG.Avance_MM > M.Meta_MM
                    THEN AG.Avance_MM - M.Meta_MM
                ELSE 0
            END
            AS DECIMAL(10,3)
        ) AS Excedente_MM
    FROM MetasGlobales M
    LEFT JOIN AvancesGlobales AG
        ON AG.Agencia = M.Agencia
    WHERE @UnaAgencia = 0
    ORDER BY
        Agencia,
        CLO;
END;
GO
