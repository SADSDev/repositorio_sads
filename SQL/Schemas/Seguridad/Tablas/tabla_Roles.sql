CREATE TABLE Seguridad.Roles
(
    RolId       INT IDENTITY(1,1) PRIMARY KEY,
    Rol         VARCHAR(50) NOT NULL UNIQUE
);