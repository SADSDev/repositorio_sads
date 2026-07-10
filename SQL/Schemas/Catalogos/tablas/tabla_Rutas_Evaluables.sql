CREATE TABLE CATALOGOS.Rutas_Evaluables
(
    NUR         VARCHAR(20) NOT NULL,
    Agencia     INT NULL,
    Grupo       VARCHAR(20) NULL,

    CONSTRAINT PK_Rutas_Evaluables
        PRIMARY KEY (NUR),

    CONSTRAINT FK_RutasEvaluables_Agencias
        FOREIGN KEY (Agencia)
        REFERENCES CATALOGOS.Agencias(Agencia)
);
GO