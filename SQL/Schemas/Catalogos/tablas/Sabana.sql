
/****** Object:  Table [PWST].[CATALOGOS_Sabana]    Script Date: 15/09/2026 09:59:31 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[CATALOGOS_Sabana](
	[Agencia] [int] NULL,
	[ClienteISMS] [varchar](50) NULL,
	[REEV] [varchar](50) NULL,
	[Tier] [varchar](50) NULL,
	[Custom] [varchar](50) NULL,
	[Gtplus] [int] NULL,
	[Credito] [float] NULL,
	[Open] [int] NULL,
	[Ponderado] [int] NULL,
	[Visitable] [int] NULL,
	[Merch] [int] NULL,
	[FechaModificacion] [datetime] NULL
) ON [PRIMARY]
GO

ALTER TABLE [PWST].[CATALOGOS_Sabana] ADD  CONSTRAINT [DF_Sabana_Merch]  DEFAULT ((0)) FOR [Merch]
GO