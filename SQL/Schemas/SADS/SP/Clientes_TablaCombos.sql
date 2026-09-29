CREATE OR ALTER PROCEDURE [PWST].[SADS_Clientes_TablaCombos]  
@Cliente VARCHAR(300),  
@Inicio INT,  
@Fin INT,  
@Ainicio INT,  
@Afin INT  
  
AS  
  
SET NOCOUNT ON;  
  
SELECT
    FORMAT(Fecha, 'dd-MM-yyyy') AS Fecha, 
    Codigo_Combo as FAP, 
    Descripcion_Combo as Descripcion, 
    Cantidad_Combos as Cantidad
FROM [PWST].[POWERSTREET_Combos_Por_Cliente]   
WHERE Codigo_Cliente = @Cliente    
AND  DATEPART(ISO_WEEK, Fecha)  
BETWEEN @Inicio   
AND  @Fin  
AND  Fecha > DATEFROMPARTS(YEAR(GETDATE()), 1, 1)   
order by Fecha  
