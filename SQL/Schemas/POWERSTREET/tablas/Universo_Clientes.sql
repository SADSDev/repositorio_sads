USE [DataMart]
GO

/****** Object:  Table [PowerStreet].[Universo_Clientes]    Script Date: 20/08/2026 12:34:26 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[POWERSTREET_Universo_Clientes](
	[Distribuidor] [int] NOT NULL,
	[Agencia] [int] NOT NULL,
	[Codigo_GLN] [varchar](20) NOT NULL,
	[Codigo_Pwst] [varchar](20) NULL,
	[Fecha_Actualizacion] [date] NOT NULL,
	[Itinerarios] [varchar](50) NULL,
	[Frecuencia] [tinyint] NULL,
	[Lunes] [int] NULL,
	[Martes] [int] NULL,
	[Miercoles] [int] NULL,
	[Jueves] [int] NULL,
	[Viernes] [int] NULL,
	[Sabado] [int] NULL,
	[Nombre] [varchar](300) NULL,
	[Colonia] [varchar](300) NULL,
	[Direccion] [varchar](300) NULL,
	[Potencial] [varchar](100) NULL,
	[Estado] [varchar](200) NULL,
	[Municipio] [varchar](200) NULL,
	[Zona] [int] NULL,
	[ZonaVent] [int] NULL,
	[ZonaRepa] [int] NULL,
	[TipoCliente] [varchar](100) NULL,
	[Canal] [varchar](200) NULL,
	[Lista] [varchar](250) NULL,
	[X] [numeric](18, 9) NULL,
	[Y] [numeric](18, 9) NULL,
	[Codigo_MKD] [varchar](60) NULL,
	[Baja] [varchar](60) NULL,
	[Potencial_MKD] [varchar](60) NULL,
	[Censo] [varchar](60) NULL,
	[Status] [varchar](60) NULL,
	[NUR] [varchar](30) NULL,
	[Tipo_Credito] [varchar](100) NULL,
	[Programa] [varchar](200) NULL,
	[Telefono_Cliente] [varchar](100) NULL,
	[Telefono_Mensajes] [varchar](100) NULL,
	[CorreoElectronico] [varchar](250) NULL,
 CONSTRAINT [PK_Clientes] PRIMARY KEY CLUSTERED 
(
	[Codigo_GLN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [PWST].[POWERSTREET_Universo_Clientes]  WITH CHECK ADD  CONSTRAINT [FK_Clientes_Agencias] FOREIGN KEY([Agencia])
REFERENCES [PWST].[CATALOGOS_Agencias] ([Agencia])
GO

ALTER TABLE [PWST].[POWERSTREET_Universo_Clientes] CHECK CONSTRAINT [FK_Clientes_Agencias]
GO