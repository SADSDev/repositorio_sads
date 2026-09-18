CREATE OR ALTER PROCEDURE [PWST].[CATALOGOS_ObtenerCliente]  
@Cliente VARCHAR(100) = '',  
@AgenciaId INT  
  
AS  
SET NOCOUNT ON  
    SELECT DISTINCT 
        U.Codigo_GLN as Cliente,  
        U.Nombre,
        S.REEV, 
        U.Direccion, 
        U.Colonia, 
        U.Estado, 
        U.Municipio  
    FROM PWST.POWERSTREET_Universo_Clientes U
    LEFT JOIN PWST.CATALOGOS_SABANA S
        ON U.Codigo_GLN = S.ClienteISMS  
    WHERE (U.Codigo_GLN = @Cliente OR @Cliente = '')  
    AND U.Agencia = @AgenciaId