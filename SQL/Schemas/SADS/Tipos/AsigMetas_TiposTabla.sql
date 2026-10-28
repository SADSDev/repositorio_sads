/* Tipos de tabla para SADS_AsigMetas_SubirDatos.
   Compatibles con SQL Server con nivel de compatibilidad 100. */

IF TYPE_ID(N'PWST.AsigMetasAgenciaInstancia') IS NULL
BEGIN
    EXEC(N'
        CREATE TYPE [PWST].[AsigMetasAgenciaInstancia] AS TABLE
        (
            Agencia INT NOT NULL,
            Indicador VARCHAR(100) NOT NULL,
            Valor_Meta DECIMAL(18,4) NOT NULL
        )
    ');
END;
GO

IF TYPE_ID(N'PWST.AsigMetasRutaInstancia') IS NULL
BEGIN
    EXEC(N'
        CREATE TYPE [PWST].[AsigMetasRutaInstancia] AS TABLE
        (
            NUR VARCHAR(20) NOT NULL,
            Fecha DATE NOT NULL,
            Indicador VARCHAR(100) NOT NULL,
            Valor_Meta DECIMAL(18,4) NOT NULL
        )
    ');
END;
GO
