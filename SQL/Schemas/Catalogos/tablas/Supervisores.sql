CREATE TABLE PWST.CATALOGOS_Supervisores
(
    Codigo VARCHAR(20) NOT NULL,
    NUR VARCHAR(20) NOT NULL,
    Grupo VARCHAR(50) NOT NULL,
    Agencia INT NOT NULL,

    CONSTRAINT PK_CATALOGOS_Supervisores
        PRIMARY KEY (Codigo),

    CONSTRAINT FK_CATALOGOS_Supervisores_Agencia
        FOREIGN KEY (Agencia)
        REFERENCES PWST.CATALOGOS_Agencias (Agencia)
);
GO