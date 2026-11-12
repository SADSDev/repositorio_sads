CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_VisitasAgencias
(
    @fecha DATE,
    @agencia VARCHAR(200) = NULL,
    @zona VARCHAR(200)=NULL,
    @ruta VARCHAR(200)=NULL,
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

    DECLARE @Hoy DATE;

    DECLARE @FechaInicioPeriodo DATE;
    DECLARE @FechaFinPeriodo DATE;

    DECLARE @DiasHabiles INT;
    DECLARE @DiasHabilesTranscurridos INT;
    DECLARE @DiasHabilesRestantes INT;


    -------------------------------------------------------
    -- Fecha de corte
    -------------------------------------------------------
    IF YEAR(@fecha) = YEAR(GETDATE())
       AND MONTH(@fecha) = MONTH(GETDATE())
    BEGIN
        SET @Hoy = CAST(GETDATE() AS DATE);
    END
    ELSE
    BEGIN
        SET @Hoy = EOMONTH(@fecha);
    END
    -------------------------------------------------------
    -------------------------------------------------------
    IF @frecuencia = 1
    BEGIN
        SET @FechaInicioPeriodo = @fecha;
        SET @FechaFinPeriodo    = @fecha;
    END

    ELSE IF @frecuencia = 2
    BEGIN
        -- Lunes
        SET @FechaInicioPeriodo =
            DATEADD(DAY, -((DATEDIFF(DAY, '19000101', @fecha)) % 7), @fecha);

        -- Domingo
        SET @FechaFinPeriodo =
             DATEADD(DAY, 6, @FechaInicioPeriodo);

    END

    ELSE IF @frecuencia = 3
    BEGIN

        SET @FechaInicioPeriodo =
            DATEFROMPARTS(YEAR(@fecha),MONTH(@fecha),1);

        SET @FechaFinPeriodo =
            EOMONTH(@fecha);

    END
    -------------------------------------------------------
    -- Días hábiles del periodo
    -------------------------------------------------------
    SELECT
        @DiasHabiles = COUNT(*)
    FROM PWST.CATALOGOS_Calendario
    WHERE Fecha BETWEEN @FechaInicioPeriodo
                    AND @FechaFinPeriodo
      AND Es_Habil = 1;

    -------------------------------------------------------
    -- Días hábiles transcurridos del periodo
    -------------------------------------------------------
    SELECT
        @DiasHabilesTranscurridos = COUNT(*)
    FROM PWST.CATALOGOS_Calendario
    WHERE Fecha BETWEEN @FechaInicioPeriodo
                    AND @fecha
      AND Es_Habil = 1;

    -------------------------------------------------------
    --Días hábiles restantes
    -------------------------------------------------------
    SET @DiasHabilesRestantes = @DiasHabiles - @DiasHabilesTranscurridos;

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
            AND(
                @agencia IS NULL
                OR CHARINDEX(
                    ',' + CONVERT(VARCHAR(10), A.Agencia) + ',',
                    ',' + @agencia + ','
                ) > 0
            )
            AND (@zona IS NULL OR EXISTS (SELECT 1 FROM (SELECT LTRIM(RTRIM(N.X.value('.', 'VARCHAR(200)'))) AS value FROM (SELECT CAST('<x><v>' + REPLACE(ISNULL(@zona, ''), CHAR(44), '</v><v>') + '</v></x>' AS XML) AS XmlData) AS D CROSS APPLY D.XmlData.nodes('/x/v') AS N(X)) AS Z WHERE LTRIM(RTRIM(Z.value)) = V.Grupo))
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
                    ) IN (SELECT LTRIM(RTRIM(value)) FROM (SELECT LTRIM(RTRIM(N.X.value('.', 'VARCHAR(200)'))) AS value FROM (SELECT CAST('<x><v>' + REPLACE(ISNULL(@ruta, ''), CHAR(44), '</v><v>') + '</v></x>' AS XML) AS XmlData) AS D CROSS APPLY D.XmlData.nodes('/x/v') AS N(X)) AS RutaSplit)
            )
    ),

    ObjetivoVisitas AS
    (
        SELECT
            M.NUR,
            SUM(M.Valor_Meta) AS Meta,
            R.Agrupador
        FROM PWST.SADS_SegOper_Metas M

        INNER JOIN Rutas R
            ON M.NUR = R.NUR

        WHERE
            M.Indicador = 'VISITAS EFECTIVAS'
            AND M.Fecha BETWEEN @FechaInicioPeriodo
                            AND @FechaFinPeriodo

        GROUP BY
            M.NUR,
            R.Agrupador
    ),

    -------------------------------------------------------
    AvanceHoy AS
    (
        SELECT
            A.NUR,
            SUM(A.Visitas_Con_Compras) AS Avance,
            MAX(A.Visitas_Programadas) AS Visitas_Programadas
        FROM PWST.POWERSTREET_Seguimiento_Indicadores A
        LEFT JOIN Rutas B
            ON A.NUR = B.NUR
        WHERE
            A.Fecha BETWEEN @FechaInicioPeriodo AND @fecha
            AND (
                @agencia IS NULL
                OR CHARINDEX(
                    ',' + CONVERT(VARCHAR(10), B.Agencia) + ',',
                    ',' + @agencia + ','
                ) > 0
            )
        GROUP BY
            A.NUR
    ),

    ObjetivoAlDia AS
    (
        SELECT
            M.NUR,
            SUM(M.Valor_Meta) AS Objetivo_Al_Dia
        FROM PWST.SADS_SegOper_Metas M
        INNER JOIN Rutas R
            ON M.NUR = R.NUR
        WHERE
            M.Indicador = 'VISITAS EFECTIVAS'
            AND M.Fecha BETWEEN @FechaInicioPeriodo AND @fecha
        GROUP BY
            M.NUR
    ),

    -------------------------------------------------------
    TablaOperacionVisitas AS
    (
        SELECT
            A.NUR,
            A.Agrupador,
            A.Meta,
            B.Avance,
            D.Objetivo_Al_Dia
        FROM ObjetivoVisitas A
        LEFT JOIN AvanceHoy B
            ON A.NUR = B.NUR
        LEFT JOIN ObjetivoAlDia D
            ON A.NUR = D.NUR
    ),

    TablaOperacionCLO AS
    (
        SELECT
            Agrupador,
            SUM(Meta) AS Meta,
            SUM(ISNULL(Avance, 0)) AS Avance,
            SUM(ISNULL(Objetivo_Al_Dia, 0)) AS Objetivo_Al_Dia
        FROM TablaOperacionVisitas
        GROUP BY Agrupador
    )

    -------------------------------------------------------
    -- Resultado final
    -------------------------------------------------------
    SELECT
        Agrupador AS CLO,
        CEILING(Meta) AS Meta,
        CEILING(Objetivo_Al_Dia) AS Objetivo_Al_Dia,
        Avance,
        CAST(Avance/Meta AS DECIMAL (10,4)) AS Alcance
    FROM TablaOperacionCLO
    ORDER BY Agrupador;

END;
GO
