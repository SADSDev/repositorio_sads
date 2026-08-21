USE [DataMart]
GO

/****** Object:  Table [PowerStreet].[Libros]    Script Date: 20/08/2026 12:25:39 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[POWERSTREET_Libros](
	[Vendedor] [varchar](30) NULL,
	[Cliente] [varchar](30) NOT NULL,
	[Frecuencia] [varchar](5) NULL,
	[Orden] [int] NULL,
	[Fecha_Actualizacion] [date] NULL,
	[Cliente2] [varchar](20) NULL,
	[Nombre] [varchar](100) NULL,
	[Direccion] [varchar](200) NULL,
	[Colonia] [varchar](100) NULL,
	[Estado] [varchar](50) NULL,
	[Municipio] [varchar](50) NULL,
	[Sucursal] [int] NULL
) ON [PRIMARY]
GO
