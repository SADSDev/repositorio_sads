
--AUN SIN PROBAR EN SQL SERVER, LA VISTA YA ESTÁ TERMINADA PERO AUN NO SE PRUEBA 
CREATE VIEW ANALYTICS.MAM_esperado_me_por_ruta
AS 

WITH clientes_activos_por_ruta AS (

    SELECT
        Ruta,
        COUNT(DISTINCT Codigo_GLN) AS clientes_activos

    FROM PowerStreet.UX

    WHERE Estatus = 'Activo'

    GROUP BY Ruta
),

ME_penetracion_mensual AS (

    SELECT
        A.Ruta,
        A.Familia,
        YEAR(A.Fecha) AS anio,
        MONTH(A.Fecha) AS mes,
        COUNT(DISTINCT A.Cliente) AS clientes,
        B.clientes_activos,
        CAST(
            COUNT(DISTINCT A.Cliente)
            AS FLOAT
        )
        /
        NULLIF(B.clientes_activos,0) AS Pen

    FROM ANALYTICS.MAM_venta_mty A

    INNER JOIN CATALOGOS.Vigencias_ME V

        ON A.Familia = V.Familia

        AND DATEFROMPARTS(
                YEAR(A.Fecha),
                MONTH(A.Fecha),
                1
            )

            BETWEEN

            DATEFROMPARTS(
                YEAR(V.Inicio_Vigencia),
                MONTH(V.Inicio_Vigencia),
                1
            )

            AND

            DATEFROMPARTS(
                YEAR(ISNULL(V.Fin_Vigencia,GETDATE())),
                MONTH(ISNULL(V.Fin_Vigencia,GETDATE())),
                1
            )

    LEFT JOIN clientes_activos_por_ruta B
        ON A.Ruta = B.Ruta

    GROUP BY

        A.Ruta,
        A.Familia,
        YEAR(A.Fecha),
        MONTH(A.Fecha),
        B.clientes_activos
),
pen_prom_pond AS (

    SELECT
        Ruta,
        anio,
        mes,

        SUM(clientes) AS total_clientes,

        SUM(
            clientes * Pen
        )
        /
        NULLIF(
            SUM(clientes),
            0
        ) AS Pen_E

    FROM ME_penetracion_mensual

    GROUP BY
        Ruta,
        anio,
        mes
),
pen_esperada AS (

    SELECT
        A.Ruta,

        SUM(
            A.Pen_E * B.peso
        )
        /
        SUM(B.peso) AS Pen_E_final

    FROM (

        SELECT
            Ruta,
            anio,
            mes,
            Pen_E,

            ROW_NUMBER() OVER(
                PARTITION BY Ruta
                ORDER BY anio DESC, mes DESC
            ) AS mes_relativo

        FROM pen_prom_pond

    ) A

    LEFT JOIN ANALYTICS.MAM_Ponderaciones B
        ON A.mes_relativo = B.mes

    GROUP BY
        A.Ruta

),
paquetes_por_marca_por_ruta AS (

    SELECT
        A.Ruta,
        A.Familia,

        YEAR(A.Fecha) AS anio,
        MONTH(A.Fecha) AS mes,

        SUM(A.Cantidad) AS total_paquetes

    FROM ANALYTICS.MAM_venta_mty A

    INNER JOIN CATALOGOS.Vigencias_ME V

        ON A.Familia = V.Familia

        AND DATEFROMPARTS(
                YEAR(A.Fecha),
                MONTH(A.Fecha),
                1
            )
            BETWEEN
            DATEFROMPARTS(
                YEAR(V.Inicio_Vigencia),
                MONTH(V.Inicio_Vigencia),
                1
            )
            AND
            DATEFROMPARTS(
                YEAR(ISNULL(V.Fin_Vigencia,GETDATE())),
                MONTH(ISNULL(V.Fin_Vigencia,GETDATE())),
                1
            )

    GROUP BY
        A.Ruta,
        A.Familia,
        YEAR(A.Fecha),
        MONTH(A.Fecha)

),
mu_marca AS (

    SELECT
        A.Ruta,
        A.Familia,
        A.anio,
        A.mes,

        A.total_paquetes,

        B.clientes,

        CAST(A.total_paquetes AS FLOAT)
        /
        NULLIF(B.clientes,0) AS mu

    FROM paquetes_por_marca_por_ruta A

    LEFT JOIN ME_penetracion_mensual B

        ON A.Ruta = B.Ruta
        AND A.Familia = B.Familia
        AND A.anio = B.anio
        AND A.mes = B.mes

),

mu_prom_pond AS (

    SELECT
        Ruta,
        anio,
        mes,

        SUM(clientes) AS total_clientes,

        SUM(
            clientes * mu
        )
        /
        NULLIF(
            SUM(clientes),
            0
        ) AS mu_E

    FROM mu_marca

    GROUP BY
        Ruta,
        anio,
        mes

),

mu_esperado AS (

    SELECT
        A.Ruta,

        SUM(
            A.mu_E * B.peso
        )
        /
        SUM(B.peso) AS mu_E_final

    FROM (

        SELECT
            Ruta,
            anio,
            mes,
            mu_E,

            ROW_NUMBER() OVER(
                PARTITION BY Ruta
                ORDER BY anio DESC, mes DESC
            ) AS mes_relativo

        FROM mu_prom_pond

    ) A

    LEFT JOIN ANALYTICS.MAM_Ponderaciones B
        ON A.mes_relativo = B.mes

    GROUP BY
        A.Ruta

),

volumen_me_por_ruta AS (

    SELECT
        A.Ruta,

        A.clientes_activos,

        B.Pen_E_final,

        C.mu_E_final,

        (
            A.clientes_activos
            *
            B.Pen_E_final
            *
            C.mu_E_final
        ) AS esperado_me_por_ruta

    FROM clientes_activos_por_ruta A

    LEFT JOIN pen_esperada B
        ON A.Ruta = B.Ruta

    LEFT JOIN mu_esperado C
        ON A.Ruta = C.Ruta

)
SELECT
    Ruta,
    esperado_me_por_ruta
FROM volumen_me_por_ruta
GO
