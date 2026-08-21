USE [DataMart]
GO

/****** Object:  Table [PowerStreet].[Fullfillment_Pedidos_PMM]    Script Date: 20/08/2026 12:17:59 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[POWERSTREET_Fullfillment_Pedidos_PMM](
	[NUR] [varchar](20) NOT NULL,
	[Fecha] [date] NOT NULL,
	[Vendedor] [varchar](20) NOT NULL,
	[Cliente] [varchar](20) NOT NULL,
	[Nombre] [varchar](250) NOT NULL,
	[Orden] [varchar](20) NOT NULL,
	[Status_Orden] [varchar](30) NOT NULL,
	[Documento_Orden] [varchar](100) NOT NULL,
	[Documento_Auxiliar] [varchar](100) NULL,
	[Status_Entrega] [varchar](30) NOT NULL,
	[Motivo_Rechazo] [varchar](250) NULL,
	[Total_Orden] [decimal](18, 4) NULL,
	[Cantidad_Orden] [decimal](18, 4) NULL,
	[Total_Entrega] [decimal](18, 4) NULL,
	[Cantidad_Entrega] [decimal](18, 4) NULL,
	[Cantidad_Contado] [decimal](18, 4) NULL,
	[Cantidad_Credito] [decimal](18, 4) NULL,
	[Total_Contado] [decimal](18, 4) NULL,
	[Total_Credito] [decimal](18, 4) NULL,
	[Fillrate] [decimal](10, 4) NULL,
	[Volumen_Entregado] [decimal](10, 4) NULL,
	[Fullfillment] [decimal](10, 4) NULL,
	[Empresa] [int] NOT NULL,
	[Clavecorr] [varchar](20) NOT NULL,
	[Serie] [varchar](20) NOT NULL,
	[Nrodoc] [varchar](20) NOT NULL,
	[Detalle] [varchar](100) NOT NULL
) ON [PRIMARY]
GO
