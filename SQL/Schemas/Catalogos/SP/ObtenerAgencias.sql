CREATE   PROCEDURE CATALOGOS.ObtenerAgencias  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    SELECT  
        Agencia,  
        CLO  
    FROM CATALOGOS.Agencias  
    ORDER BY Agencia;  
END;  