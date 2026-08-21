USE [DataMart]
GO

/****** Object:  Table [CATALOGOS].[Frecuencias_Reportes]    Script Date: 20/08/2026 10:52:16 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[CATALOGOS_Frecuencias_Reportes](
	[FrecuenciaId] [tinyint] NOT NULL,
	[Frecuencia] [varchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[FrecuenciaId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO




INSERT INTO CATALOGOS.Frecuencias_Reportes
(
    FrecuenciaId,
    Frecuencia
)
VALUES
(1, 'Diaria'),
(2, 'Semanal'),
(3, 'Mensual');