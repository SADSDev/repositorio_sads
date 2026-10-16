USE [DataMart]
GO

/****** Objeto: Table [PWST].[POWERSTREET_Libros] Fecha de script: 16/10/2026 11:49:11 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[POWERSTREET_Libros](
	[Agencia] [int] NOT NULL,
	[Vendedor] [varchar](30) NULL,
	[Cliente] [varchar](30) NULL,
	[Frecuencia] [varchar](5) NULL,
	[Orden] [int] NULL,
	[Fecha_Actualizacion] [date] NULL,
	[Cliente2] [varchar](50) NULL,
	[Nombre] [varchar](300) NULL,
	[Direccion] [varchar](300) NULL,
	[Colonia] [varchar](300) NULL,
	[Estado] [varchar](300) NULL,
	[Municipio] [varchar](300) NULL,
	[Sucursal] [varchar](100) NULL,
	[Dato] [int] NULL
) ON [PRIMARY]
GO
