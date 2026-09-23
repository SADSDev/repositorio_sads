CREATE OR ALTER PROCEDURE [PWST].[SADS_Clientes_TablaIndicadores]   
  @Cliente VARCHAR(300),  
  @Inicio INT,  
  @Fin INT,  
  @Ainicio INT,  
  @Afin INT  
  
AS  
  
  
SET nocount on  
  
CREATE TABLE #Indicadores (Compras FLOAT, ITO FLOAT, ASSORMENT FLOAT, ME FLOAT, COMBOS FLOAT, TIEMPO_VISITA FLOAT, APERTURA FLOAT, CPWME FLOAT)  
  
CREATE TABLE #TiemposMovimiento (Ruta VARCHAR(50),Cliente VARCHAR(100), Semana INT,  Paquetes_Vendidos FLOAT, HoraInicio DATETIME, HoraFin DATETIME, TipoInicio VARCHAR(50), FechaVisita DATETIME, DiaVisita VARCHAR(50) )    
INSERT INTO #TiemposMovimiento (Ruta, Cliente, Semana, Paquetes_Vendidos , HoraInicio , HoraFin , TipoInicio , FechaVisita , DiaVisita)  
SELECT 
    SUBSTRING(Vendedor,19,3), 
    Cliente, 
    DATEPART(ISO_WEEK, Fecha) AS Semana,  
    PaquetesVendidos, 
    HoraInicio, 
    HoraFinal, 
    TipoInicio, 
    Fecha, 
    [PWST].[DiaSemana](Fecha) AS DiaVisita  
FROM PWST.POWERSTREET_PDV_PorAgencia  
WHERE Cliente = @Cliente  
AND DATEPART(ISO_WEEK, Fecha) BETWEEN @Inicio AND @Fin  
AND Fecha > DATEFROMPARTS(YEAR(GETDATE()), 1, 1);

DECLARE @Familias TABLE(Familia VARCHAR(100));
INSERT INTO @Familias(Familia)
VALUES
    ('MARLBORO RED'),
    ('ICE MIX'),
    ('BLOSSOM MIX'),
    ('SUMMER MIX'),
    ('RUBY MIX'),
    ('CRAFTED RED'),
    ('BARONET');

--SELECT Ruta, Cliente, Semana,  PaquetesVendidos, HoraInicioVisita, HoraFinalVisita, TipoInicioVisita, Fecha, [PWST].[DiaSemana](Fecha) as DiaVisita  
    
-----------------------  
------  COMPRAS -------  
CREATE TABLE #Tabla (Semana INT)  
DECLARE @I INT = @Inicio  
  
DECLARE @Peso_Compras FLOAT = 0.25  
   
 WHILE @I < (@Fin + 1)  
 BEGIN  
  INSERT INTO #Tabla SELECT @I  
  SET @I = @I + 1  
 END  
  
DECLARE @Compras FLOAT  = 0  
DECLARE @Venta FLOAT  = 0  
DECLARE @ITO FLOAT = 0  
  
SELECT @Venta = SUM(IIF(G.Cant > 0, 1, 0))
FROM #Tabla T
LEFT JOIN (
    SELECT
        DATEPART(ISO_WEEK, Fecha) AS SemanaISO,
        SUM(Cantidad) AS Cant
    FROM [PWST].[POWERSTREET_Venta_Diaria]
    WHERE Cliente = @Cliente
    AND DATEPART(ISO_WEEK, Fecha) BETWEEN @Inicio AND @Fin
    AND FECHA > DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
    GROUP BY DATEPART(ISO_WEEK, Fecha)
) G
ON T.Semana = G.SemanaISO
  
  
--SELECT @Venta = SUM(IIF(G.Cant > 0, 1, 0))  
--    FROM #Tabla T  
--    LEFT JOIN (  
--         SELECT DATEPART(ISO_WEEK, GR.Fecha) AS Semana,  
--         GR.Cant   
--         FROM (  
--           SELECT   
--           Fecha,      
--           SUM(Cantidad) AS Cant  
--          FROM [PWST].[VentaPorRutaSOD]  
--          WHERE Cliente = @Cliente  
--          AND  Fecha   
--          BETWEEN PWST.ObtenerFechaI(@Inicio)    
--          AND  PWST.ObtenerFechaF(@Fin)  
--          GROUP BY  Fecha) GR   
--        ) D  
--    ON  T.Semana= D.Semana  
       
  
SET @Compras = (ISNULL(@Venta,0) / (@Fin -@Inicio + 1) * @Peso_Compras) * 100  
  
-----------------------  
--------  ITO ---------  
  
DECLARE @Peso_Ito FLOAT = 0.1   
  
