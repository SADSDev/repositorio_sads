USE [DataMart]
GO

/****** Object:  Table [Seguridad].[UsuarioAplicacion]    Script Date: 20/08/2026 01:13:03 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[SEGURIDAD_UsuarioAplicacion](
	[UsuarioAplicacionId] [int] IDENTITY(1,1) NOT NULL,
	[UsuarioId] [int] NOT NULL,
	[AplicacionId] [int] NOT NULL,
	[RolId] [int] NOT NULL,
	[Agencia] [int] NULL,
	[Grupo] [varchar](50) NULL,
	[Ruta] [varchar](10) NULL,
 CONSTRAINT [PK_UsuarioAplicacion] PRIMARY KEY CLUSTERED 
(
	[UsuarioAplicacionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_UsuarioAplicacion] UNIQUE NONCLUSTERED 
(
	[UsuarioId] ASC,
	[AplicacionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [PWST].[SEGURIDAD_UsuarioAplicacion] ADD  CONSTRAINT [DF_UsuarioAplicacion_RolId]  DEFAULT ((1)) FOR [RolId]
GO

ALTER TABLE [PWST].[SEGURIDAD_UsuarioAplicacion]  WITH CHECK ADD  CONSTRAINT [FK_UsuarioAplicacion_Aplicacion] FOREIGN KEY([AplicacionId])
REFERENCES [PWST].[SEGURIDAD_Aplicaciones] ([Id])
GO

ALTER TABLE [PWST].[SEGURIDAD_UsuarioAplicacion] CHECK CONSTRAINT [FK_UsuarioAplicacion_Aplicacion]
GO

ALTER TABLE [PWST].[SEGURIDAD_UsuarioAplicacion]  WITH CHECK ADD  CONSTRAINT [FK_UsuarioAplicacion_Usuario] FOREIGN KEY([UsuarioId])
REFERENCES [PWST].[SEGURIDAD_Usuarios] ([Id])
GO

ALTER TABLE [PWST].[SEGURIDAD_UsuarioAplicacion] CHECK CONSTRAINT [FK_UsuarioAplicacion_Usuario]
GO
