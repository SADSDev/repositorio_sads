CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_VisitasSupervisoresAgencias
(
    @fecha DATE,
    @agencia VARCHAR(200)=NULL,
    @zona VARCHAR(200)=NULL,
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

    IF @frecuencia IN (1, 2, 3)
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
                OR EXISTS (
                    SELECT 1
                    FROM (SELECT LTRIM(RTRIM(N.X.value('.', 'VARCHAR(200)'))) AS value FROM (SELECT CAST('<x><v>' + REPLACE(ISNULL(@zona, ''), CHAR(44), '</v><v>') + '</v></x>' AS XML) AS XmlData) AS D CROSS APPLY D.XmlData.nodes('/x/v') AS N(X)) AS Z
                    WHERE LTRIM(RTRIM(Z.value)) = S.Grupo
                )
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
                ) IN (
                    SELECT LTRIM(RTRIM(value))
                    FROM (SELECT LTRIM(RTRIM(N.X.value('.', 'VARCHAR(200)'))) AS value FROM (SELECT CAST('<x><v>' + REPLACE(ISNULL(@ruta, ''), CHAR(44), '</v><v>') + '</v></x>' AS XML) AS XmlData) AS D CROSS APPLY D.XmlData.nodes('/x/v') AS N(X)) AS RutaSplit
                )
            )
    ),

    ito_supervisores AS
    (
        SELECT
            t.NUR,
            t.Supervisor,
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
            FROM PWST.POWERSTREET_Encuestas_Supervisores I
            WHERE
                I.Fecha >= @FechaInicioPeriodo
                AND I.Fecha < DATEADD(DAY, 1, @fecha)
        ) t
        INNER JOIN nurs n
            ON t.Supervisor = n.Codigo
        WHERE
            t.rn = 1
    ),

    ResumenSupervisores AS
    (
        SELECT
            S.Codigo AS Supervisor,
            S.CLO,
            CAST(M.Valor_Meta AS INT) AS Valor_Meta,
            COUNT(DISTINCT T.Cliente) AS Total_Visitas,
            CAST(
                COUNT(DISTINCT T.Cliente) * 1.0 / NULLIF(M.Valor_Meta, 0)
                AS DECIMAL(10,4)
            ) AS Alcance
        FROM nurs S
        INNER JOIN PWST.SADS_SegOper_MetasSupervisor M
            ON M.Agencia = S.Agencia
            AND M.Grupo = S.Grupo
            AND M.Indicador = 'VISITAS'
            AND M.Mes = DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
        LEFT JOIN ito_supervisores T
            ON T.Supervisor = S.Codigo
            AND T.Agencia = S.Agencia
            AND T.Grupo = S.Grupo
        GROUP BY
            S.Codigo,
            S.CLO,
            M.Valor_Meta
    )

    SELECT
        CLO,
        SUM(Valor_Meta) AS MetaTotal,
        SUM(Total_Visitas) AS Total_Visitas,
        CAST(
            CAST(SUM(Total_Visitas) AS DECIMAL(18,4))
            / NULLIF(SUM(Valor_Meta), 0)
            AS DECIMAL(10,4)
        ) AS Alcance
    FROM ResumenSupervisores
    GROUP BY
        CLO
    ORDER BY
        CLO;

END;
GO
