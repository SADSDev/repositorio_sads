USE [DataMart]
GO

/****** Object:  Table [SADS].[SegOper_Metas_Mensuales]    Script Date: 20/08/2026 12:44:51 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[SADS_SegOper_Metas_Mensuales](
	[Mes] [date] NOT NULL,
	[NUR] [varchar](20) NOT NULL,
	[CategoriaId] [tinyint] NOT NULL,
	[Indicador] [varchar](100) NOT NULL,
	[Valor_Meta] [decimal](18, 4) NOT NULL,
 CONSTRAINT [UQ_SegOper_Metas_Mensuales] UNIQUE NONCLUSTERED 
(
	[Mes] ASC,
	[NUR] ASC,
	[Indicador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
