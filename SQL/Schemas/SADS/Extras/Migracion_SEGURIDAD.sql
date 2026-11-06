-- Zac, inserta los datos de las tablas del schema de SEGURIDAD
-- en el siguiente orden



INSERT INTO [PWST].[SEGURIDAD_Operaciones]
(
    Operacion
)
VALUES 
    ('OPERACION');


INSERT INTO [PWST].[SEGURIDAD_Aplicaciones]
(
    Nombre,
    Descripcion,
    Activo
)
VALUES 
    ('SADS', 'Sistema de Reportes y herramientas de analisis', '1');

INSERT INTO [PWST].[SEGURIDAD_Recursos]
(
    AplicacionId,
    Recurso,
    Ruta,
    Operacion
)
VALUES
    (1, 'Asignador de metas', 'ventanas/asignador_metas.vue', 'OPERACION'),
    (1, 'Reporte por cliente', 'pages/ventas.vue', 'OPERACION'),
    (1, 'Reporte seguimiento operación de rutas' 'pages/seguimiento_operacion_rutas.vue', 'OPERACION'),
    (1,'Catalogos-Sábana', 'pages/sabana.vue', 'OPERACION'),
    (1,'Catalogos-Supervisores','pages/supervisores.vue', 'OPERACION');

INSERT INTO [PWST].[SEGURIDAD_Roles]
(
    Rol
)
VALUES
    ('Administrador'),
    ('Director'),
    ('Gerente de sector'),
    ('Gerente Regional'),
    ('Supervisor'),
    ('Operación');

INSERT INTO [PWST].[SEGURIDAD_Permisos]
(
    Permiso
)
VALUES
    ('Filtrar Agencias'),
    ('Filtrar zona de supervisor'),
    ('Filtrar ruta'),
    ('Editar metas de Venta-ruta');

INSERT INTO PWST.SEGURIDAD_RolRecursos
(
    RolId,
    RecursoId
)
VALUES
    (1, 1),
    (1, 2),
    (1, 3),
    (1, 4),
    (1, 5),
    (2, 1),
    (2, 2),
    (2, 3),
    (2, 4),
    (2, 5),
    (3, 1),
    (3, 2),
    (3, 3),
    (3, 4),
    (3, 5),
    (4, 1),
    (4, 2),
    (4, 3),
    (4, 4),
    (4, 5),
    (5, 2),
    (5, 3);

INSERT INTO PWST.SEGURIDAD_RolPermisos
(
    RolId,
    PermisoId
)
VALUES
    (1, 1),
    (1, 2),
    (1, 3),
    (1, 4),
    (2, 1),
    (2, 2),
    (2, 3),
    (2, 4),
    (3, 1),
    (3, 2),
    (3, 3),
    (3, 4),
    (4, 2),
    (4, 3),
    (4, 4),
    (5, 3); 


---------------------------------------------------
-- USUARIOS A LOS QUE SE LES DARÁ DE ALTA
---------------------------------------------------
EXEC PWST.SEGURIDAD_AltaUsuario
    @usuario='edsondlrc',
    @contrasena='Eadlrc123#',
    @nombreCompleto='Edson Alejandro de la Rosa Cuellar',
    @AplicacionId=1,
    @rolId=1,
    @agencia=NULL,
    @grupo=NULL,
    @NUR=NULL,
    @permisos='',
    @recursos=''

EXEC PWST.SEGURIDAD_AltaUsuario
    @usuario='marioigg',
    @contrasena='MSodsmty1#',
    @nombreCompleto='Mario Iván Gamez Gutierrez',
    @AplicacionId=1,
    @rolId=4,
    @agencia=8,
    @grupo=NULL,
    @NUR=NULL,
    @permisos='1, 2, 3, 4',
    @recursos=''

EXEC PWST.SEGURIDAD_AltaUsuario
    @usuario='gerardoam',
    @contrasena='Sod$coa2%',
    @nombreCompleto='Gerardo Arizpe Melendez',
    @AplicacionId=1,
    @rolId=4,
    @agencia=4,
    @grupo=NULL,
    @NUR=NULL,
    @permisos='1, 2, 3, 4',
    @recursos=''

EXEC PWST.SEGURIDAD_AltaUsuario
    @usuario='josefeg',
    @contrasena='GerSod1$%',
    @nombreCompleto='Jose Francisco Espinosa Garay',
    @AplicacionId=1,
    @rolId=3,
    @agencia=NULL,
    @grupo=NULL,
    @NUR=NULL,
    @permisos='',
    @recursos=''

EXEC PWST.SEGURIDAD_AltaUsuario
    @usuario='edgarhmm',
    @contrasena='SodD1r&!',
    @nombreCompleto='Edgar Horacio Maldonado Morfin',
    @AplicacionId=1,
    @rolId=2,
    @agencia=NULL,
    @grupo=NULL,
    @NUR=NULL,
    @permisos='',
    @recursos=''

EXEC PWST.SEGURIDAD_AltaUsuario
    @usuario='supmty01',
    @contrasena='Sd8#673',
    @nombreCompleto='Supervisor Monterrey 1',
    @AplicacionId=1,
    @rolId=5,
    @agencia=8,
    @grupo='SECTOR 1',
    @NUR=NULL,
    @permisos='',
    @recursos=''

EXEC PWST.SEGURIDAD_AltaUsuario
    @usuario='supmty02',
    @contrasena='Xf934$',
    @nombreCompleto='Supervisor Monterrey 2',
    @AplicacionId=1,
    @rolId=5,
    @agencia=8,
    @grupo='SECTOR 2',
    @NUR=NULL,
    @permisos='',
    @recursos=''

EXEC PWST.SEGURIDAD_AltaUsuario
    @usuario='supmty03',
    @contrasena='94f%k',
    @nombreCompleto='Supervisor Monterrey 3',
    @AplicacionId=1,
    @rolId=5,
    @agencia=8,
    @grupo='SECTOR 3',
    @NUR=NULL,
    @permisos='',
    @recursos=''

EXEC PWST.SEGURIDAD_AltaUsuario
    @usuario='supmty04',
    @contrasena='#Vmp43',
    @nombreCompleto='Supervisor Monterrey 4',
    @AplicacionId=1,
    @rolId=5,
    @agencia=8,
    @grupo='SECTOR 4',
    @NUR=NULL,
    @permisos='',
    @recursos=''

EXEC PWST.SEGURIDAD_AltaUsuario
    @usuario='lzacarias',
    @contrasena='Lezo5270',
    @nombreCompleto='Luis Zacarias',
    @AplicacionId=1,
    @rolId=1,
    @agencia=NULL,
    @grupo=NULL,
    @NUR=NULL,
    @permisos='',
    @recursos=''