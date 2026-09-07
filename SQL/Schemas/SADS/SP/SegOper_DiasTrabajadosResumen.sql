CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_DiasTrabajadosResumen
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
            c.Dias_Operativos,
            MIN(Dias_Trabajados) AS Dias_Trabajados
        FROM (
            SELECT
                i.NUR,
                SUM(i.Dias_Trabajados) AS Dias_Trabajados
            FROM PWST.POWERSTREET_Seguimiento_Indicadores i
            INNER JOIN rutas r
                ON i.NUR = r.NUR
            WHERE i.Fecha BETWEEN @FechaInicioPeriodo AND @fecha
            GROUP BY i.NUR
        ) d
        CROSS JOIN (
            SELECT
                SUM(CAST(Es_Habil AS int)) AS Dias_Operativos
            FROM PWST.CATALOGOS_Calendario
            WHERE Fecha BETWEEN @FechaInicioPeriodo AND @fecha
        ) c
        GROUP BY c.Dias_Operativos
    )

    SELECT*FROM dias_trabajados

END;
GO
