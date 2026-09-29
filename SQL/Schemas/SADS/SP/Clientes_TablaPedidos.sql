CREATE OR ALTER PROCEDURE [PWST].[SADS_Clientes_TablaPedidos]  
@Cliente VARCHAR(300),  
@Inicio INT,  
@Fin INT,  
@Ainicio INT,  
@Afin INT  

AS  
SET NOCOUNT ON;  

CREATE TABLE #Pedidos
(
    Fecha VARCHAR(10),
    Numero VARCHAR(50),
    Estatus VARCHAR(50),
    [Cantidad Orden] FLOAT,
    [Cantidad Entrega] FLOAT,
    [Entregados Orden Original] FLOAT,
    Fullfillment VARCHAR(20)
);
INSERT INTO #Pedidos

SELECT
    FORMAT(Fecha, 'dd-MM-yyyy') AS Fecha,
    Orden,
    Status_Orden,
    Cantidad_Orden,
    ISNULL(Cantidad_Entrega, 0),
    ROUND(Cantidad_Orden * (Fullfillment / 100.0), 2),
    CONCAT(CAST(ROUND(Fullfillment, 2) AS DECIMAL(10,2)), '%') AS Fullfillment 
FROM PWST.POWERSTREET_Fullfillment_Pedidos_PMM
WHERE Cliente = @Cliente
  AND DATEPART(ISO_WEEK, Fecha) BETWEEN @Inicio AND @Fin
  AND YEAR(Fecha) BETWEEN @Ainicio AND @Afin;

SELECT
    Fecha,
    Numero AS Orden,
    Estatus,
    [Cantidad Orden],
    [Cantidad Entrega],
    [Entregados Orden Original],
    Fullfillment
FROM #Pedidos
ORDER BY Fecha;

DROP TABLE #Pedidos;