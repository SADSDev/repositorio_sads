CREATE OR ALTER PROCEDURE SADS.SegOper_TablaIto
(
    @fecha DATE,
    @agencia INT = NULL,
    @zona VARCHAR(20) = NULL,
    @ruta VARCHAR(10) = NULL,
    @frecuencia INT
)
AS
BEGIN
    SET NOCOUNT ON;

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
            A.Agencia,
            A.CLO,
            V.Grupo AS Zona
        FROM CATALOGOS.Rutas_Evaluables V

        INNER JOIN CATALOGOS.Agencias A
            ON V.NUR LIKE A.Clave_NUR + '%'

        WHERE
            V.NUR <> '1125632M29'
            AND (@agencia IS NULL OR A.Agencia = @agencia)
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

    ito_filtrado AS
    (
        SELECT *
        FROM
        (
            SELECT
                A.*,
                ROW_NUMBER() OVER
                (
                    PARTITION BY
                        A.NUR,
                        A.Fecha,
                        A.Cliente,
                        A.Apertura
                    ORDER BY A.Fecha
                ) AS rn
            FROM PowerStreet.ITO_Detallado A

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
            Fecha
    ),

    tabla_ito AS
    (
        SELECT
            NUR,
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
        GROUP BY NUR
    )

    SELECT *
    FROM tabla_ito
    ORDER BY NUR ASC;

END;
GO