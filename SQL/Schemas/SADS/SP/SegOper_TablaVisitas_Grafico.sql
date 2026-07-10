CREATE OR ALTER PROCEDURE SADS.SegOper_TablaVisitas_Grafico
(
    @fecha DATE,
    @agencia INT=NULL,
    @zona INT=NULL,
    @ruta VARCHAR(10)=NULL,
    @frecuencia INT
)
AS
BEGIN
    SET NOCOUNT ON;

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

        SET @FechaInicioPeriodo =
            DATEADD(DAY,1-DATEPART(WEEKDAY,@fecha),@fecha);

        SET @FechaFinPeriodo =
            DATEADD(DAY,7-DATEPART(WEEKDAY,@fecha),@fecha);

        IF @Hoy < @FechaFinPeriodo
            SET @FechaCorte = @Hoy;
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
            SET @FechaCorte = @Hoy;
        ELSE
            SET @FechaCorte = @FechaFinPeriodo;

    END

    -------------------------------------------------------
    -- Días hábiles
    -------------------------------------------------------

    SELECT
        @DiasHabiles = COUNT(*)
    FROM CATALOGOS.Calendario
    WHERE Fecha BETWEEN @FechaInicioPeriodo
                    AND @FechaFinPeriodo
      AND Es_Habil = 1;

    -------------------------------------------------------
    -- Días hábiles transcurridos
    -------------------------------------------------------

    SELECT
        @DiasHabilesTranscurridos = COUNT(*)
    FROM CATALOGOS.Calendario
    WHERE Fecha BETWEEN @FechaInicioPeriodo
                    AND @FechaCorte
      AND Es_Habil = 1;

    -------------------------------------------------------
    -- Proceso
    -------------------------------------------------------

    ;WITH Rutas AS
    (
        SELECT
            A.Agencia,
            A.CLO,
            A.Clave_NUR,
            V.Grupo AS Zona
        FROM CATALOGOS.Agencias A

        LEFT JOIN CATALOGOS.Vendedores V
            ON A.Clave_NUR = V.NUR

        WHERE
            (@agencia IS NULL OR A.Agencia = @agencia)
            AND (@zona IS NULL OR V.Grupo = @zona)
            AND (@ruta IS NULL OR A.Clave_NUR = @ruta)
    ),

    Meta AS
    (
        SELECT

            A.NUR,

            CASE

                WHEN @frecuencia = 1 THEN
                    A.Obj_Visitas_Diario

                WHEN @frecuencia = 2 THEN
                    A.Obj_Visitas_Diario * @DiasHabiles

                WHEN @frecuencia = 3 THEN
                    A.Obj_Visitas_Mensual

            END AS Meta

        FROM SADS.SegOper_Objetivos_Mensuales A

        INNER JOIN Rutas R
            ON A.NUR LIKE '%' + R.Clave_NUR + '%'

        WHERE
            YEAR(A.Fecha)=YEAR(@fecha)
            AND MONTH(A.Fecha)=MONTH(@fecha)
    ),

    AvanceHoy AS
    (
        SELECT

            A.NUR,

            COALESCE(SUM(A.Visitas_Con_Compras),0) AS Avance

        FROM PowerStreet.Seguimiento_Indicadores A

        INNER JOIN Rutas R
            ON A.NUR LIKE '%' + R.Clave_NUR + '%'

        WHERE

            A.Fecha BETWEEN @FechaInicioPeriodo
                        AND @FechaCorte

        GROUP BY

            A.NUR
    ),

    Operacion AS
    (
        SELECT

            CEILING(COALESCE(SUM(A.Meta),0)) AS Meta,

            CEILING
            (
                COALESCE
                (
                    SUM
                    (
                        A.Meta *
                        (
                            @DiasHabilesTranscurridos * 1.0
                            / @DiasHabiles
                        )
                    ),
                    0
                )
            ) AS Debe_Haber,

            CEILING(COALESCE(SUM(B.Avance),0)) AS Avance

        FROM Meta A

        LEFT JOIN AvanceHoy B
            ON A.NUR = B.NUR
    )

    SELECT
        Meta,
        Debe_Haber,
        Avance
    FROM Operacion;

END