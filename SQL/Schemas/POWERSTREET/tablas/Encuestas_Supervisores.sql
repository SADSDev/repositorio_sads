CREATE TABLE PWST.POWERSTREET_Encuestas_Supervisores
(
    Fecha DATE NOT NULL,
    Supervisor VARCHAR(10),
    NUR VARCHAR(50) NOT NULL,
    Cliente VARCHAR(20) NOT NULL,
    Nombre_Cliente VARCHAR(200) NULL,
    Tipo_Visita VARCHAR(50) NULL,
    Con_Vendedor INT NOT NULL,
    Sin_Vendedor INT NOT NULL
);