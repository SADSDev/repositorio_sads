USE [DataMart]
GO

/****** Object:  Table [Seguridad].[UsuarioPermisos]    Script Date: 20/08/2026 01:10:55 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[SEGURIDAD_UsuarioPermisos](
	[UsuarioAplicacionId] [int] NOT NULL,
	[PermisoId] [int] NOT NULL,
 CONSTRAINT [PK_UsuarioPermisos] PRIMARY KEY CLUSTERED 
(
	[UsuarioAplicacionId] ASC,
	[PermisoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [PWST].[SEGURIDAD_UsuarioPermisos]  WITH CHECK ADD  CONSTRAINT [FK_UsuarioPermisos_Permisos] FOREIGN KEY([PermisoId])
REFERENCES [PWST].[SEGURIDAD_Permisos] ([PermisoId])
GO

ALTER TABLE [PWST].[SEGURIDAD_UsuarioPermisos] CHECK CONSTRAINT [FK_UsuarioPermisos_Permisos]
GO

ALTER TABLE [PWST].[SEGURIDAD_UsuarioPermisos]  WITH CHECK ADD  CONSTRAINT [FK_UsuarioPermisos_UsuarioAplicacion] FOREIGN KEY([UsuarioAplicacionId])
REFERENCES [PWST].[SEGURIDAD_UsuarioAplicacion] ([UsuarioAplicacionId])
GO

ALTER TABLE [PWST].[SEGURIDAD_UsuarioPermisos] CHECK CONSTRAINT [FK_UsuarioPermisos_UsuarioAplicacion]
GO