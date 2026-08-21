USE [DataMart]
GO

/****** Object:  Table [PowerStreet].[ITO_Consolidado]    Script Date: 20/08/2026 12:20:19 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[POWERSTREET_ITO_Consolidado](
	[CLO] [int] NULL,
	[Agencia] [varchar](200) NOT NULL,
	[Fecha] [date] NOT NULL,
	[NUR] [varchar](20) NOT NULL,
	[Visitas_Geocerca] [int] NOT NULL,
	[Visitas_Totales] [int] NOT NULL,
	[Visitas_Efectivas] [int] NOT NULL,
	[Visitas_Programadas] [int] NOT NULL,
	[Visitas_Unicas_Dentro_ITO] [int] NOT NULL,
	[Pct_Geocerca] [decimal](10, 4) NOT NULL,
	[Pct_Cobertura_ITO] [decimal](10, 4) NOT NULL,
	[Pct_Strike_Rate] [decimal](10, 4) NOT NULL,
	[Visitas_Efectivas_MenorIgual_2min] [int] NOT NULL,
	[Pct_Visitas_Efectivas_MenorIgual_2min] [decimal](10, 4) NOT NULL,
	[Periodo] [varchar](35) NULL
) ON [PRIMARY]
GO