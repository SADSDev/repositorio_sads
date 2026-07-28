CREATE TABLE SADS.SegOper_ObjetivosMensualesVariables
(
    Fecha       DATE            NOT NULL,
    NUR         VARCHAR(20)     NOT NULL,
    Nombre_Meta VARCHAR(100)    NOT NULL,
    Meta        DECIMAL(18,2)   NOT NULL,

    CONSTRAINT PK_SegOper_ObjetivosMensualesVariables
        PRIMARY KEY (Fecha, NUR, Nombre_Meta),

    CONSTRAINT FK_SegOper_ObjetivosMensualesVariables_Ruta
        FOREIGN KEY (NUR)
        REFERENCES CATALOGOS.Rutas_Evaluables (NUR)
);
