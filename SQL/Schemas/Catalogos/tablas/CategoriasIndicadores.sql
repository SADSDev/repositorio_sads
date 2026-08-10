CREATE TABLE CATALOGOS.Categorias_Indicador
(
    CategoriaId TINYINT NOT NULL
        CONSTRAINT PK_Categorias_Indicador PRIMARY KEY,

    Categoria VARCHAR(50) NOT NULL
        CONSTRAINT UQ_Categorias_Indicador UNIQUE
);