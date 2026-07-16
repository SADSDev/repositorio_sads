

CREATE TABLE Seguridad.UsuarioAplicacion
(
    UsuarioId      INT NOT NULL,
    AplicacionId   INT NOT NULL,
    RolId          INT NOT NULL,
    Agencia        INT,
    Zona           VARCHAR(50),
    Ruta           VARCHAR(10),

    CONSTRAINT PK_UsuarioAplicacion
        PRIMARY KEY (UsuarioId, AplicacionId),

    CONSTRAINT FK_UsuarioAplicacion_Usuario
        FOREIGN KEY (UsuarioId)
        REFERENCES Seguridad.Usuarios(Id),

    CONSTRAINT FK_UsuarioAplicacion_Aplicacion
        FOREIGN KEY (AplicacionId)
        REFERENCES Seguridad.Aplicaciones(Id)
);
GO