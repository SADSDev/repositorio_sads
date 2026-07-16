CREATE OR ALTER PROCEDURE Seguridad.IniciarSesion
(
    @nombre       VARCHAR(50),
    @contrasena   VARCHAR(255),
    @Aplicacion   INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UsuarioId INT;
    DECLARE @RolId INT;

    ---------------------------------------------------------
    -- Obtener Usuario y Rol
    ---------------------------------------------------------

    SELECT
        @UsuarioId = U.Id,
        @RolId = UA.RolId
    FROM Seguridad.Usuarios U
    INNER JOIN Seguridad.UsuarioAplicacion UA
        ON U.Id = UA.UsuarioId
    WHERE
        U.NombreUsuario = @nombre
        AND U.Contrasena = @contrasena
        AND U.Activo = 1
        AND UA.AplicacionId = @Aplicacion;

    ---------------------------------------------------------
    -- Si no existe el usuario
    ---------------------------------------------------------

    IF @UsuarioId IS NULL
        RETURN;

    ---------------------------------------------------------
    -- Información del usuario + permisos
    ---------------------------------------------------------

    SELECT
        U.Id AS UsuarioId,
        U.NombreCompleto AS Nombre,
        UA.AplicacionId,

        R.RolId,
        R.Rol,

        UA.Agencia,
        UA.Grupo,
        UA.Ruta,

        P.PermisoId,
        P.Permiso
    FROM Seguridad.Usuarios U

    INNER JOIN Seguridad.UsuarioAplicacion UA
        ON U.Id = UA.UsuarioId

    INNER JOIN Seguridad.Roles R
        ON UA.RolId = R.RolId

    INNER JOIN Seguridad.RolPermisos RP
        ON R.RolId = RP.RolId

    INNER JOIN Seguridad.Permisos P
        ON RP.PermisoId = P.PermisoId

    WHERE
        U.Id = @UsuarioId
        AND UA.AplicacionId = @Aplicacion

    ORDER BY
        P.PermisoId;

END;
GO