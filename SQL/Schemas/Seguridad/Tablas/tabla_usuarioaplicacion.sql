CREATE TABLE Seguridad.UsuarioAplicacion
(
    UsuarioAplicacionId INT IDENTITY(1,1) NOT NULL,

    UsuarioId INT NOT NULL,
    AplicacionId INT NOT NULL,
    RolId INT NOT NULL,

    Agencia INT NULL,
    Grupo VARCHAR(50) NULL,
    Ruta VARCHAR(10) NULL,

    CONSTRAINT PK_UsuarioAplicacion
        PRIMARY KEY (UsuarioAplicacionId),

    CONSTRAINT UQ_UsuarioAplicacion
        UNIQUE (UsuarioId, AplicacionId),

    CONSTRAINT FK_UsuarioAplicacion_Usuarios
        FOREIGN KEY (UsuarioId)
        REFERENCES Seguridad.Usuarios(Id),

    CONSTRAINT FK_UsuarioAplicacion_Aplicaciones
        FOREIGN KEY (AplicacionId)
        REFERENCES Seguridad.Aplicaciones(Id),

    CONSTRAINT FK_UsuarioAplicacion_Roles
        FOREIGN KEY (RolId)
        REFERENCES Seguridad.Roles(RolId)
);
GO