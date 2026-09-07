CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_VolumenEspecialAgencias
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

    IF @zona IS NOT NULL AND @zona <> 'MAYOREO'
        RETURN;

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
            DATEFROMPARTS(
                YEAR(@fecha),
                MONTH(@fecha),
                1
            );
    END

    ELSE
    BEGIN
        THROW 50001, 'La frecuencia debe ser 1, 2 o 3.', 1;
    END;

    -------------------------------------------------------
    -- Proceso
    -------------------------------------------------------

    ;WITH metas AS
    (
        SELECT
            A.CLO,
            M.Agencia,
            M.Indicador,
            M.Valor_Meta
        FROM PWST.SADS_SegOper_MetasAgencia M

        LEFT JOIN PWST.CATALOGOS_Agencias A
            ON M.Agencia = A.Agencia

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
            AND M.Indicador IN (
                'VOLUMEN GTP',
                'VOLUMEN MM'
            )
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
    ),

    avances AS
    (
        SELECT
            Agencia,

            SUM(
                CASE
                    WHEN EsGTP = 1
                        THEN Cantidad
                    ELSE 0
                END
            ) AS Avance_GTP,

            SUM(
                CASE
                    WHEN EsMayoreo = 1
                        THEN Cantidad
                    ELSE 0
                END
            ) AS Avance_MM

        FROM ventas_filtradas

        GROUP BY Agencia
    ),

    resultado AS
    (
        SELECT
            M.Agencia,
            M.CLO,
            M.Indicador,
            CAST(M.Valor_Meta AS INT) AS Valor_Meta,

            CASE
                WHEN M.Indicador = 'VOLUMEN GTP'
                    THEN ISNULL(A.Avance_GTP, 0)

                WHEN M.Indicador = 'VOLUMEN MM'
                    THEN ISNULL(A.Avance_MM, 0)
            END AS Avance

        FROM metas M

        LEFT JOIN avances A
            ON A.Agencia = M.Agencia
    )

    -------------------------------------------------------
    -- Una fila por agencia
    -------------------------------------------------------

    SELECT
        Agencia,
        MAX(CLO) AS CLO,

        ---------------------------------------------------
        -- GTP
        ---------------------------------------------------

        MAX(
            CASE
                WHEN Indicador = 'VOLUMEN GTP'
                    THEN Valor_Meta
            END
        ) AS Meta_GTP,

        CAST(
            MAX(
                CASE
                    WHEN Indicador = 'VOLUMEN GTP'
                        THEN Avance
                END
            ) 
            AS DECIMAL(10,3)
        ) AS Avance_GTP,

        CAST(
            MAX(
                CASE
                    WHEN Indicador = 'VOLUMEN GTP'
                        THEN Avance * 1.0
                             / NULLIF(Valor_Meta, 0)
                END
            )
            AS DECIMAL(10,4)
        ) AS Alcance_GTP,

        CAST(
            MAX(
                CASE
                    WHEN Indicador = 'VOLUMEN GTP'
                        THEN
                            CASE
                                WHEN Avance > Valor_Meta
                                    THEN Avance - Valor_Meta
                                ELSE 0
                            END
                END
            )
            AS DECIMAL(10,3)
        ) AS Excedente_GTP,
        ---------------------------------------------------
        -- Medio Mayoreo
        ---------------------------------------------------

        MAX(
            CASE
                WHEN Indicador = 'VOLUMEN MM'
                    THEN Valor_Meta
            END
        ) AS Meta_MM,

        CAST(
            MAX(
                CASE
                    WHEN Indicador = 'VOLUMEN MM'
                        THEN Avance
                END
            )
            AS DECIMAL(10,3)
        ) AS Avance_MM,

        CAST(
            MAX(
                CASE
                    WHEN Indicador = 'VOLUMEN MM'
                        THEN Avance * 1.0
                             / NULLIF(Valor_Meta, 0)
                END
            )
            AS DECIMAL(10,4)
        ) AS Alcance_MM,

        CAST(
            MAX(
                CASE
                    WHEN Indicador = 'VOLUMEN MM'
                        THEN
                            CASE
                                WHEN Avance > Valor_Meta
                                    THEN Avance - Valor_Meta
                                ELSE 0
                            END
                END
            )
            AS DECIMAL(10,3) 
        ) AS Excedente_MM
    FROM resultado

    GROUP BY
        Agencia

    ORDER BY
        Agencia;

END;
GO