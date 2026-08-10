DROP TABLE IF EXISTS CATALOGOS.Objetivos_Fijos_Rutas;
GO

CREATE TABLE CATALOGOS.Objetivos_Fijos_Rutas
(
    NUR VARCHAR(20) NOT NULL,
    CategoriaId TINYINT NOT NULL,
    Indicador VARCHAR(100) NOT NULL,
    Valor_Objetivo DECIMAL(18,4) NOT NULL,

    CONSTRAINT PK_Objetivos_Fijos_Rutas
        PRIMARY KEY (NUR, Indicador),

    CONSTRAINT FK_Objetivos_Fijos_Rutas_Categoria
        FOREIGN KEY (CategoriaId)
        REFERENCES CATALOGOS.Categorias_Indicador(CategoriaId)
);
GO