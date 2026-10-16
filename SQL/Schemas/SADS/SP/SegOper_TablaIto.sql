CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_TablaIto
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

    -------------------------------------------------------
    -- Declaración de variables
    -------------------------------------------------------

    DECLARE @FechaInicioPeriodo DATE;

    -------------------------------------------------------
    -- Definir inicio del periodo según frecuencia
    -------------------------------------------------------

    IF @frecuencia = 1
    BEGIN
        -- Diario: solamente la fecha consultada
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
        -- Mensual: primer día del mes de @fecha
        SET @FechaInicioPeriodo =
            DATEFROMPARTS(
                YEAR(@fecha),
                MONTH(@fecha),
                1
            );
    END;

    -------------------------------------------------------
    -- Proceso
    -------------------------------------------------------

    ;WITH Rutas AS
    (
        SELECT DISTINCT
            V.NUR,
            V.Grupo,
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

    ito_filtrado AS
    (
        SELECT *
        FROM
        (
            SELECT
                A.*,
                R.CLO AS CLO_Ruta,
                R.Grupo AS Grupo_Ruta,
                ROW_NUMBER() OVER
                (
                    PARTITION BY
                        A.NUR,
                        A.Fecha,
                        A.Cliente,
                        A.Apertura
                    ORDER BY A.Fecha
                ) AS rn
            FROM PWST.POWERSTREET_ITO_Detallado A

            INNER JOIN Rutas R
                ON A.NUR = R.NUR

            WHERE
                A.Vendedor NOT LIKE '%Supervisor%'
                AND A.Vendedor NOT LIKE '%CENSADOR PENDIENTE DE CONFIGURACION%'
                AND A.Vendedor NOT LIKE '%VENDEDOR MOSTRADOR%'
                AND A.Vendedor NOT LIKE '%Ruta Espejo%'
                AND A.Fecha >= @FechaInicioPeriodo
                AND A.Fecha <= @fecha
        ) X
        WHERE rn = 1
    ),

    ito_por_dia AS
    (
        SELECT
            NUR,
            Grupo_Ruta AS Grupo,
            CLO_Ruta AS CLO,
            Fecha,
            MAX(Visitas_Totales) AS Visitas_Totales,
            MAX(Visitas_Geocerca) AS Visitas_Geocerca,
            MAX(Visitas_Unicas_ITO) AS Visitas_Ito,
            SUM(
                CASE
                    WHEN Apertura = 'GPS'
                    THEN 1
                    ELSE 0
                END
            ) AS Aperturas_GPS
        FROM ito_filtrado
        GROUP BY
            NUR,
            Grupo_Ruta,
            CLO_Ruta,
            Fecha
    ),

    tabla_ito AS
    (
        SELECT
            NUR,
            Grupo,
            CLO,
            SUM(Visitas_Totales) AS Visitas_Totales,

            CAST(
                SUM(Visitas_Geocerca) * 1.0
                / NULLIF(SUM(Visitas_Totales), 0)
                AS DECIMAL(10,4)
            ) AS Geocerca,

            CAST(
                SUM(Visitas_Ito) * 1.0
                / NULLIF(SUM(Visitas_Totales), 0)
                AS DECIMAL(10,4)
            ) AS Apego_ITO,

            CAST(
                SUM(Aperturas_GPS) * 1.0
                / NULLIF(SUM(Visitas_Totales), 0)
                AS DECIMAL(10,4)
            ) AS GPS

        FROM ito_por_dia
        GROUP BY
            NUR,
            Grupo,
            CLO
    )

    SELECT *
    FROM tabla_ito
    ORDER BY NUR ASC;

END;
GO
