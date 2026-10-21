CREATE OR ALTER PROCEDURE PWST.SEGURIDAD_ObtenerRecursos
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
        @UsuarioId = U.UsuarioId,
        @RolId = UA.RolId
    FROM PWST.SEGURIDAD_Usuarios U
    INNER JOIN PWST.SEGURIDAD_UsuarioAplicacion UA
        ON U.UsuarioId = UA.UsuarioId
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
    -- Recursos del usuario
    ---------------------------------------------------------
    SELECT
        U.NombreCompleto AS Nombre,
        UR.RecursoId,
        RE.Recurso,
        RE.Ruta
    FROM PWST.SEGURIDAD_Usuarios U
    INNER JOIN PWST.SEGURIDAD_UsuarioAplicacion UA
        ON U.UsuarioId=UA.UsuarioId
    INNER JOIN PWST.SEGURIDAD_UsuarioRecursos UR
        ON UA.UsuarioAplicacionId = UR.UsuarioAplicacionId
    INNER JOIN PWST.SEGURIDAD_Recursos RE
        ON UR.RecursoId = RE.RecursoId
    WHERE
        UA.UsuarioId = @UsuarioId
        AND UA.AplicacionId = @Aplicacion
    ORDER BY UR.RecursoId;
END;
GO