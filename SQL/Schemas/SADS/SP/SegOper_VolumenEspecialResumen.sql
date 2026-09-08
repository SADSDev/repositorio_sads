CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_VolumenEspecialResumen
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
    WITH metas AS (
        SELECT
            A.Agencia,
            A.Indicador,
            A.Valor_Meta
        FROM PWST.SADS_SegOper_MetasAgencia A
        WHERE (
            @agencia IS NULL
            OR CHARINDEX(
                ',' + CONVERT(VARCHAR(10), A.Agencia) + ',',
                ',' + @agencia + ','
            ) > 0
        )
        AND A.Mes = DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
        AND A.Indicador IN ('VOLUMEN GTP', 'VOLUMEN MM')
    ),

    ventas_filtradas AS (
        SELECT
            VD.NUR,
            VD.Cliente,
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

        LEFT JOIN PWST.CATALOGOS_Vendedores V
            ON V.NUR = VD.NUR
            AND V.Grupo = 'MAYOREO'
            AND (
                @agencia IS NULL
                OR CHARINDEX(
                    ',' + CONVERT(VARCHAR(10), V.Agencia) + ',',
                    ',' + @agencia + ','
                ) > 0
            )

        WHERE VD.Fecha BETWEEN @FechaInicioPeriodo AND @fecha
    ),

    avances AS (
        SELECT
            SUM(CASE WHEN EsGTP = 1 THEN Cantidad ELSE 0 END) AS Avance_GTP,
            SUM(CASE WHEN EsMayoreo = 1 THEN Cantidad ELSE 0 END) AS Avance_MM
        FROM ventas_filtradas
    )

    SELECT
        M.Indicador,
        CAST(SUM(M.Valor_Meta) AS INT)  AS Valor_Meta,
        CASE
            WHEN M.Indicador = 'VOLUMEN GTP'
                THEN A.Avance_GTP
            WHEN M.Indicador = 'VOLUMEN MM'
                THEN A.Avance_MM
        END AS Avance
    FROM metas M
    CROSS JOIN avances A
    GROUP BY
        M.Indicador,
        A.Avance_GTP,
        A.Avance_MM;
END;
GO
