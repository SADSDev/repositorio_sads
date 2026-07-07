CREATE OR ALTER PROCEDURE SADS.SegOper_TablaVisitas_Grafico
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

    --proceso
    ;WITH Meta AS(
        SELECT
            NUR,
            COALESCE(SUM(A.Obj_Visitas_Mensual), 0) AS Meta_Mensual,
            COALESCE(A.Obj_Visitas_Diario * @diashabiles_transcurridos, 0) AS Debe_Haber
        FROM SADS.SegOper_Objetivos_Mensuales AS A
        LEFT JOIN CATALOGOS.Agencias AS B
            ON A.NUR LIKE '%' + B.Clave_NUR + '%'
        WHERE
            YEAR(A.Fecha) = @anio
            AND MONTH(A.Fecha) = @mes
            AND (@agencia = 0 OR B.Agencia = @agencia)
        GROUP BY 
            A.NUR,
            A.Obj_Visitas_Diario
    ),

    AvanceHoy AS(
            SELECT
                A.NUR,
                COALESCE(SUM(A.Visitas_Con_Compras),0) AS Avance
            FROM PowerStreet.Seguimiento_Indicadores AS A
            LEFT JOIN CATALOGOS.Agencias AS B
                ON A.NUR LIKE '%' + B.Clave_NUR + '%'
            WHERE
                A.Fecha BETWEEN DATEFROMPARTS(@anio,@mes,1) AND @hoy
                AND (@agencia = 0 OR B.Agencia = @agencia)
            GROUP BY
                A.NUR
    ),

    Operacion AS(
        SELECT
            CEILING(COALESCE(SUM(A.Meta_Mensual),0)) AS Meta_Mensual,
            CEILING(COALESCE(SUM(A.Debe_Haber),0)) AS Debe_Haber,
            CEILING(COALESCE(SUM(B.Avance),0)) AS Avance
        FROM Meta A
        LEFT JOIN AvanceHoy B
            ON A.NUR = B.NUR
    )
    SELECT*FROM Operacion
END;
