CREATE OR ALTER PROCEDURE [PWST].[SADS_Clientes_ObtenerFrecuencia]  
@Cliente VARCHAR(300)   
  
AS  
  
SELECT IIF(Lunes = 0, 0, 1) AS 'PM01',  
  IIF(Martes = 0, 0, 1) AS 'PM02',  
  IIF(Miercoles = 0, 0, 1) AS 'PM03',  
  IIF(Jueves = 0, 0, 1) AS 'PM04',  
  IIF(Viernes = 0, 0, 1) AS 'PM05',  
  IIF(Sabado = 0, 0, 1) AS 'PM06'  
FROM [PWST].[POWERSTREET_Universo_Clientes]  
WHERE Codigo_GLN  = @Cliente  
AND  DATEPART(ISO_WEEK, Fecha_Actualizacion) = (select max(DATEPART(ISO_WEEK, Fecha_Actualizacion)) from POWERSTREET_Universo_Clientes where Codigo_GLN = @Cliente)
