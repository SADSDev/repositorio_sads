USE [DataMart]
GO

/****** Object:  Table [PWST].[ANALYTICS_SimulacionesVentas]    Script Date: 10/09/2026 09:03:17 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[ANALYTICS_SimulacionesVentas](
	[Simulacion] [int] NOT NULL,
	[Agencia] [int] NOT NULL,
	[NUR] [varchar](20) NOT NULL,
	[Fecha] [date] NOT NULL,
	[Error] [decimal](18, 6) NOT NULL,
	[Volumen_Simulado] [decimal](18, 6) NULL,
 CONSTRAINT [PK_ANALYTICS_SimulacionesVentas] PRIMARY KEY CLUSTERED 
(
	[Simulacion] ASC,
	[NUR] ASC,
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO