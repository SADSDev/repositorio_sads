CREATE OR ALTER PROCEDURE PWST.SEGURIDAD_AltaUsuario  
(  
    @usuario         VARCHAR(50),  
    @contrasena      VARCHAR(100),  
    @nombreCompleto  VARCHAR(150),  
    @AplicacionId    INT,  
    @rol             INT,  
    @agencia         INT = NULL,  
    @grupo           VARCHAR(50) = NULL,  
    @NUR             VARCHAR(20) = NULL  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    DECLARE @UsuarioId INT;  
    DECLARE @UsuarioAplicacionId INT;  
    DECLARE @Ruta VARCHAR(10);  
  
    BEGIN TRY  
  
        -------------------------------------------------------  
        -- Validar que no exista el NombreCompleto  
        -------------------------------------------------------  
  
        IF EXISTS  
        (  
            SELECT 1  
            FROM PWST.SEGURIDAD_Usuarios  
            WHERE NombreCompleto = @nombreCompleto  
        )  
        BEGIN  
            THROW 50001, 'Ya existe un usuario con ese NombreCompleto.', 1;  
        END;  
  
  
        -------------------------------------------------------  
        -- Obtener Ruta a partir del NUR  
        -------------------------------------------------------  
  
        IF @NUR IS NOT NULL  
        BEGIN  
            SET @Ruta =  
                CONCAT(  
                    'R',  
                    SUBSTRING(  
                        @NUR,  
                        PATINDEX('%[A-Z]%', @NUR) + 1,  
                        LEN(@NUR)  
                    )  
                );  
        END  
        ELSE  
        BEGIN  
            SET @Ruta = NULL;  
        END;  
  
  
        -------------------------------------------------------  
        -- Iniciar transacción  
        -------------------------------------------------------  
  
        BEGIN TRANSACTION;  
  
  
        -------------------------------------------------------  
        -- 1. Crear usuario  
        -------------------------------------------------------  
  
        INSERT INTO PWST.SEGURIDAD_Usuarios  
        (  
            NombreUsuario,  
            Contrasena,  
            NombreCompleto,  
            Activo,  
            FechaCreacion  
        )  
        VALUES  
        (  
            @usuario,  
            @contrasena,  
            @nombreCompleto,  
            1,  
            GETDATE()  
        );  
  
        SET @UsuarioId = SCOPE_IDENTITY();  
  
  
        -------------------------------------------------------  
        -- 2. Asignar usuario a la aplicación  
        -------------------------------------------------------  
  
        INSERT INTO PWST.SEGURIDAD_UsuarioAplicacion  
        (  
            UsuarioId,  
            AplicacionId,  
            RolId,  
            Agencia,  
            Grupo,  
            Ruta  
        )  
        VALUES  
        (  
            @UsuarioId,  
            @AplicacionId,  
            @rol,  
            @agencia,  
            @grupo,  
            @Ruta  
        );  
  
        SET @UsuarioAplicacionId = SCOPE_IDENTITY();  
  
  
        -------------------------------------------------------  
        -- 3. Copiar permisos del rol al usuario  
        -------------------------------------------------------  
  
        INSERT INTO PWST.SEGURIDAD_UsuarioPermisos  
        (  
            UsuarioAplicacionId,  
            PermisoId  
        )  
        SELECT  
            @UsuarioAplicacionId,  
            RP.PermisoId  
        FROM PWST.SEGURIDAD_RolPermisos RP  
        WHERE RP.RolId = @rol;  
  
  
        -------------------------------------------------------  
        -- Confirmar transacción  
        -------------------------------------------------------  
  
        COMMIT TRANSACTION;  
  
  
        -------------------------------------------------------  
        -- Regresar IDs generados  
        -------------------------------------------------------  
  
        SELECT  
            @UsuarioId AS UsuarioId,  
            @UsuarioAplicacionId AS UsuarioAplicacionId,  
            @Ruta AS Ruta;  
  
    END TRY  
  
    BEGIN CATCH  
  
        IF @@TRANCOUNT > 0  
            ROLLBACK TRANSACTION;  
  
        THROW;  
  
    END CATCH  
  
END;  