CREATE TABLE CATALOGOS.Objetivos_Fijos_Rutas
(
    NUR VARCHAR(20) NOT NULL,
    Objetivo_Mensual_Visitas DECIMAL(9,4) NOT NULL,

    CONSTRAINT PK_Objetivos_Visitas
        PRIMARY KEY (NUR),

    CONSTRAINT FK_Objetivos_Visitas_RutasEvaluables
        FOREIGN KEY (NUR)
        REFERENCES CATALOGOS.Rutas_Evaluables(NUR)
);