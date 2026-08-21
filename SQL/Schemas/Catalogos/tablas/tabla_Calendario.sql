USE [DataMart]
GO

/****** Object:  Table [CATALOGOS].[Calendario]    Script Date: 20/08/2026 10:39:28 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PWST].[CATALOGOS_Calendario](
	[Fecha] [date] NOT NULL,
	[Anio] [smallint] NOT NULL,
	[Mes] [tinyint] NOT NULL,
	[Dia] [tinyint] NOT NULL,
	[Dia_Semana] [tinyint] NOT NULL,
	[Es_Asueto] [bit] NOT NULL,
	[Es_Habil] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

------------------------------------------------------------------------
--LLENADO DE LA TABLA
------------------------------------------------------------------------

--------------------------------------CTE PARA CREACION DE FECHAS ENTRE 2 AÑOS
SET DATEFIRST 1; -- 1=Lunes ... 7=Domingo

DECLARE @FechaInicio DATE = '2025-01-01';
DECLARE @FechaFin DATE = '2040-12-31';

;WITH Fechas AS
(
    SELECT @FechaInicio AS Fecha

    UNION ALL

    SELECT DATEADD(DAY,1,Fecha)
    FROM Fechas
    WHERE Fecha < @FechaFin
)

---------------------------------------------INSERTAR SOLO DATOS DE DÍA BASICOS
INSERT INTO CATALOGOS.Calendario
(
    Fecha,
    Anio,
    Mes,
    Dia,
    Dia_Semana,
    Es_Asueto,
    Es_Habil
)

SELECT
    Fecha,
    YEAR(Fecha),
    MONTH(Fecha),
    DAY(Fecha),
    DATEPART(WEEKDAY,Fecha),
    0,
    CASE
        WHEN DATEPART(WEEKDAY,Fecha)=7 THEN 0
        ELSE 1
    END
FROM Fechas
OPTION(MAXRECURSION 0);

------------------------------------------------MARCAR DÍAS ASUETOS FIJOS
--AÑO NUEVO
UPDATE CATALOGOS.Calendario
SET
    Es_Asueto = 1,
    Es_Habil = 0
WHERE Mes=1
AND Dia=1;

--DÍA DEL TRABAJO
UPDATE CATALOGOS.Calendario
SET
    Es_Asueto=1,
    Es_Habil=0
WHERE Mes=5
AND Dia=1;

--INDEPENDENCIA DE MÉXICO
UPDATE CATALOGOS.Calendario
SET
    Es_Asueto=1,
    Es_Habil=0
WHERE Mes=9
AND Dia=16;

--NAVIDAD
UPDATE CATALOGOS.Calendario
SET
    Es_Asueto=1,
    Es_Habil=0
WHERE Mes=12
AND Dia=25;

----------------------------------LLENAR DÍAS ASUETOS MOVILES
--PRIMER LUNES DE FEBRERO
UPDATE CATALOGOS.Calendario
SET
    Es_Asueto=1,
    Es_Habil=0
WHERE
    Mes=2
    AND Dia_Semana=1
    AND Dia<=7;

--TERCER LUNES DE MARZO
UPDATE CATALOGOS.Calendario
SET
    Es_Asueto=1,
    Es_Habil=0
WHERE
    Mes=3
    AND Dia_Semana=1
    AND Dia BETWEEN 15 AND 21;

--TERCER LUNES DE NOVIEMBRE
UPDATE CATALOGOS.Calendario
SET
    Es_Asueto=1,
    Es_Habil=0
WHERE
    Mes=11
    AND Dia_Semana=1
    AND Dia BETWEEN 15 AND 21;