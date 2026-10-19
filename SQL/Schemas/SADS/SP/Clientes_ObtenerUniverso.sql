CREATE OR ALTER PROCEDURE [PWST].[SADS_Clientes_ObtenerUniverso]   
(
    @Cliente VARCHAR(300)
)
   
  
AS  
    SET NOCOUNT ON;  
    
    SELECT
        A.CLO,
        UC.Codigo_GLN AS Cliente,
        isnull(S.Reev,'ND') as REEV,
        UC.NUR,
        CONCAT('R', SUBSTRING(UC.NUR, PATINDEX('%[A-Z]%', UC.NUR) + 1, LEN(UC.NUR))) AS Ruta,
        CASE WHEN UC.Frecuencia > 0
            THEN CONCAT('PM0', UC.Frecuencia)
            ELSE 'ND'
        END AS Frecuencia,
        [Status],
        ISNULL(S.Tier, 'ND') AS Tier,
        ISNULL(S.Custom, 'ND') AS Custom,
        CASE WHEN S.Gtplus=1 THEN 'SI' ELSE 'NO' END AS Gtplus,
        ISNULL(CAST(S.Credito AS VARCHAR(50)), 'ND') AS Credito,
        CASE WHEN S.[Open]=1 THEN 'SI' ELSE 'NO' END AS [Open],
        CASE WHEN S.Ponderado=1 THEN 'SI' ELSE 'NO' END AS Ponderado,
        CASE WHEN S.Visitable=1 THEN 'SI' ELSE 'NO' END AS Visitable,
        CASE WHEN S.Merch=1 THEN 'SI' ELSE 'NO' END AS Merch,
        UC.X, 
        UC.Y   
    FROM PWST.POWERSTREET_Universo_Clientes UC
    LEFT JOIN PWST.CATALOGOS_Agencias A
        ON UC.Agencia=A.Agencia  
    LEFT JOIN PWST.CATALOGOS_Sabana S  
        ON  UC.Codigo_GLN LIKE  '%' + S.ClienteISMS + '%'  
        AND  UC.Agencia = S.Agencia      
    WHERE UC.Codigo_GLN = @Cliente