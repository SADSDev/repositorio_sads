CREATE VIEW ANALYTICS.MAM_ticket_esperado_por_ruta
AS

SELECT
    Ruta,
    ROUND(AVG(CAST(total_diario AS FLOAT)),3) AS ticket_esperado

FROM ANALYTICS.MAM_venta_diaria_de_clientes_por_ruta

GROUP BY Ruta;
GO
