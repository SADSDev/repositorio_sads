CREATE TABLE PWST.ANALYTICS_SimulacionesVentasMensuales
(
    NUR VARCHAR(50) NOT NULL,
    Simulacion INT NOT NULL,
    Mes DATE NOT NULL,
    Volumen_Simulado_Mensual DECIMAL(12,3) NOT NULL,

    CONSTRAINT PK_SimulacionesVentasMensuales
        PRIMARY KEY CLUSTERED
        (
            Mes,
            NUR,
            Simulacion
        )
        WITH (DATA_COMPRESSION = PAGE)
);