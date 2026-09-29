CREATE OR ALTER PROCEDURE [PWST].[ObtenerSupervisores]   
@AgenciaId INT = 0  
AS  
BEGIN  
   
  
    SELECT
        Id, 
        Nombre  
    FROM [PWST].[Cat_Supervisor]  
    WHERE AgenciaId = @AgenciaId   
    AND Activo = 1  
    Order by Id;  
   
   
  
END  