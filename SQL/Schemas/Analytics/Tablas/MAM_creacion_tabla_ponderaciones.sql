CREATE TABLE ANALYTICS.MAM_Ponderaciones
(
    Mes INT NOT NULL,
    Peso DECIMAL(4,3) NOT NULL
);
GO

INSERT INTO ANALYTICS.MAM_Ponderaciones
(
    mes,
    peso
)
VALUES
    (1, 0.4),
    (2, 0.3),
    (3, 0.2),
    (4, 0.1);
GO