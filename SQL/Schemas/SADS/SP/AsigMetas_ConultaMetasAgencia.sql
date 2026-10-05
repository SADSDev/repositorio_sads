CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_MetasAgencias   
(  
    @mes INT,   
    @anio INT,   
    @agencia INT   
)   
AS   
BEGIN   
  
    SET NOCOUNT ON;   
--------------------------------------  
-- RESULT SET 4  
-- METAS MENSUALES  
--------------------------------------  
SELECT   
    ISNULL(Indicador,'ND') AS Indicador,   
    ISNULL(CAST(Valor_Meta AS INT),0) AS Valor_Meta   
FROM PWST.SADS_SegOper_MetasAgencia   
WHERE Agencia=@agencia
AND CategoriaId=1   
AND MONTH(Mes)=@mes   
AND YEAR(Mes)=@anio;

END