USE [DataMart]
GO

/****** Object:  Table [CATALOGOS].[Articulos]    Script Date: 20/08/2026 10:34:10 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[CATALOGOS_Articulos](
	[Codigo] [varchar](50) NOT NULL,
	[Articulo] [varchar](100) NULL,
	[Descripcion_Hand_Held] [varchar](100) NULL,
	[Familia] [varchar](80) NULL,
	[Unidades] [int] NULL,
 CONSTRAINT [PK_Articulos] PRIMARY KEY CLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
