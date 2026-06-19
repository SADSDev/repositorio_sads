CREATE VIEW ANALYTICS.MAM_frecuencia_de_recompra_por_ruta
AS
WITH
tickets_por_ruta AS (

    SELECT
        Ruta,
        YEAR(Fecha) AS anio,
        MONTH(Fecha) AS mes,

        COUNT(*) AS tickets

    FROM ANALYTICS.MAM_venta_diaria_de_clientes_por_ruta

    GROUP BY
        Ruta,
        YEAR(Fecha),
        MONTH(Fecha)

),

clientes_mes AS (

    SELECT
        Ruta,
        YEAR(Fecha) AS anio,
        MONTH(Fecha) AS mes,

        COUNT(DISTINCT Cliente) AS clientes_unicos

    FROM ANALYTICS.MAM_venta_diaria_de_clientes_por_ruta

    GROUP BY
        Ruta,
        YEAR(Fecha),
        MONTH(Fecha)

),

frec_esp AS (

    SELECT
        A.Ruta,
        A.anio,
        A.mes,
        A.tickets,
        B.clientes_unicos,

        CAST(A.tickets AS FLOAT)
        /
        NULLIF(B.clientes_unicos,0) AS f_i_t

    FROM tickets_por_ruta A

    LEFT JOIN clientes_mes B
        ON A.Ruta = B.Ruta
       AND A.anio = B.anio
       AND A.mes = B.mes

),

frecuencia_recompra_ponderada AS (

    SELECT
        A.Ruta,

        SUM(
            A.f_i_t * B.peso
        ) / SUM(B.peso) AS frecuencia_recompra

    FROM (

        SELECT
            Ruta,
            anio,
            mes,
            f_i_t,

            ROW_NUMBER() OVER(
                PARTITION BY Ruta
                ORDER BY anio DESC, mes DESC
            ) AS mes_relativo

        FROM frec_esp

    ) A

    LEFT JOIN ANALYTICS.MAM_Ponderaciones B
        ON A.mes_relativo = B.mes

    GROUP BY
        A.Ruta

)

SELECT
    Ruta,
    ROUND(frecuencia_recompra,2) AS frecuencia_recompra

FROM frecuencia_recompra_ponderada;
GO
