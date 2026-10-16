CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_TablaVolumenResumen
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

    /*
       Se materializan las ventas del mes una sola vez para reutilizarlas
       tanto en el avance normal como en los volúmenes especiales.
    */
    SELECT
        VD.NUR,
        VD.Fecha,
        VD.Cantidad,
        A.Agencia,
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM PWST.CATALOGOS_Clientes_GTP GTP
                WHERE GTP.Cliente = VD.Cliente
            )
            THEN 1
            ELSE 0
        END AS EsGTP,
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM PWST.CATALOGOS_Vendedores V
                WHERE V.NUR = VD.NUR
                  AND V.Grupo = 'MAYOREO'
            )
            THEN 1
            ELSE 0
        END AS EsMayoreo
    INTO #VentasMes
    FROM PWST.POWERSTREET_Venta_Diaria VD
    LEFT JOIN PWST.CATALOGOS_Agencias A
        ON LEFT(
            VD.NUR,
            PATINDEX('%[A-Z]%', VD.NUR) - 1
        ) = A.Clave_NUR
    WHERE
        VD.Fecha >= DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
        AND VD.Fecha < DATEADD(DAY, 1, @fecha)
        AND (
            @agencia IS NULL
            OR CHARINDEX(
                ',' + CONVERT(VARCHAR(10), A.Agencia) + ',',
                ',' + @agencia + ','
            ) > 0
        );

    ;WITH Rutas AS
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
            V.Evaluable=1
            AND (
                @agencia IS NULL
                OR CHARINDEX(
                    ',' + CONVERT(VARCHAR(10), A.Agencia) + ',',
                    ',' + @agencia + ','
                ) > 0
            )
            AND (@zona IS NULL OR EXISTS (SELECT 1 FROM STRING_SPLIT(@zona, CHAR(44)) Z WHERE LTRIM(RTRIM(Z.value)) = V.Grupo))
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
                ) IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@ruta, CHAR(44)))
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

    RutasVentas AS
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
            V.Evaluable=1 OR V.Grupo='MAYOREO'
            AND(
                @agencia IS NULL
                OR CHARINDEX(
                    ',' + CONVERT(VARCHAR(10), A.Agencia) + ',',
                    ',' + @agencia + ','
                ) > 0
            )
            AND (@zona IS NULL OR EXISTS (SELECT 1 FROM STRING_SPLIT(@zona, CHAR(44)) Z WHERE LTRIM(RTRIM(Z.value)) = V.Grupo))
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
                ) IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@ruta, CHAR(44)))
            )
    ),

    Ventas AS
    (
        SELECT
            VD.NUR,
            VD.Fecha,
            VD.Cantidad,
            VD.EsGTP,
            VD.EsMayoreo
        FROM #VentasMes VD
        INNER JOIN RutasVentas R
            ON R.NUR = VD.NUR
    ),

    Avances AS
    (
        SELECT
            NUR,

            SUM(
                CASE
                    WHEN EsGTP = 0
                        AND EsMayoreo = 0
                        AND Fecha BETWEEN @fecha_inicio AND @fecha
                    THEN Cantidad
                    ELSE 0
                END
            ) AS AvanceRuta
        FROM Ventas
        GROUP BY NUR
    ),

    MetasEspeciales AS
    (
        SELECT
            M.Agencia,
            COALESCE(SUM(CASE
                WHEN UPPER(LTRIM(RTRIM(M.Indicador))) = 'VOLUMEN GTP'
                THEN M.Valor_Meta ELSE 0
            END), 0) AS MetaGTP,
            COALESCE(SUM(CASE
                WHEN UPPER(LTRIM(RTRIM(M.Indicador))) = 'VOLUMEN MM'
                THEN M.Valor_Meta ELSE 0
            END), 0) AS MetaMM
        FROM PWST.SADS_SegOper_MetasAgencia M
        WHERE
            M.Mes = DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
            AND UPPER(LTRIM(RTRIM(M.Indicador))) IN ('VOLUMEN GTP', 'VOLUMEN MM')
            AND (
                @agencia IS NULL
                OR CHARINDEX(
                    ',' + CONVERT(VARCHAR(10), M.Agencia) + ',',
                    ',' + @agencia + ','
                ) > 0
            )
        GROUP BY M.Agencia
    ),

    AvancesEspeciales AS
    (
        SELECT
            VD.Agencia,
            COALESCE(SUM(CASE
                WHEN VD.EsGTP = 1 THEN VD.Cantidad
                ELSE 0
            END), 0) AS AvanceGTPMes,
            COALESCE(SUM(CASE
                WHEN VD.EsMayoreo = 1 THEN VD.Cantidad
                ELSE 0
            END), 0) AS AvanceMMMes,
            COALESCE(SUM(CASE
                WHEN VD.EsGTP = 1
                    AND VD.Fecha BETWEEN @fecha_inicio AND @fecha
                THEN VD.Cantidad ELSE 0
            END), 0) AS AvanceGTPPeriodo,
            COALESCE(SUM(CASE
                WHEN VD.EsMayoreo = 1
                    AND VD.Fecha BETWEEN @fecha_inicio AND @fecha
                THEN VD.Cantidad ELSE 0
            END), 0) AS AvanceMMPeriodo
        FROM #VentasMes VD
        GROUP BY VD.Agencia
    ),

    ExcedentesEspeciales AS
    (
        SELECT
            M.Agencia,
            CASE
                WHEN M.MetaGTP = 0 OR COALESCE(A.AvanceGTPMes, 0) > M.MetaGTP
                THEN CASE @frecuencia
                    WHEN 1 THEN COALESCE(A.AvanceGTPPeriodo, 0)
                    WHEN 2 THEN COALESCE(A.AvanceGTPPeriodo, 0)
                    WHEN 3 THEN COALESCE(A.AvanceGTPMes, 0) - M.MetaGTP
                END
                ELSE 0
            END AS ExcedenteGTP,
            CASE
                WHEN M.MetaMM = 0 OR COALESCE(A.AvanceMMMes, 0) > M.MetaMM
                THEN CASE @frecuencia
                    WHEN 1 THEN COALESCE(A.AvanceMMPeriodo, 0)
                    WHEN 2 THEN COALESCE(A.AvanceMMPeriodo, 0)
                    WHEN 3 THEN COALESCE(A.AvanceMMMes, 0) - M.MetaMM
                END
                ELSE 0
            END AS ExcedenteMM
        FROM MetasEspeciales M
        LEFT JOIN AvancesEspeciales A
            ON A.Agencia = M.Agencia
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
                AS DECIMAL(18, 3)
            ) AS MetaVolumen,

            CAST(COALESCE(A.AvanceRuta, 0) AS DECIMAL(18, 3))
                AS AvanceRuta,

            CAST(
                CEILING(COALESCE(M.ObjAlDia,0) * 1000) / 1000.0
                AS DECIMAL(18,3)
            ) AS ObjAlDia
        FROM Metas M
        INNER JOIN Rutas R
            ON R.NUR = M.NUR
        LEFT JOIN Avances A
            ON A.NUR = M.NUR
    )

    SELECT
        CAST(
            CEILING(SUM(R.MetaVolumen))
            AS INT
        ) AS MetaVolumen,

        CAST(
            SUM(R.AvanceRuta)
            AS DECIMAL(18,3)
        ) AS AvanceRuta,

        CAST(
            CEILING(SUM(R.ObjAlDia))
            AS INT
        ) AS ObjAlDia,

        CAST(COALESCE((
            SELECT SUM(ExcedenteGTP)
            FROM ExcedentesEspeciales
        ), 0) AS DECIMAL(18,3)) AS ExcedenteGTP,

        CAST(COALESCE((
            SELECT SUM(ExcedenteMM)
            FROM ExcedentesEspeciales
        ), 0) AS DECIMAL(18,3)) AS ExcedenteMM

    FROM Resultado R;

    DROP TABLE #VentasMes;
END;
GO 