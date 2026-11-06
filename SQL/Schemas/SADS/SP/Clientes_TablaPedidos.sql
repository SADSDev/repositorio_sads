CREATE OR ALTER PROCEDURE [PWST].[SADS_Clientes_TablaPedidos]  
@Cliente VARCHAR(300),  
@Inicio INT,  
@Fin INT,  
@Ainicio INT,  
@Afin INT  

AS 
BEGIN
SET NOCOUNT ON;
    
    DECLARE @FechaInicio DATE
    DECLARE @FechaFin DATE
    DECLARE @DiferenciaSemanas INT

    SET @FechaFin = DATEADD(
        DAY,
        (@Fin - 1) * 7 + 6,
        DATEADD(
            DAY,
            -(DATEDIFF(DAY, '19000101', DATEFROMPARTS(@Afin, 1, 4)) % 7)-1,
            DATEFROMPARTS(@Afin, 1, 4)
        )
    );
    
    IF @Ainicio < @Afin AND @Inicio < 0 AND @Fin > 0
    BEGIN
       SET @FechaInicio = DATEADD(
            WEEK,
            @Inicio,
            DATEADD(
                DAY,
                -(DATEDIFF(
                    DAY,
                    '19000101',
                    DATEFROMPARTS(@Ainicio, 12, 28)
                ) % 7),
                DATEFROMPARTS(@Ainicio, 12, 28)
            )
        );
    END
    ELSE
    BEGIN 
        SET @DiferenciaSemanas= @Fin-@Inicio
        SET @FechaInicio =DATEADD(DAY, -5,DATEADD(
                WEEK, -@DiferenciaSemanas, @FechaFin
            )
        )
    END

    SELECT
        FORMAT(P.Fecha, 'dd-MM-yyyy') AS Fecha,
        P.Orden AS Orden,
        P.Status_Orden AS Estatus,
        CAST(P.Cantidad_Orden AS DECIMAL(10,3))  AS [Cantidad Orden],
        ISNULL(CAST(P.Cantidad_Entrega AS DECIMAL(10,3)), 0) AS [Cantidad Entrega],
        CAST(ROUND(P.Cantidad_Orden * (P.Fullfillment / 100.0), 3) AS DECIMAL(10,3))
            AS [Entregados Orden Original],
        CONCAT(
            CAST(ROUND(P.Fullfillment, 2) AS DECIMAL(10,2)),
            '%'
        ) AS Fullfillment
    FROM PWST.POWERSTREET_Fullfillment_Pedidos_PMM P
    WHERE Cliente = @Cliente
    AND Fecha BETWEEN @FechaInicio AND @FechaFin 
    ORDER BY P.Fecha ASC;
END