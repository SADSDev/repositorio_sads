USE [DataMart]
GO

/****** Object:  Table [PowerStreet].[Seguimiento_Indicadores]    Script Date: 20/08/2026 12:29:44 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[POWERSTREET_Seguimiento_Indicadores](
	[Agencia] [varchar](200) NOT NULL,
	[Fecha] [date] NOT NULL,
	[NUR] [varchar](20) NOT NULL,
	[Dias_Trabajados] [int] NOT NULL,
	[Clientes_Universo] [int] NOT NULL,
	[Clientes_ITO] [int] NOT NULL,
	[Visitas_Programadas] [int] NOT NULL,
	[Total_Visitas] [int] NOT NULL,
	[Visitas_Fuera_ITO] [int] NOT NULL,
	[Clientes_Visitados] [int] NOT NULL,
	[Cobertura_Clientes_Universo] [decimal](12, 4) NOT NULL,
	[Indicador_Frecuencia] [decimal](12, 4) NOT NULL,
	[Eficiencia_ITO] [decimal](12, 4) NOT NULL,
	[Visitas_Con_Compras] [int] NOT NULL,
	[Efectividad_Visitas] [decimal](12, 4) NOT NULL,
	[Clientes_Con_Compras] [int] NOT NULL,
	[Efectividad_Compra] [decimal](12, 4) NOT NULL,
	[Total_Paquetes] [decimal](12, 4) NOT NULL,
	[Total_Cajetillas_Sin_Combos] [decimal](12, 4) NOT NULL,
	[Drop_Size_General] [decimal](12, 4) NOT NULL,
	[Drop_Size_Efectivo] [decimal](12, 4) NOT NULL,
	[Clientes_Con_Credito] [int] NOT NULL,
	[Promedio_Diario_Volumen] [decimal](12, 4) NOT NULL,
	[Promedio_Diario_Visitas] [decimal](12, 4) NOT NULL,
	[Fee_Distribucion] [decimal](12, 4) NOT NULL
) ON [PRIMARY]
GO