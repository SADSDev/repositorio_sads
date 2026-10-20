USE [DataMart]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[SEGURIDAD_RolRecursos]
(
    [RolId] INT NOT NULL,
    [RecursoId] INT NOT NULL,

    CONSTRAINT [PK_RolRecursos]
        PRIMARY KEY CLUSTERED
        (
            [RolId] ASC,
            [RecursoId] ASC
        )
        WITH
        (
            PAD_INDEX = OFF,
            STATISTICS_NORECOMPUTE = OFF,
            IGNORE_DUP_KEY = OFF,
            ALLOW_ROW_LOCKS = ON,
            ALLOW_PAGE_LOCKS = ON
        ) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [PWST].[SEGURIDAD_RolRecursos]
WITH CHECK ADD CONSTRAINT [FK_RolRecursos_Recursos]
FOREIGN KEY ([RecursoId])
REFERENCES [PWST].[SEGURIDAD_Recursos] ([RecursoId])
GO

ALTER TABLE [PWST].[SEGURIDAD_RolRecursos]
CHECK CONSTRAINT [FK_RolRecursos_Recursos]
GO

ALTER TABLE [PWST].[SEGURIDAD_RolRecursos]
WITH CHECK ADD CONSTRAINT [FK_RolRecursos_Roles]
FOREIGN KEY ([RolId])
REFERENCES [PWST].[SEGURIDAD_Roles] ([RolId])
GO

ALTER TABLE [PWST].[SEGURIDAD_RolRecursos]
CHECK CONSTRAINT [FK_RolRecursos_Roles]
GO
