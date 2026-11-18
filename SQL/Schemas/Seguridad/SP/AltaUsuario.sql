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
            RAISERROR('Ya existe un usuario con ese Nombre.', 16, 1);
            RETURN;
        END;  
        --validar que hayan sido agregados datos necesarios para funcionar
        IF NOT EXISTS
        (
            SELECT 1
            FROM PWST.SEGURIDAD_Roles
            WHERE RolId = @RolId
        )
        BEGIN
            RAISERROR('Ese Rol no existe', 16, 1);
            RETURN;
        END;

        -- Validar que el usuario tenga los filtros necesarios
        IF @RolId = 6
        AND (@Agencia IS NULL OR @Grupo IS NULL OR @NUR IS NULL)
        BEGIN
            RAISERROR('El tipo de usuario escogido necesita agencia, grupo y ruta', 16, 1);
            RETURN;
        END;
        IF @RolId = 5
        AND (@Agencia IS NULL OR @Grupo IS NULL)
        BEGIN
            RAISERROR('El tipo de usuario escogido necesita agencia y grupo', 16, 1);
            RETURN;
        END;
        IF @RolId = 4
        AND @Agencia IS NULL
        BEGIN
            RAISERROR('El tipo de usuario escogido necesita agencia', 16, 1);
            RETURN;
        END;
        
        -------------------------------------------------------  
        -- Obtener Ruta a partir del NUR y rol 
        -------------------------------------------------------  
        IF @NUR IS NOT NULL  
        BEGIN  
            SET @Ruta =  
                'R' +
                    SUBSTRING(  
                        @NUR,  
                        PATINDEX('%[A-Z]%', @NUR) + 1,  
                        LEN(@NUR)  
                    );
        END  
        ELSE  
        BEGIN  
            SET @Ruta = NULL;  
        END;    

        -- Las listas deben contener solamente enteros separados por comas.
        SET @permisos = REPLACE(ISNULL(@permisos, ''), ' ', '');
        SET @recursos = REPLACE(ISNULL(@recursos, ''), ' ', '');

        IF @permisos LIKE '%[^0-9,]%'
           OR @recursos LIKE '%[^0-9,]%'
        BEGIN
            RAISERROR('Permisos y recursos deben ser listas de enteros separados por comas.', 16, 1);
            RETURN;
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
        DECLARE @PermisosXml XML;
        DECLARE @RecursosXml XML;

        SET @PermisosXml = CAST(
            '<root><item>'
            + REPLACE(@permisos, ',', '</item><item>')
            + '</item></root>'
            AS XML
        );

        SET @RecursosXml = CAST(
            '<root><item>'
            + REPLACE(@recursos, ',', '</item><item>')
            + '</item></root>'
            AS XML
        );

        ------------------------------------------------
        -- CTE´s de permisos y resursos a asignar 
        -----------------------------------------------
        ;WITH Permisos AS
        (
            SELECT
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Posicion,
                LTRIM(RTRIM(Nodo.Item.value('.', 'VARCHAR(20)'))) AS Valor
            FROM @PermisosXml.nodes('/root/item') Nodo(Item)
        ),

        Recursos AS
        (
            SELECT
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Posicion,
                LTRIM(RTRIM(Nodo.Item.value('.', 'VARCHAR(20)'))) AS Valor
            FROM @RecursosXml.nodes('/root/item') Nodo(Item)
        )

        ------------------------------------------------
        -- declaración de tabla temporal de permisos
        -- y recursos a asignar al usuario
        ----------------------------------------------- 
        SELECT
            CASE
                WHEN P.Valor <> ''
                 AND P.Valor NOT LIKE '%[^0-9]%'
                 AND LEN(P.Valor) <= 9
                THEN CONVERT(INT, P.Valor)
                ELSE NULL
            END AS PermisoId,
            CASE
                WHEN R.Valor <> ''
                 AND R.Valor NOT LIKE '%[^0-9]%'
                 AND LEN(R.Valor) <= 9
                THEN CONVERT(INT, R.Valor)
                ELSE NULL
            END AS RecursoId
        INTO #RecursosPermisos
        FROM Permisos P
        INNER JOIN Recursos R
            ON P.Posicion = R.Posicion;
            
        --------------------------------------------
        --Insert de permisos y recursos a tablas de SEGURIDAD

        --si @permisos y @recursos se enviaron NULL se le asignaran
        ---los permisos y recursos default correspondientes al @rolId ingresado
        --------------------------------------------        
        -- Insertar permisos
        IF @permisos IS NULL
        BEGIN
            INSERT INTO PWST.SEGURIDAD_UsuarioPermisos
            (
                UsuarioAplicacionId,
                PermisoId
            )
            SELECT
                @UsuarioAplicacionId,
                RP.PermisoId
            FROM PWST.SEGURIDAD_RolPermisos RP
            WHERE RP.RolId = @RolId;
        END
        ELSE
        BEGIN
            INSERT INTO PWST.SEGURIDAD_UsuarioPermisos
            (
                UsuarioAplicacionId,
                PermisoId
            )
            SELECT
                @UsuarioAplicacionId,
                PermisoId
            FROM #RecursosPermisos
            WHERE PermisoId IS NOT NULL;
        END;


        -- Insertar recursos
        IF @recursos IS NULL
        BEGIN
            INSERT INTO PWST.SEGURIDAD_UsuarioRecursos
            (
                UsuarioAplicacionId,
                RecursoId
            )
            SELECT
                @UsuarioAplicacionId,
                RR.RecursoId
            FROM PWST.SEGURIDAD_RolRecursos RR
            WHERE RR.RolId = @RolId;
        END
        ELSE
        BEGIN
            INSERT INTO PWST.SEGURIDAD_UsuarioRecursos
            (
                UsuarioAplicacionId,
                RecursoId
            )
            SELECT
                @UsuarioAplicacionId,
                RecursoId
            FROM #RecursosPermisos
            WHERE RecursoId IS NOT NULL;
        END;
 
  
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
  
        DECLARE @ErrorMensaje NVARCHAR(4000);
        DECLARE @ErrorSeveridad INT;
        DECLARE @ErrorEstado INT;

        SELECT
            @ErrorMensaje = ERROR_MESSAGE(),
            @ErrorSeveridad = ERROR_SEVERITY(),
            @ErrorEstado = ERROR_STATE();

        RAISERROR(@ErrorMensaje, @ErrorSeveridad, @ErrorEstado);
  
    END CATCH  
  
END;
