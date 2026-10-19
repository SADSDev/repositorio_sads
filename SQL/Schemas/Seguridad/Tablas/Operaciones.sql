CREATE TABLE PWST.SEGURIDAD_Operaciones
(
    OperacionId INT IDENTITY(1,1) NOT NULL,
    Operacion VARCHAR(100) NOT NULL,

    CONSTRAINT PK_SEGURIDAD_Operaciones
        PRIMARY KEY (OperacionId)
);