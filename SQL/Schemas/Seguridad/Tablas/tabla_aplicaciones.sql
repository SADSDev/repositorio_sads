
CREATE TABLE Seguridad.Aplicaciones
(
    Id INT IDENTITY(1,1) NOT NULL,

    Nombre        VARCHAR(100) NOT NULL,
    Descripcion   VARCHAR(250) NULL,

    Activo BIT NOT NULL
        CONSTRAINT DF_Aplicaciones_Activo DEFAULT(1),

    CONSTRAINT PK_Aplicaciones
        PRIMARY KEY (Id),

    CONSTRAINT UQ_Aplicaciones_Nombre
        UNIQUE (Nombre)
);
GO