DECLARE @VTotal FLOAT = 0  
--Visitas  
SELECT @VTotal = Count(Paquetes_Vendidos)  
FROM #TiemposMovimiento  
  
  
DECLARE @VCorrectas FLOAT = 0  
SELECT @VCorrectas = Count(Paquetes_Vendidos)   
FROM #TiemposMovimiento  
WHERE  DiaVisita IN ( Select  Dias   
       FROM (SELECT Codigo_GLN, [Dias], Frecuencia   
         FROM (       
          SELECT Codigo_GLN,  
            Lunes AS 'Lunes',  
            Martes AS 'Martes',  
            Miercoles AS 'Miércoles',  
            Jueves AS 'Jueves',  
            Viernes AS 'Viernes',  
            Sabado AS 'Sábado'    
          FROM [PWST].[POWERSTREET_Universo_Clientes]  
          WHERE Codigo_GLN  = @Cliente  
         ) AS s   
         UNPIVOT   
         (   
          Frecuencia FOR [Dias] IN ([Lunes], [Martes], [Miércoles],[Jueves],[Viernes],[Sábado])   
         ) AS unpvt ) D  
       WHERE Frecuencia > 0)  
  
         
IF @VTotal = 0  
 BEGIN  
  SET  @ITO = 0  
 END  
ELSE  
 BEGIN  
  SET  @ITO = (((ISNULL(@VCorrectas,0)/ ISNULL(@VTotal,0) ) * @Peso_Ito) * 100)  
 END  
  
  
  
  
--------------------------------  
----------  ASSORMENT ----------  
DECLARE @Assorment FLOAT = 0  
DECLARE @NumFamilias INT 
SELECT @NumFamilias = COUNT(*)
FROM @Familias; 
DECLARE @Peso_Assorment FLOAT = 0.1   
DECLARE @CantCajetillas INT = 0.3  
  
DECLARE @Cant  FLOAT = 0  
  
SET @Cant = ( select count( Cajetillas)  
FROM ( SELECT   
   A.Familia,   
   SUM(V.Cantidad) AS Cajetillas  
  FROM [PWST].[POWERSTREET_Venta_Diaria] V
  INNER JOIN [PWST].[CATALOGOS_Articulos] A
    ON V.Codigo_Articulo = A.Codigo
  WHERE Cliente = @Cliente  
    AND DATEPART(ISO_WEEK, Fecha) BETWEEN @Inicio AND @Fin  
    AND Familia IN (  
      SELECT Familia
      FROM @Familias
    )  
  AND Fecha > DATEFROMPARTS(YEAR(GETDATE()), 1, 1)  
  GROUP BY Familia  
  HAVING SUM(Cantidad) >= @CantCajetillas) A  
  )  
  
IF @Cant = 0  
 BEGIN  
  SET @Assorment = 0  
 END  
ELSE  
 BEGIN  
  SET @Assorment = ((@Cant / @NumFamilias) * @Peso_Assorment) * 100  
 END  
   
  
  
--------------------------------  
--------------  MARCAS ESTRATEGICAS -------------  
DECLARE @ME FLOAT = 0  
DECLARE @NumFamilias_ME FLOAT = 5  
DECLARE @Peso_ME FLOAT = 0.2  
  
  
  
SET @ME = (  
  SELECT ((SUM(IIF(ISNULL(ME.Cantidad,0) > 0, 1, 0)) / @NumFamilias_ME) * @Peso_ME ) * 100  
  FROM ( SELECT A.Familia, SUM(ISNULL(V.Cantidad,0)) AS Cantidad  
    FROM [PWST].[POWERSTREET_Venta_Diaria] V  
    INNER JOIN [PWST].[CATALOGOS_Articulos] A
      ON V.Codigo_Articulo = A.Codigo
    WHERE 1=1  
    AND  Cliente = @Cliente  
    AND  Familia IN ('ICE MIX', 'BLOSSOM MIX', 'SUMMER MIX', 'RUBY MIX', 'BARONET')  
    AND  DATEPART(ISO_WEEK, Fecha)   
    BETWEEN @inicio  
    AND  @Fin  
    AND  FECHA > DATEFROMPARTS(YEAR(GETDATE()), 1, 1)  
    GROUP BY Familia ) ME  
   )  
  
  
--------------------------------  
------------  COMBOS -----------  
DECLARE @Combo FLOAT = 0  
DECLARE @Peso_Combo FLOAT = 0.05  
  
SET @Combo = (  
SELECT IIF(SUM(ISNULL(C.Cantidad, 0)) >= 1, 1, 0) * @Peso_Combo * 100  
FROM  ( SELECT ISNULL(Cantidad_Combos,0) as Cantidad  
  FROM PWST.POWERSTREET_Combos_Por_Cliente  
  WHERE Codigo_Cliente = @Cliente  
  AND  DATEPART(ISO_WEEK, Fecha)  
  BETWEEN @inicio  
  AND  @Fin  
  ) C  
  )  
  
