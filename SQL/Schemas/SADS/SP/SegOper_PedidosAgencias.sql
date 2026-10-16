CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_PedidosAgencias
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

    DECLARE @AgruparPorGrupo BIT =
        CASE
            WHEN @agencia IS NOT NULL
                 AND CHARINDEX(',', @agencia) = 0
            THEN 1
            ELSE 0
        END;

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
            V.Grupo AS Zona,
            CASE
                WHEN @AgruparPorGrupo = 1 THEN V.Grupo
                ELSE A.CLO
            END AS Agrupador
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

    pedidos_filtrado AS
    (
        SELECT *
        FROM
        (
            SELECT
                A.*,
                R.Agencia,
                R.CLO,
                R.Agrupador,
                ROW_NUMBER() OVER
                (
                    PARTITION BY A.Orden
                    ORDER BY A.Fecha DESC
                ) AS rn
            FROM PWST.POWERSTREET_Fullfillment_Pedidos_PMM A

            INNER JOIN Rutas R
                ON A.NUR = R.NUR

            WHERE
                A.Fecha >= @FechaInicioPeriodo
                AND A.Fecha <= @fecha
        ) X
        WHERE rn = 1
    ),

    resumen AS
    (
        SELECT
            Agrupador,

            COUNT(Orden) AS Asignados,

            SUM(
                CASE
                    WHEN Cantidad_Entrega > 0
                    THEN 1
                    ELSE 0
                END
            ) AS Entregados,

            SUM(
                CASE
                    WHEN Cantidad_Orden > Cantidad_Entrega
                        AND Cantidad_Entrega > 0
                    THEN 1
                    ELSE 0
                END
            ) AS Incompletos,

            SUM(
                CASE
                    WHEN Status_Entrega = 'PENDIENTE'
                    THEN 1
                    ELSE 0
                END
            ) AS Pendientes,

            SUM(
                CASE
                    WHEN Status_Entrega = 'RECHAZADO'
                    THEN 1
                    ELSE 0
                END
            ) AS Rechazados,

            CAST(
                AVG(Fillrate) / 100.0
                AS DECIMAL(10,4)
            ) AS Fillrate,

            CAST(
                SUM((Fullfillment / 100) * Cantidad_Orden)
                / NULLIF(SUM(Cantidad_Orden), 0)
                AS DECIMAL(10,4)
            ) AS Fullfillment

        FROM pedidos_filtrado

        GROUP BY
            Agrupador
    )

    SELECT
        Agrupador AS CLO,
        Asignados,
        Entregados,
        Incompletos,
        Pendientes,
        Rechazados,
        Fillrate,
        Fullfillment
    FROM resumen
    ORDER BY Agrupador;

END;
GO
