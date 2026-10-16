CREATE TABLE PWST.SEGURIDAD_Recursos
(
    RecursoId INT IDENTITY(1,1) NOT NULL,
    Aplicacion_Id INT NOT NULL,
    Recurso VARCHAR(150) NOT NULL,
    Ruta VARCHAR(250) NOT NULL,
    Operacion VARCHAR(100) NOT NULL,

    CONSTRAINT PK_SEGURIDAD_Recursos
        PRIMARY KEY (RecursoId),

    CONSTRAINT FK_SEGURIDAD_Recursos_Aplicaciones
        FOREIGN KEY (Aplicacion_Id)
        REFERENCES PWST.SEGURIDAD_Aplicaciones (Id)
);