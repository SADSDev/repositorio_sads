CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_TablaVisitas
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
            V.Grupo AS Zona
        FROM PWST.CATALOGOS_Vendedores V

        INNER JOIN PWST.CATALOGOS_Agencias A
            ON V.NUR LIKE A.Clave_NUR + '%'

        WHERE
            Evaluable=1
            AND(
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

    ObjetivoVisitas AS
    (
        SELECT
            M.NUR,
            SUM(M.Valor_Meta) AS Meta,
            R.CLO
        FROM PWST.SADS_SegOper_Metas M

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
            A.CLO,
            A.Meta,
            B.Avance,
            D.Objetivo_Al_Dia,
            CAST(ROUND(B.Avance / NULLIF(A.Meta,0),4) AS DECIMAL(10,4)) AS Cobertura_Meta,
            CAST(B.Avance - CEILING(D.Objetivo_Al_Dia) AS INT) AS Avance_VS_Obj_Al_Dia,
            CASE
                WHEN (B.Avance - D.Objetivo_Al_Dia) < 0
                THEN CASE
                    WHEN @DiasHabilesRestantes > 0
                    THEN ISNULL(
                        CAST(
                            ROUND(
                                ABS(B.Avance - D.Objetivo_Al_Dia) / NULLIF(@DiasHabilesRestantes,0),
                                2
                            ) AS DECIMAL(10,2)
                        ),
                        0
                    )
                    ELSE CAST(
                        ROUND(
                            ABS(B.Avance - D.Objetivo_Al_Dia),
                            2
                        ) AS DECIMAL(10,2)
                    )
                END
                ELSE 0
            END AS Visitas_Adicionales_Por_Dia
        FROM ObjetivoVisitas A
        LEFT JOIN AvanceHoy B
            ON A.NUR = B.NUR
        LEFT JOIN ObjetivoAlDia D
            ON A.NUR = D.NUR
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
        CEILING(Objetivo_Al_Dia) AS Objetivo_Al_Dia ,
        Avance_VS_Obj_Al_Dia ,
        CEILING(Visitas_Adicionales_Por_Dia) AS Visitas_Adicionales_Por_Dia
    FROM TablaOperacionVisitas
    ORDER BY CLO;

END;
GO
