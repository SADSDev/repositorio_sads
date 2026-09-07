CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_TablaVisitasSupervisores
(
    @fecha DATE,
    @agencia VARCHAR(200)=NULL,
    @zona VARCHAR(20)=NULL,
    @ruta VARCHAR(20) = NULL,
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

    IF @frecuencia IN (1, 2, 3)
    BEGIN
        -- la fecha de inicio siempre será la misma
        SET @FechaInicioPeriodo = DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1);
    END

    ELSE
    BEGIN
        THROW 50001, 'La frecuencia debe ser 1, 2 o 3.', 1;
    END;

    -------------------------------------------------------
    -- Proceso
    -------------------------------------------------------

    ;WITH nurs AS
    (
        SELECT DISTINCT
            S.Codigo,
            S.NUR,
            S.Grupo,
            S.Agencia,
            A.CLO,
            A.Clave_NUR
        FROM PWST.CATALOGOS_Supervisores S
        INNER JOIN PWST.CATALOGOS_Agencias A
            ON A.Agencia = S.Agencia
        WHERE
            (
                @agencia IS NULL
                OR CHARINDEX(
                    ',' + CONVERT(VARCHAR(10), S.Agencia) + ',',
                    ',' + @agencia + ','
                ) > 0
            )
            AND
            (
                @zona IS NULL
                OR S.Grupo = @zona
            )
            AND
            (
                @ruta IS NULL
                OR CONCAT(
                    'R',
                    SUBSTRING(
                        S.NUR,
                        PATINDEX('%[A-Z]%', S.NUR) + 1,
                        LEN(S.NUR)
                    )
                ) = @ruta
            )
    ),

    ito_supervisores AS
    (
        SELECT
            t.NUR,
            t.Vendedor,
            n.CLO,
            n.Agencia,
            n.Grupo,
            t.Fecha,
            t.Cliente
        FROM
        (
            SELECT
                I.*,
                ROW_NUMBER() OVER
                (
                    PARTITION BY I.Cliente
                    ORDER BY I.Fecha DESC
                ) AS rn
            FROM PWST.POWERSTREET_ITO_Detallado I
            WHERE
                I.Vendedor LIKE '%Supervisor%'
                AND I.Fecha BETWEEN @FechaInicioPeriodo AND @fecha
        ) t

        INNER JOIN nurs n
            ON LEFT(
                t.NUR,
                PATINDEX('%[^0-9]%', t.NUR) - 1
            ) = n.Clave_NUR

            -- ESTE ES EL FILTRO QUE FALTABA
            AND LEFT(
                t.Vendedor,
                CHARINDEX(' -', t.Vendedor) - 1
            ) = n.Codigo

        WHERE
            t.rn = 1
    )

    SELECT
        t.Vendedor,
        t.CLO,
        CAST(s.Valor_Meta AS INT) AS Valor_Meta,
        COUNT(DISTINCT t.Cliente) AS Total_Visitas,
        CAST(COUNT(DISTINCT t.Cliente)/s.Valor_Meta AS DECIMAL(10,4)) AS Alcance
    FROM ito_supervisores t
    INNER JOIN PWST.SADS_SegOper_MetasSupervisor s
        ON s.Agencia = t.Agencia
        AND s.Indicador = 'VISITAS'
    GROUP BY
        t.Vendedor,
        t.CLO,
        s.Valor_Meta
    ORDER BY
        t.CLO DESC;

END;
GO