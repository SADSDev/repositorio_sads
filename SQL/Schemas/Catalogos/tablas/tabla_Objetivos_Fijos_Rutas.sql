USE [DataMart]
GO

/****** Object:  Table [CATALOGOS].[Objetivos_Fijos_Rutas]    Script Date: 20/08/2026 10:55:12 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[CATALOGOS_Objetivos_Fijos_Rutas](
	[NUR] [varchar](20) NOT NULL,
	[CategoriaId] [tinyint] NOT NULL,
	[Indicador] [varchar](100) NOT NULL,
	[Valor_Objetivo] [decimal](18, 4) NOT NULL,
 CONSTRAINT [PK_Objetivos_Fijos_Rutas] PRIMARY KEY CLUSTERED 
(
	[NUR] ASC,
	[Indicador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [PWST].[CATALOGOS_Objetivos_Fijos_Rutas]  WITH CHECK ADD  CONSTRAINT [FK_Objetivos_Fijos_Rutas_Categoria] FOREIGN KEY([CategoriaId])
REFERENCES [PWST].[CATALOGOS_Categorias_Indicador] ([CategoriaId])
GO

ALTER TABLE [PWST].[CATALOGOS_Objetivos_Fijos_Rutas] CHECK CONSTRAINT [FK_Objetivos_Fijos_Rutas_Categoria]
GO