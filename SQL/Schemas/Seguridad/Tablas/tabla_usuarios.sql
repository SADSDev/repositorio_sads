CREATE TABLE Seguridad.Usuarios
(
    Id INT IDENTITY(1,1) NOT NULL,

    NombreUsuario      VARCHAR(50)  NOT NULL,
    Contrasena         VARCHAR(50)  NOT NULL,
    NombreCompleto     VARCHAR(150) NOT NULL,

    Activo             BIT NOT NULL
        CONSTRAINT DF_Usuarios_Activo DEFAULT(1),

    FechaCreacion      DATETIME2 NOT NULL
        CONSTRAINT DF_Usuarios_FechaCreacion DEFAULT(GETDATE()),

    CONSTRAINT PK_Usuarios
        PRIMARY KEY (Id),

    CONSTRAINT UQ_Usuarios_NombreUsuario
        UNIQUE (NombreUsuario)
);
GO

