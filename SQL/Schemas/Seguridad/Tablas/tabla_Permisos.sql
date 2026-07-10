CREATE TABLE Seguridad.Permisos
(
    PermisoId   INT IDENTITY(1,1) PRIMARY KEY,
    Permiso     VARCHAR(150) NOT NULL UNIQUE
);