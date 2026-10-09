USE [DataMart]
GO

/****** Objeto: Table [PWST].[CATALOGOS_Vendedores] Fecha de script: 09/10/2026 04:08:49 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[CATALOGOS_Vendedores](
	[Codigo] [varchar](50) NOT NULL,
	[Ruta] [varchar](50) NULL,
	[Agencia] [int] NULL,
	[Grupo] [varchar](50) NULL,
	[Oficina] [varchar](50) NULL,
	[Operacion] [varchar](50) NULL,
	[NUR] [varchar](50) NOT NULL,
	[Evaluable] [int] NOT NULL,
 CONSTRAINT [PK_CATALOGOS_Vendedores] PRIMARY KEY CLUSTERED 
(
	[NUR] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

