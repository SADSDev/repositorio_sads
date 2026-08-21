CREATE OR ALTER PROCEDURE PWST.CATALOGOS_ObtenerAgencias  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    SELECT  
        Agencia,  
        CLO  
    FROM PWST.CATALOGOS_Agencias
    WHERE Agencia NOT IN (2, 3, 9, 10)  
    ORDER BY Agencia;  
END;  