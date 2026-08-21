USE [DataMart]
GO

/****** Object:  Table [PowerStreet].[Venta_Diaria]    Script Date: 20/08/2026 12:37:44 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[POWERSTREET_Venta_Diaria](
	[Fecha] [date] NOT NULL,
	[NUR] [varchar](20) NOT NULL,
	[Vendedor] [varchar](10) NOT NULL,
	[Cliente] [varchar](20) NOT NULL,
	[Nombre_Cliente] [varchar](200) NULL,
	[Potencial] [varchar](10) NULL,
	[Codigo_Articulo] [varchar](20) NOT NULL,
	[Descripcion_Articulo] [varchar](100) NOT NULL,
	[Cantidad] [decimal](12, 4) NOT NULL,
	[Total] [decimal](12, 4) NOT NULL
) ON [PRIMARY]
GO