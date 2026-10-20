CREATE TABLE PWST.SEGURIDAD_UsuarioRecursos
(
    UsuarioAplicacionId INT NOT NULL,
    RecursoId INT NOT NULL,

    CONSTRAINT PK_SEGURIDAD_UsuarioRecursos
        PRIMARY KEY (UsuarioAplicacionId, RecursoId),

    CONSTRAINT FK_SEGURIDAD_UsuarioRecursos_UsuarioAplicacion
        FOREIGN KEY (UsuarioAplicacionId)
        REFERENCES PWST.SEGURIDAD_UsuarioAplicacion (UsuarioAplicacionId),

    CONSTRAINT FK_SEGURIDAD_UsuarioRecursos_Recursos
        FOREIGN KEY (RecursoId)
        REFERENCES PWST.SEGURIDAD_Recursos (RecursoId)
);