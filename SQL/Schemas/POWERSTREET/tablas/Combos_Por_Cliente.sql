USE [DataMart]
GO

/****** Object:  Table [PowerStreet].[Combos_Por_Cliente]    Script Date: 20/08/2026 12:14:27 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[POWERSTREET_Combos_Por_Cliente](
	[Fecha] [date] NOT NULL,
	[NUR] [varchar](20) NOT NULL,
	[Codigo_Cliente] [varchar](20) NOT NULL,
	[Nombre_Cliente] [varchar](200) NULL,
	[Direccion] [varchar](300) NULL,
	[Potencial] [varchar](10) NULL,
	[Codigo_Combo] [varchar](20) NOT NULL,
	[Descripcion_Combo] [varchar](500) NULL,
	[Cantidad_Combos] [int] NOT NULL,
	[Total] [decimal](18, 3) NOT NULL
) ON [PRIMARY]
GO
