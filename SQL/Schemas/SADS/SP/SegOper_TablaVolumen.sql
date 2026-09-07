CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_TablaVolumen
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

    Ventas AS
    (
        SELECT
            VD.NUR,
            VD.Cliente,
            VD.Cantidad,
            CASE
                WHEN GTP.Cliente IS NULL THEN 0
                ELSE 1
            END AS EsGTP
        FROM PWST.POWERSTREET_Venta_Diaria VD
        INNER JOIN Metas M
            ON M.NUR = VD.NUR
        LEFT JOIN PWST.CATALOGOS_Clientes_GTP GTP
            ON GTP.Cliente = VD.Cliente
        WHERE
            VD.Fecha BETWEEN @fecha_inicio AND @fecha
    ),

    Avances AS
    (
        SELECT
            NUR,
            SUM(CASE WHEN EsGTP = 0 THEN Cantidad ELSE 0 END) AS AvanceRuta,
            SUM(CASE WHEN EsGTP = 1 THEN Cantidad ELSE 0 END) AS InyeccionGTP
        FROM Ventas
        GROUP BY
            NUR
    ),

    Resultado AS
    (
        SELECT
            R.NUR,
            R.CLO,

            -- Se conserva precisión de tres decimales para coincidir
            -- con la estructura mostrada.
            CAST(
                CEILING(COALESCE(M.MetaVolumen, 0) * 1000) / 1000.0
                AS INT
            ) AS MetaVolumen,

            CAST(COALESCE(A.AvanceRuta, 0) AS DECIMAL(18, 3))
                AS AvanceRuta,

            CAST(COALESCE(A.InyeccionGTP, 0) AS DECIMAL(18, 3))
                AS InyeccionGTP,

            CAST(
                COALESCE(A.AvanceRuta, 0)
                + COALESCE(A.InyeccionGTP, 0)
                AS DECIMAL(18, 3)
            ) AS AvanceTotal,

            CAST(
                CEILING(COALESCE(M.ObjAlDia,0) * 1000) / 1000.0
                AS INT
            ) AS ObjAlDia
        FROM Metas M
        INNER JOIN Rutas R
            ON R.NUR = M.NUR
        LEFT JOIN Avances A
            ON A.NUR = M.NUR
    )

    SELECT
        NUR,
        CLO,
        MetaVolumen,
        AvanceRuta,
        InyeccionGTP,
        AvanceTotal,
        ObjAlDia,
        CAST(
            ROUND(
                AvanceRuta / NULLIF(MetaVolumen,0),
                4
            ) AS DECIMAL(10,4)
        ) AS AlcanceRuta,
        CAST(
            ROUND(
                AvanceTotal / NULLIF(MetaVolumen, 0),
                4
            ) AS DECIMAL(10, 4)
        ) AS AlcanceTotal
    FROM Resultado
    ORDER BY
        NUR;
END;
GO
