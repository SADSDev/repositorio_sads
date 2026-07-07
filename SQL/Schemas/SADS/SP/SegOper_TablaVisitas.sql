CREATE OR ALTER PROCEDURE SADS.SegOper_TablaVisitas
(
    @anio INT,
    @mes INT,
    @agencia INT
)
AS
BEGIN
    SET NOCOUNT ON;
    --declaracion de variables reusables en sp
    DECLARE @hoy DATE;
    DECLARE @diashabiles INT;
    DECLARE @diashabiles_transcurridos INT;

    IF @anio = YEAR(GETDATE()) AND @mes = MONTH(GETDATE())
        SET @hoy = CAST(GETDATE() AS DATE);
    ELSE
        SET @hoy = EOMONTH(DATEFROMPARTS(@anio, @mes, 1));
    
    SELECT
        @diashabiles = COUNT(*)
    FROM CATALOGOS.Calendario
    WHERE
        Anio = @anio
        AND Mes = @mes
        AND Es_Habil = 1;

    SELECT
        @diashabiles_transcurridos = COUNT(*)
    FROM CATALOGOS.Calendario
    WHERE
        Fecha BETWEEN DATEFROMPARTS(@anio, @mes, 1)
                  AND @hoy
        AND Es_Habil = 1;
    
    --Proceso
    ;WITH ObjetivoVisitas AS
    (
        SELECT
            A.NUR,
            CEILING(A.Obj_Visitas_Mensual) AS Obj_Visitas_Mensual,
            CEILING(A.Obj_Visitas_Diario) AS Obj_Visitas_Diario,
            B.CLO
        FROM SADS.SegOper_Objetivos_Mensuales AS A
        LEFT JOIN CATALOGOS.Agencias AS B
            ON A.NUR LIKE '%' + B.Clave_NUR + '%'
        WHERE
            YEAR(A.Fecha) = @anio
            AND MONTH(A.Fecha) = @mes
            AND (@agencia = 0 OR B.Agencia = @agencia)
    ),

    AvanceHoy AS
    (
        SELECT
            A.NUR,
            SUM(A.Visitas_Con_Compras) AS Avance,
            MAX(A.Visitas_Programadas) AS Visitas_Programadas
        FROM PowerStreet.Seguimiento_Indicadores AS A
        LEFT JOIN CATALOGOS.Agencias AS B
            ON A.NUR LIKE '%' + B.Clave_NUR + '%'
        WHERE
            A.Fecha BETWEEN DATEFROMPARTS(@anio,@mes,1) AND @hoy
            AND (@agencia = 0 OR B.Agencia = @agencia)
        GROUP BY
            A.NUR
    ),

    TablaOperacionVisitas AS
    (
        SELECT
            A.NUR,
            A.CLO,
            A.Obj_Visitas_Mensual,
            A.Obj_Visitas_Diario,
            B.Avance,
            CAST(ROUND((B.Avance / A.Obj_Visitas_Mensual),4) AS DECIMAL(10,4)) AS Cobertura_Meta,
            CAST(ROUND(A.Obj_Visitas_Mensual * (@diashabiles_transcurridos * 1.0 / @diashabiles), 2) AS DECIMAL(10,2)) AS Objetivo_Al_Dia,
            CAST(ROUND(B.Avance - (A.Obj_Visitas_Mensual * (@diashabiles_transcurridos * 1.0 / @diashabiles)), 2) AS DECIMAL(10,2)) AS Avance_VS_Obj_Al_Dia,
            CASE
                WHEN (B.Avance - (A.Obj_Visitas_Mensual * (@diashabiles_transcurridos * 1.0 / @diashabiles))) < 0 
                    THEN CAST(ROUND(ABS(B.Avance - (A.Obj_Visitas_Mensual * (@diashabiles_transcurridos * 1.0 / @diashabiles))) / @diashabiles, 2) AS DECIMAL(10,2)) 
                ELSE 0
            END AS Visitas_Adicionales_Por_Dia,
            CAST(ROUND(A.Obj_Visitas_Mensual/((B.Visitas_Programadas / 6.0) * @diashabiles),4) AS DECIMAL(10,4)) AS Efectividad_Visitas
        FROM ObjetivoVisitas AS A
        LEFT JOIN AvanceHoy AS B
            ON A.NUR = B.NUR
    )

    SELECT *FROM TablaOperacionVisitas

END;
