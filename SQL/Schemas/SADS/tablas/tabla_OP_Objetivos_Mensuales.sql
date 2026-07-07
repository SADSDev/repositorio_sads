CREATE TABLE SADS.SegOper_Objetivos_Mensuales
(
    Fecha               DATE            NOT NULL,
    NUR                 VARCHAR(20)     NOT NULL,
    Objetivo_Visitas    DECIMAL(10,3)   NOT NULL,

    CONSTRAINT PK_Objetivos_Mensuales
        PRIMARY KEY (Fecha, NUR),

    CONSTRAINT FK_Objetivos_Mensuales_Rutas
        FOREIGN KEY (NUR)
        REFERENCES CATALOGOS.Rutas_Evaluables(NUR),

    CONSTRAINT CK_Objetivos_Mensuales_PrimerDia
    CHECK (DAY(Fecha) = 1),

    CONSTRAINT UQ_OP_Objetivos_Mensuales
    UNIQUE (Fecha, NUR)

);