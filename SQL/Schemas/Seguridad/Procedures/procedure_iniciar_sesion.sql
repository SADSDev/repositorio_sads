CREATE PROCEDURE Seguridad.IniciarSesion
(
    @nombre       VARCHAR(50),
    @contrasena   VARCHAR(255),
    @Aplicacion   VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AppID INT = TRY_CAST(@Aplicacion AS INT);

    SELECT
        U.Id,
        U.NombreCompleto AS Nombre,
        1 AS AlmacenId,
        1 AS ClienteId,
        'Administrador' AS Rol,
        UA.RolId
    FROM Seguridad.Usuarios U
    INNER JOIN Seguridad.UsuarioAplicacion UA
        ON U.Id = UA.UsuarioId
    INNER JOIN Seguridad.Aplicaciones A
        ON UA.AplicacionId = A.Id
    WHERE
        U.NombreUsuario = @nombre
        AND U.Contrasena = @contrasena
        AND U.Activo = 1
        AND A.Activo = 1
        AND A.Id = @AppID;
END;
GO