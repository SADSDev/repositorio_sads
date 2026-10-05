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
    WHERE Agencia = @agencia
    AND (
        Fin_Vigencia IS NULL
        OR Fin_Vigencia >= DATEFROMPARTS(@anio, @mes, 1)
    )
    AND(
        Inicio_vigencia <= DATEFROMPARTS(@anio, @mes, 1)
    );
    
END