CREATE TABLE PWST.ANALYTICS_SimulacionesVentas
(
    Simulacion INT NOT NULL,
    Agencia INT NOT NULL,
    NUR VARCHAR(20) NOT NULL,
    Fecha DATE NOT NULL,
    Volumen_Simulado DECIMAL(18,6) NOT NULL,

    CONSTRAINT PK_ANALYTICS_SimulacionesVentas
        PRIMARY KEY CLUSTERED
        (
            Simulacion,
            NUR,
            Fecha
        )
);
GO