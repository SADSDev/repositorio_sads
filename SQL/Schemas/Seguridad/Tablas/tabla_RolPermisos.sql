CREATE TABLE Seguridad.RolPermisos
(
    RolId INT NOT NULL,
    PermisoId INT NOT NULL,

    CONSTRAINT PK_RolPermisos
        PRIMARY KEY (RolId, PermisoId),

    CONSTRAINT FK_RolPermisos_Roles
        FOREIGN KEY (RolId)
        REFERENCES Seguridad.Roles(RolId),

    CONSTRAINT FK_RolPermisos_Permisos
        FOREIGN KEY (PermisoId)
        REFERENCES Seguridad.Permisos(PermisoId)
);