CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_ObtenerMEVigentes  
(  
    @mes INT = NULL,   
    @anio INT = NULL,   
    @agencia INT   
)  
AS  
BEGIN  
    SET NOCOUNT ON;  

    SELECT DISTINCT
        Familia
    FROM [PWST].[CATALOGOS_Vigencias_ME]
    WHERE Agencia = @agencia;
    
END