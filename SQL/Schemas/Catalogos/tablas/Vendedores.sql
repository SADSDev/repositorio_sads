USE [DataMart]
GO

/****** Object:  Table [CATALOGOS].[Vendedores]    Script Date: 20/08/2026 12:09:45 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[CATALOGOS_Vendedores](
	[Codigo_de_Vendedor] [varchar](50) NOT NULL,
	[Ruta] [varchar](50) NULL,
	[Agencia] [int] NULL,
	[Grupo] [varchar](50) NULL,
	[Oficina] [varchar](50) NULL,
	[Operacion] [varchar](50) NULL,
	[NUR] [varchar](50) NULL
) ON [PRIMARY]
GO
