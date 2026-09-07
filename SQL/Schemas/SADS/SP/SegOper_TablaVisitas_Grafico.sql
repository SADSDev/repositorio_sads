CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_TablaVisitas_Grafico
(
    @fecha DATE,
    @agencia VARCHAR(200)=NULL,
    @zona VARCHAR(20)=NULL,
    @ruta VARCHAR(10)=NULL,
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

    DECLARE @Hoy DATE;

    DECLARE @FechaInicioPeriodo DATE;
    DECLARE @FechaFinPeriodo DATE;
    DECLARE @FechaCorte DATE;

    DECLARE @DiasHabiles INT;
    DECLARE @DiasHabilesTranscurridos INT;

    -------------------------------------------------------
    -- Fecha de corte
    -------------------------------------------------------

    IF YEAR(@fecha)=YEAR(GETDATE())
       AND MONTH(@fecha)=MONTH(GETDATE())
        SET @Hoy = CAST(GETDATE() AS DATE);
    ELSE
        SET @Hoy = EOMONTH(@fecha);

    -------------------------------------------------------
    -- Determinar periodo
    -------------------------------------------------------

    IF @frecuencia = 1
    BEGIN

        SET @FechaInicioPeriodo = @fecha;
        SET @FechaFinPeriodo    = @fecha;
        SET @FechaCorte         = @fecha;

    END

    ELSE IF @frecuencia = 2
    BEGIN
        -- Lunes de la semana
        SET @FechaInicioPeriodo =
            DATEADD(
                DAY,
                -((DATEDIFF(DAY, '19000101', @fecha)) % 7),
                @fecha
            );

        -- No permitir que la semana empiece antes del mes
        IF @FechaInicioPeriodo <
        DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
        BEGIN
            SET @FechaInicioPeriodo =
                DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1);
        END;

        -- Domingo de la semana
        SET @FechaFinPeriodo =
            DATEADD(DAY, 6, @FechaInicioPeriodo);

        -- No permitir que la semana termine después del mes
        IF @FechaFinPeriodo > EOMONTH(@fecha)
        BEGIN
            SET @FechaFinPeriodo = EOMONTH(@fecha);
        END;

        -- Fecha de corte
        IF @Hoy < @FechaFinPeriodo
            SET @FechaCorte = @fecha;
        ELSE
            SET @FechaCorte = @FechaFinPeriodo;
    END

    ELSE IF @frecuencia = 3
    BEGIN

        SET @FechaInicioPeriodo =
            DATEFROMPARTS(YEAR(@fecha),MONTH(@fecha),1);

        SET @FechaFinPeriodo =
            EOMONTH(@fecha);

        IF @Hoy < @FechaFinPeriodo
            SET @FechaCorte = @fecha;
        ELSE
            SET @FechaCorte = @FechaFinPeriodo;

    END

    -------------------------------------------------------
    -- Días hábiles
    -------------------------------------------------------

    SELECT
        @DiasHabiles = COUNT(*)
    FROM PWST.CATALOGOS_Calendario
    WHERE Fecha BETWEEN @FechaInicioPeriodo
                    AND @FechaFinPeriodo
      AND Es_Habil = 1;

    -------------------------------------------------------
    -- Días hábiles transcurridos
    -------------------------------------------------------

    SELECT
        @DiasHabilesTranscurridos = COUNT(*)
    FROM PWST.CATALOGOS_Calendario
    WHERE Fecha BETWEEN @FechaInicioPeriodo
                    AND @FechaCorte
      AND Es_Habil = 1;

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

        WHERE
            (
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

    Meta AS
    (
        SELECT
            M.NUR,
            SUM(M.Valor_Meta) AS Meta
        FROM PWST.SADS_SegOper_Metas M

        INNER JOIN Rutas R
            ON M.NUR = R.NUR

        WHERE
            M.Indicador = 'VISITAS EFECTIVAS'
            AND M.Fecha BETWEEN @FechaInicioPeriodo
                            AND @FechaFinPeriodo

        GROUP BY
            M.NUR
    ),

    AvanceHoy AS
    (
        SELECT

            A.NUR,

            COALESCE(SUM(A.Visitas_Con_Compras),0) AS Avance

        FROM PWST.POWERSTREET_Seguimiento_Indicadores A

        INNER JOIN Rutas R
            ON A.NUR = R.NUR

        WHERE
            A.Fecha BETWEEN @FechaInicioPeriodo AND @fecha
        GROUP BY

            A.NUR
    ),

    Meta_Al_Dia AS
    (
        SELECT
            M.NUR,
            SUM(M.Valor_Meta) AS Debe_Haber
        FROM PWST.SADS_SegOper_Metas M

        INNER JOIN Rutas R
            ON M.NUR = R.NUR

        WHERE
            M.Indicador = 'VISITAS EFECTIVAS'
            AND M.Fecha BETWEEN @FechaInicioPeriodo AND @fecha

        GROUP BY
            M.NUR
    ),

    Operacion AS
    (
        SELECT
            CEILING(SUM(M.Meta)) AS Meta,
            CEILING(SUM(D.Debe_Haber)) AS Debe_Haber,
            CEILING(SUM(A.Avance)) AS Avance

        FROM Meta M

        LEFT JOIN Meta_Al_Dia D
            ON M.NUR = D.NUR

        LEFT JOIN AvanceHoy A
            ON M.NUR = A.NUR
    )

    SELECT
        Meta,
        Debe_Haber,
        Avance
    FROM Operacion;

END
