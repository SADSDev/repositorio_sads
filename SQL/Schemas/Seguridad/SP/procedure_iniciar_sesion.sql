CREATE OR ALTER PROCEDURE PWST.SEGURIDAD_IniciarSesion
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
    FROM PWST.SEGURIDAD_Usuarios U
    INNER JOIN PWST.SEGURIDAD_UsuarioAplicacion UA
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

        R.Rol,
        R.RolId,

        UA.Agencia,
        UA.Grupo,
        UA.Ruta,
        
        UP.PermisoId,

        P.Permiso
    FROM PWST.SEGURIDAD_Usuarios U

    INNER JOIN PWST.SEGURIDAD_UsuarioAplicacion UA
        ON U.Id = UA.UsuarioId

    INNER JOIN PWST.SEGURIDAD_Roles R
        ON UA.RolId = R.RolId

    LEFT JOIN Seguridad_UsuarioPermisos UP
        ON UA.UsuarioAplicacionId = UP.UsuarioAplicacionId

    LEFT JOIN PWST.SEGURIDAD_Permisos P
        ON UP.PermisoId = P.PermisoId

    WHERE
        U.Id = @UsuarioId
        AND UA.AplicacionId = @Aplicacion

    ORDER BY
        P.PermisoId;

END;
GO