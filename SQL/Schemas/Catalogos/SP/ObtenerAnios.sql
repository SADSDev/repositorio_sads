CREATE   PROCEDURE CATALOGOS.ObtenerAniosDisponibles  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    SELECT DISTINCT  
        Anio  
    FROM CATALOGOS.Calendario  
    ORDER BY Anio;  
END;  