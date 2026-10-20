CREATE TABLE PWST.SEGURIDAD_UsuarioRecursos
(
    UsuarioAplicacionId INT NOT NULL,
    RecursoId INT NOT NULL,

    CONSTRAINT PK_SEGURIDAD_UsuarioRecursos
        PRIMARY KEY (UsuarioId, RecursoId),

    CONSTRAINT FK_SEGURIDAD_UsuarioRecursos_Usuarios
        FOREIGN KEY (UsuarioId)
        REFERENCES PWST.SEGURIDAD_Usuarios (Id),

    CONSTRAINT FK_SEGURIDAD_UsuarioRecursos_Recursos
        FOREIGN KEY (RecursoId)
        REFERENCES PWST.SEGURIDAD_Recursos (RecursoId)
);