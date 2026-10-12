CREATE OR ALTER PROCEDURE [PWST].[CATALOGOS_ObtenerCliente]
    @Cliente VARCHAR(100) = '',
    @AgenciaId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Cliente = ''
    BEGIN
        SELECT DISTINCT
            U.Codigo_GLN AS Cliente,
            U.Nombre,
            S.REEV,
            U.Direccion,
            U.Colonia,
            U.Estado,
            U.Municipio
        FROM PWST.POWERSTREET_Universo_Clientes U
        LEFT JOIN PWST.CATALOGOS_SABANA S
            ON U.Codigo_GLN = S.ClienteISMS
        WHERE U.Agencia = @AgenciaId
        OPTION (RECOMPILE);
    END
    ELSE
    BEGIN
        SELECT DISTINCT
            U.Codigo_GLN AS Cliente,
            U.Nombre,
            S.REEV,
            U.Direccion,
            U.Colonia,
            U.Estado,
            U.Municipio
        FROM PWST.POWERSTREET_Universo_Clientes U
        LEFT JOIN PWST.CATALOGOS_SABANA S
            ON U.Codigo_GLN = S.ClienteISMS
        WHERE U.Agencia = @AgenciaId
          AND U.Codigo_GLN = @Cliente
        OPTION (RECOMPILE);
    END
END;