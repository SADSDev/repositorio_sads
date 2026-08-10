CREATE TABLE SADS.SegOper_Metas
(
    Fecha DATE NOT NULL,
    NUR VARCHAR(20) NOT NULL,
    CategoriaId TINYINT NOT NULL,
    Indicador VARCHAR(100) NOT NULL,
    Valor_Meta DECIMAL(18,4) NOT NULL,

    CONSTRAINT UQ_SegOper_Metas
        UNIQUE (Fecha, NUR, Indicador)
);