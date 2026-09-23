  
CREATE PROCEDURE [PWST].[SADS_Clientes_GraficaVolumen]  
@Cliente VARCHAR(300),  
@Inicio INT,  
@Fin INT,  
@Ainicio INT,  
@Afin INT  
  
AS  
  
  
SELECT
    DATEPART(ISO_WEEK, Fecha) AS SemanaIso,
    ISNULL(SUM(Cantidad), 0) AS Cantidad
FROM [PWST].[POWERSTREET_Venta_Diaria]
WHERE Cliente = @Cliente
AND DATEPART(ISO_WEEK, Fecha) BETWEEN @Inicio AND @Fin
AND Fecha > DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
GROUP BY DATEPART(ISO_WEEK, Fecha) 
  
--SELECT DATEPART(ISO_WEEK, A.Fecha) AS Semana,  
--  A.Cantidad  
--FROM ( SELECT    
--   Fecha ,         
--   SUM(Cantidad) AS Cantidad  
--  FROM [PWST].[VentaPorRutaSOD]  
--  WHERE Cliente = @Cliente  
--  AND  Fecha   
--  BETWEEN PWST.ObtenerFechaI(@Inicio)    
--  AND  PWST.ObtenerFechaF(@Fin)   
--  GROUP BY  fecha ) A  
--  Order by Semana  
  
  