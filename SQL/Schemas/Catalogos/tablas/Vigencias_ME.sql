USE [DataMart]
GO

/****** Object:  Table [CATALOGOS].[Vigencias_ME]    Script Date: 20/08/2026 12:11:44 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[CATALOGOS_Vigencias_ME](
	[Familia] [nvarchar](50) NULL,
	[Inicio_Vigencia] [date] NOT NULL,
	[Fin_Vigencia] [date] NULL,
	[Agencia] [int] NULL
) ON [PRIMARY]
GO
