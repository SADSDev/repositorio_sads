CREATE OR ALTER PROCEDURE PWST.CATALOGOS_ObtenerAgencias  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    SELECT  
        Agencia,  
        CLO  
    FROM PWST.CATALOGOS_Agencias  
    ORDER BY Agencia;  
END;  