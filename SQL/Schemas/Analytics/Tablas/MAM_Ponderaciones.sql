USE [DataMart]
GO

/****** Object:  Table [ANALYTICS].[MAM_Ponderaciones]    Script Date: 20/08/2026 10:23:47 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[ANALYTICS_MAM_Ponderaciones](
	[Mes] [int] NULL,
	[Peso] [decimal](4, 3) NULL
) ON [PRIMARY]
GO


INSERT INTO [PWST].[ANALYTICS_MAM_Ponderaciones]
(
    Mes,
    Peso
)
VALUES
    (1, 0.4),
    (2, 0.3),
    (3, 0.2),
    (4, 0.1);
GO