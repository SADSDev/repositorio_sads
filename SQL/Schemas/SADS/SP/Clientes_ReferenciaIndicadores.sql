CREATE OR ALTER PROCEDURE [PWST].[SADS_Clientes_ReferenciaIndicadores]   
@Agencia INT = 0  
  
AS  
  
SET NOCOUNT ON  
  
CREATE TABLE #Indicadores (COMPRAS INT, ITO INT, ASSORMENT INT, ME INT, COMBOS INT, [TIEMPO VISITA] INT, APERTURA INT, CPWME INT, Operacion INT, [Control] INT,  Mercado INT)  
  
  
INSERT INTO #Indicadores (Compras, ITO, Assorment, ME, Combos, [Tiempo Visita], Apertura, CPWME, Operacion, [Control], Mercado )  
VALUES ( 25, 10, 10, 20, 5, 5, 5, 20, 70, 10, 20)  
  
SELECT *  
FROM #Indicadores  
  
  
  