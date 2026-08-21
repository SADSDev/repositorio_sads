USE [DataMart]
GO

/****** Object:  Table [PowerStreet].[ITO_Detallado]    Script Date: 20/08/2026 12:23:41 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[POWERSTREET_ITO_Detallado](
	[CLO] [int] NULL,
	[Agencia] [varchar](100) NOT NULL,
	[NUR] [varchar](20) NOT NULL,
	[Vendedor] [varchar](100) NOT NULL,
	[Fecha] [date] NOT NULL,
	[Secuencia_ITO] [int] NULL,
	[Secuencia_Real] [int] NULL,
	[Cliente] [varchar](50) NOT NULL,
	[Nombre_Cliente] [varchar](200) NULL,
	[id_Visita] [varchar](100) NULL,
	[Estatus] [varchar](50) NOT NULL,
	[Apertura] [varchar](20) NULL,
	[Cierre] [varchar](20) NULL,
	[Inicio_de_visita] [time](7) NULL,
	[Fin_de_visita] [time](7) NULL,
	[Tiempo_de_estancia_en_visita] [int] NULL,
	[Tiempo_translado] [int] NULL,
	[Visita_efectiva] [varchar](5) NOT NULL,
	[Visitas_Geocerca] [int] NULL,
	[Visitas_Totales] [int] NULL,
	[Visitas_Programadas] [int] NULL,
	[Visitas_Unicas_ITO] [int] NULL
) ON [PRIMARY]
GO