--------------------------------  
----------  TIEMPO ----------  
DECLARE @Visita FLOAT = 0  
DECLARE @PesoVisita FLOAT = 0.05  
DECLARE @MinVisita INT = 3  
  
  
DECLARE @VsistaTotal FLOAT = 0  
DECLARE @Visita3M FLOAT = 0  
  
SET @VsistaTotal = (  
     SELECT COUNT(DATEDIFF(MINUTE,HoraInicio,HoraFin )) AS Tiempo  
     FROM #TiemposMovimiento  
     )  
  
SET @Visita3M = (  
     SELECT COUNT(DATEDIFF(MINUTE,HoraInicio,HoraFin )) AS Tiempo  
     FROM #TiemposMovimiento   
     WHERE DATEDIFF(MINUTE,HoraInicio,HoraFin ) > 3  
    )  
  
IF @VsistaTotal = 0  
 BEGIN  
  SET @Visita = 0  
 END  
ELSE  
 BEGIN  
  SET @Visita = (((isnull(@Visita3M,0) / isnull(@VsistaTotal,0) ) * @PesoVisita) * 100)  
 END  
  
--------------------------------  
----------  APERTURAS ----------  
DECLARE @Apertura FLOAT = 0  
DECLARE @PesoApertura FLOAT = 0.05  
  
DECLARE @InicioTotal INT  =0  
DECLARE @InicioGPS INT  =0  
  
SET @InicioTotal = (  
     SELECT COUNT(TipoInicio)  
     FROM #TiemposMovimiento  
     )  
  
SET @InicioGPS = (  
     SELECT COUNT(TipoInicio)  
     FROM #TiemposMovimiento   
     WHERE TipoInicio = 'GPS'  
     )  
  
IF @InicioTotal = 0  
 BEGIN  
  SET @Apertura = 0  
 END  
ELSE  
 BEGIN  
  SET @Apertura = (((isnull(@InicioGPS,0) / isnull(@InicioTotal,0) ) * @PesoApertura) * 100)  
 END  
  
  
--------------------------------  
------------  CPWME ------------  
  
DECLARE @CPWME FLOAT = 0  
DECLARE @CPWME_Tope FLOAT = 0  
DECLARE @PesoCPWME FLOAT = 0.2  
  
  
SET @CPWME_Tope = (  
SELECT (ISNULL(AVG(Paquetes_Vendidos),0) * @PesoCPWME) * 100  
FROM #TiemposMovimiento   
  )  
SET @CPWME = IIF( @CPWME_Tope > 20, 20, @CPWME_Tope)  
  
--------------------------------------------------------------------------------------------------------------------------------  
------------------------------------------------   RESULTADOS   ------------------------------------------------  
--------------------------------------------------------------------------------------------------------------------------------  
  
INSERT INTO #Indicadores (Compras, ITO, Assorment, ME, Combos, Tiempo_Visita, Apertura, CPWME)  
VALUES ( ROUND(ISNULL(@COMPRAS ,0),2,3),    
   ROUND(ISNULL(@ITO  ,0),2,3),   
   ROUND(ISNULL(@Assorment ,0),2,3),   
   ROUND(ISNULL(@ME  ,0),2,3),    
   ROUND(ISNULL(@Combo  ,0),2,3),  
   ROUND(ISNULL(@Visita ,0),2,3),    
   ROUND(ISNULL(@Apertura ,0),2,3),   
   ROUND(ISNULL(@CPWME  ,0),2,3))  
  
  
;WITH Calc AS (  
    SELECT    
        Compras, ITO, Assorment, ME, Combos, Tiempo_Visita, Apertura, CPWME   
    FROM #Indicadores  
)  
SELECT  
  CAST(Compras  AS VARCHAR(20)) + '%'   AS Compras,  
  CAST(ITO   AS VARCHAR(20)) + '%'   AS ITO,  
  CAST(Assorment  AS VARCHAR(20)) + '%'   AS Assorment,  
  CAST(ME    AS VARCHAR(20)) + '%'   AS ME,  
  CAST(Combos   AS VARCHAR(20)) + '%'   AS Combos,  
  CAST(Tiempo_Visita AS VARCHAR(20)) + '%'   AS [Tiempo Visita],  
  CAST(Apertura  AS VARCHAR(20)) + '%'   AS Apertura,  
  CAST(CPWME   AS VARCHAR(20)) + '%'   AS CPWME  
FROM Calc  
  
drop table #Indicadores  
  