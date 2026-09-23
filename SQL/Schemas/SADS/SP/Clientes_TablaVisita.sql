CREATE  OR ALTER PROCEDURE [PWST].[SADS_Clientes_TablaVisita]  
@Cliente VARCHAR(300),  
@Inicio INT,  
@Fin INT,  
@Ainicio INT,  
@Afin INT  
  
AS  
  
SELECT [PWST].[DiaSemana](Fecha) as Dia,   
  FORMAT(Fecha, 'dd-MM-yyyy') as Fecha,   
  FORMAT(HoraInicio, 'hh\:mm') AS Hora,  
  DATEDIFF(MINUTE,HoraInicio,HoraFinal ) AS Tiempo,   
  TipoInicio AS Apertura,
  PaquetesVendidos AS [Paquetes vendidos]  
FROM [PWST].[POWERSTREET_PDV_PorAgencia]  
WHERE Cliente = @Cliente  
AND  DATEPART(ISO_WEEK, Fecha)   
BETWEEN @Inicio  
AND  @Fin  
AND  Fecha > DATEFROMPARTS(YEAR(GETDATE()), 1, 1)   
ORDER BY Fecha, HoraInicio  
  
  
  