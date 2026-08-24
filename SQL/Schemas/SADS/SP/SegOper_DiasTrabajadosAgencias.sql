CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_DiasTrabajadosAgencias
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
        FROM PWST.CATALOGOS_Rutas_Evaluables V

        INNER JOIN PWST.CATALOGOS_Agencias A
            ON V.NUR LIKE A.Clave_NUR + '%'

        WHERE(
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

    dias_trabajados AS (
        SELECT
            c.Dias_Del_Mes,
            d.Agencia,
            d.CLO,
            MIN(d.Dias_Trabajados) AS Dias_Trabajados
        FROM (
            SELECT
                v.NUR,
                r.Agencia,
                r.CLO,
                COUNT(DISTINCT v.Fecha) AS Dias_Trabajados
            FROM PWST.POWERSTREET_Venta_Diaria v
            INNER JOIN rutas r
                ON v.NUR = r.NUR
            WHERE v.Fecha BETWEEN @FechaInicioPeriodo AND @fecha
            GROUP BY
                v.NUR,
                r.Agencia,
                r.CLO
        ) d
        CROSS JOIN (
            SELECT
                SUM(CAST(Es_Habil AS int)) AS Dias_Del_Mes
            FROM PWST.CATALOGOS_Calendario
            WHERE Fecha BETWEEN @FechaInicioPeriodo AND @fecha
        ) c
        GROUP BY
            c.Dias_Del_Mes,
            d.Agencia,
            d.CLO
    )

    SELECT
        Dias_Del_Mes,
        CLO,
        Dias_Trabajados
    FROM dias_trabajados
    ORDER BY Agencia ASC, CLO ASC;

END;
GO
