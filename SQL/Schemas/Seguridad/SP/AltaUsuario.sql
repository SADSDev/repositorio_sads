CREATE OR ALTER PROCEDURE PWST.SEGURIDAD_AltaUsuario  
(  
    @usuario         VARCHAR(50),  
    @contrasena      VARCHAR(100),  
    @nombreCompleto  VARCHAR(150),  
    @AplicacionId    INT,  
    @rolId             INT,  
    @agencia         INT = NULL,  
    @grupo           VARCHAR(50) = NULL,  
    @NUR             VARCHAR(20) = NULL,
    @permisos        VARCHAR(MAX),
    @recursos        VARCHAR(MAX)  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    DECLARE @UsuarioId INT;  
    DECLARE @UsuarioAplicacionId INT;  
    DECLARE @Ruta VARCHAR(10);  
  
    BEGIN TRY  
  
        -------------------------------------------------------  
        -- Validaciones  
        -------------------------------------------------------  
        --validar que el nombre de usuario o nombre completo no existan
        IF EXISTS  
        (  
            SELECT 1  
            FROM PWST.SEGURIDAD_Usuarios  
            WHERE NombreCompleto = @nombreCompleto OR NombreUsuario=@usuario  
        )
        BEGIN  
            THROW 50001, 'Ya existe un usuario con ese Nombr.', 1;  
        END;  
        --validar que hayan sido agregados datos necesarios para funcionar
        IF NOT EXISTS
        (
            SELECT 1
            FROM PWST.SEGURIDAD_Roles
            WHERE RolId = @RolId
        )
        BEGIN
            THROW 50001, 'Ese Rol no existe', 1;
        END;

        -- Validar que el usuario tenga los filtros necesarios
        IF @RolId = 6
        AND (@Agencia IS NULL OR @Grupo IS NULL OR @NUR IS NULL)
        BEGIN
            THROW 50001, 'El tipo de usuario escogido necesita agencia, grupo y ruta', 1;
        END;
        IF @RolId = 5
        AND (@Agencia IS NULL OR @Grupo IS NULL)
        BEGIN
            THROW 50001, 'El tipo de usuario escogido necesita agencia y grupo', 1;
        END;
        IF @RolId = 4
        AND @Agencia IS NULL
        BEGIN
            THROW 50001, 'El tipo de usuario escogido necesita agencia', 1;
        END;
        
        -------------------------------------------------------  
        -- Obtener Ruta a partir del NUR y rol 
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
        -- Iniciar transacción  de proceso de alta usuario
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
            @rolId,  
            @agencia,  
            @grupo,  
            @Ruta  
        );  
  
        SET @UsuarioAplicacionId = SCOPE_IDENTITY();  
  
  
        -------------------------------------------------------  
        -- 3. Copiar permisos  y recursos del rol al usuario  
        -------------------------------------------------------  
        SELECT
            TRY_CAST(P.[value] AS INT) AS PermisoId,
            TRY_CAST(R.[value] AS INT) AS RecursoId
        INTO #RecursosPermisos
        FROM OPENJSON('["' + REPLACE(@permisos, ',', '","') + '"]') P
        INNER JOIN OPENJSON('["' + REPLACE(@recursos, ',', '","') + '"]') R
            ON P.[key] = R.[key];
            
        
        INSERT INTO PWST.SEGURIDAD_UsuarioPermisos
        (
            UsuarioAplicacionId,
            PermisoId
        )
        SELECT
            @UsuarioAplicacionId,
            PermisoId
        FROM
        (
            SELECT RP.PermisoId
            FROM PWST.SEGURIDAD_RolPermisos RP
            WHERE RP.RolId = @RolId

            UNION

            SELECT TRY_CAST(PermisoId AS INT)
            FROM #RecursosPermisos
        ) AS Permisos;

        INSERT INTO PWST.SEGURIDAD_UsuarioRecursos
        (
            UsuarioAplicacionId,
            RecursoId
        )
        SELECT
            @UsuarioAplicacionId,
            RecursoId
        FROM
        (
            SELECT RR.RecursoId
            FROM PWST.SEGURIDAD_RolRecursos RR
            WHERE RR.RolId = @RolId

            UNION

            SELECT TRY_CAST(RecursoId AS INT)
            FROM #RecursosPermisos
        ) AS Recursos;
  
  
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