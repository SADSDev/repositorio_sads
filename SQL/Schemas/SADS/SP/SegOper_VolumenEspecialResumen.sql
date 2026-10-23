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
    -- Definir inicio del periodo (siempre frecuencia mensual)
    -------------------------------------------------------
    SET @FechaInicioPeriodo=DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)

    -------------------------------------------------------
    -- Proceso
    -------------------------------------------------------
    ;WITH metas AS (
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

    ventas_filtradas AS
    (
        SELECT
            VD.NUR,
            A.Agencia,
            VD.Cliente,
            VD.Cantidad,

            CASE
                WHEN GTP.Cliente IS NULL
                    THEN 0
                ELSE 1
            END AS EsGTP,

            CASE
                WHEN V.NUR IS NULL
                    THEN 0
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

            AND (
                @agencia IS NULL
                OR CHARINDEX(
                    ',' + CONVERT(VARCHAR(10), A.Agencia) + ',',
                    ',' + @agencia + ','
                ) > 0
            )

            AND
            (
                -- Venta GTP
                (
                    GTP.Cliente IS NOT NULL
                    AND EXISTS
                    (
                        SELECT 1
                        FROM metas M
                        WHERE M.Agencia = A.Agencia
                        AND M.Indicador = 'VOLUMEN GTP'
                    )
                )

                OR

                -- Venta Mayoreo
                (
                    V.NUR IS NOT NULL
                    AND EXISTS
                    (
                        SELECT 1
                        FROM metas M
                        WHERE M.Agencia = A.Agencia
                        AND M.Indicador = 'VOLUMEN MM'
                    )
                )
            )
    ),

    avances AS (
        SELECT
            CAST(SUM(CASE WHEN EsGTP = 1 THEN Cantidad ELSE 0 END) AS DECIMAL(10,3)) AS Avance_GTP,
            CAST(SUM(CASE WHEN EsMayoreo = 1 THEN Cantidad ELSE 0 END) AS DECIMAL(10,3)) AS Avance_MM
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
