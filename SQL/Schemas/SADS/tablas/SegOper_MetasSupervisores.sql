USE [DataMart];
GO

CREATE TABLE [PWST].[SADS_SegOper_MetasSupervisor] (
    [Mes]         [date]          NOT NULL,
    [Agencia]       [tinyint]    NOT NULL,
    [Grupo]       [varchar](20)  NOT NULL,
    [CategoriaId] [tinyint]       NOT NULL,
    [Indicador]   [varchar](100)  NOT NULL,
    [Valor_Meta]  [decimal](18,4) NOT NULL,

    CONSTRAINT [PK_SADS_SegOper_MetasSupervisores]
        PRIMARY KEY CLUSTERED (
            [Mes],
            [Agencia],
            [CategoriaId],
            [Indicador]
        ),

    CONSTRAINT [FK_MetasSupervisores_Categoria]
        FOREIGN KEY ([CategoriaId])
        REFERENCES [PWST].[CATALOGOS_Categorias_Indicador] ([CategoriaId])
);
GO