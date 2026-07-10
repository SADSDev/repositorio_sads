CREATE TABLE CATALOGOS.Frecuencias_Reportes
(
    FrecuenciaId TINYINT PRIMARY KEY,
    Frecuencia VARCHAR(20) NOT NULL
);

INSERT INTO CATALOGOS.Frecuencias_Reportes
(
    FrecuenciaId,
    Frecuencia
)
VALUES
(1, 'Diaria'),
(2, 'Semanal'),
(3, 'Mensual');