CREATE OR ALTER PROCEDURE SADS.SegOper_TablaVisitas
(
    @fecha DATE,
    @agencia INT=NULL,
    @zona VARCHAR(20)=NULL,
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
        SET @FechaCorte         = @fecha;
    END

    ELSE IF @frecuencia = 2
    BEGIN
        -- Lunes
        SET @FechaInicioPeriodo =
            DATEADD(DAY, -((DATEDIFF(DAY, '19000101', @fecha)) % 7), @fecha);

        -- Domingo
        SET @FechaFinPeriodo =
             DATEADD(DAY, 6, @FechaInicioPeriodo);

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
    -- Días hábiles del periodo
    -------------------------------------------------------
    SELECT
        @DiasHabiles = COUNT(*)
    FROM CATALOGOS.Calendario
    WHERE Fecha BETWEEN @FechaInicioPeriodo
                    AND @FechaFinPeriodo
      AND Es_Habil = 1;

    -------------------------------------------------------
    -- Días hábiles transcurridos del periodo
    -------------------------------------------------------
    SELECT
        @DiasHabilesTranscurridos = COUNT(*)
    FROM CATALOGOS.Calendario
    WHERE Fecha BETWEEN @FechaInicioPeriodo
                    AND @FechaCorte
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
            V.Grupo AS Zona
        FROM CATALOGOS.Rutas_Evaluables V

        INNER JOIN CATALOGOS.Agencias A
            ON V.NUR LIKE A.Clave_NUR + '%'

        WHERE
            (@agencia IS NULL OR A.Agencia = @agencia)
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

    ObjetivoVisitas AS
    (
        SELECT
            M.NUR,
            SUM(M.Valor_Meta) AS Meta,
            R.CLO
        FROM SADS.SegOper_Metas M

        INNER JOIN Rutas R
            ON M.NUR = R.NUR

        WHERE
            M.Indicador = 'VISITAS EFECTIVAS'
            AND M.Fecha BETWEEN @FechaInicioPeriodo
                            AND @FechaFinPeriodo

        GROUP BY
            M.NUR,
            R.CLO
    ),

    -------------------------------------------------------
    AvanceHoy AS
    (
        SELECT
            A.NUR,
            SUM(A.Visitas_Con_Compras) AS Avance,
            MAX(A.Visitas_Programadas) AS Visitas_Programadas
        FROM PowerStreet.Seguimiento_Indicadores A
        LEFT JOIN Rutas B
            ON A.NUR = B.NUR
        WHERE
            A.Fecha BETWEEN @FechaInicioPeriodo
                        AND @FechaCorte
            AND (@agencia IS NULL OR B.Agencia=@agencia)
        GROUP BY
            A.NUR
    ),

    -------------------------------------------------------
    TablaOperacionVisitas AS
    (
        SELECT
            A.NUR,
            A.CLO,
            A.Meta,
            B.Avance,
            CAST(ROUND(B.Avance / NULLIF(A.Meta,0),4)
            AS DECIMAL(10,4))
            AS Cobertura_Meta,
            CAST(CEILING(A.Meta *(@DiasHabilesTranscurridos * 1.0/ NULLIF(@DiasHabiles,0)))
            AS DECIMAL(10,2))
            AS Objetivo_Al_Dia,
            CAST(ROUND(B.Avance -(A.Meta *(@DiasHabilesTranscurridos * 1.0/ NULLIF(@DiasHabiles,0))),2)
            AS DECIMAL(10,2))
            AS Avance_VS_Obj_Al_Dia,
            CASE
                WHEN(B.Avance -(A.Meta *(@DiasHabilesTranscurridos * 1.0/ NULLIF(@DiasHabiles,0)))) < 0
                THEN
                ISNULL(CAST(ROUND(ABS(B.Avance -(A.Meta *(@DiasHabilesTranscurridos * 1.0/ NULLIF(@DiasHabiles,0))))/ NULLIF(@DiasHabilesRestantes,0),2) AS DECIMAL(10,2)),0)
                ELSE 0
            END
            AS Visitas_Adicionales_Por_Dia,
            CAST(ROUND(A.Meta /((B.Visitas_Programadas / 6.0)* @DiasHabiles),4) AS DECIMAL(10,4)) AS Efectividad_Visitas
        FROM ObjetivoVisitas A
        LEFT JOIN AvanceHoy B
            ON A.NUR = B.NUR
    )
    -------------------------------------------------------
    -- Resultado final
    -------------------------------------------------------
    SELECT
        NUR,
        CLO,
        CEILING(Meta) AS Meta,
        Avance,
        Cobertura_Meta,
        Objetivo_Al_Dia,
        Avance_VS_Obj_Al_Dia,
        Visitas_Adicionales_Por_Dia,
        Efectividad_Visitas
    FROM TablaOperacionVisitas
    ORDER BY CLO;

END;
GO