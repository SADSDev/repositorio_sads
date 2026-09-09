# PROCESO DE OBTENCION DE TABLAS SQL


#-----------------------------------
#LIBRERIAS
#-----------------------------------
import pandas as pd
from sqlalchemy import text

from datetime import date
from datetime import timedelta
from dateutil.relativedelta import relativedelta

#----------------------------------------------------
# IMPORTS
#----------------------------------------------------
from Config.conexion_SQL import (
    manejar_error_conexion_sql,
    obtener_motor
)


#----------------------------------------------------------
# PROCESO DE OBTENCION DE DF DE VENTAS sin clientes GTP
#--------------------------------------------------------
@manejar_error_conexion_sql
def obtener_esfuerzo_historico(agencia: int, fecha_inicio: date, fecha_fin: date):
    motor=obtener_motor()
    return pd.read_sql(
        text("""
            WITH rutas AS (
                SELECT
                    NUR
                FROM PWST.CATALOGOS_Rutas_Evaluables
                WHERE Agencia = :agencia
            ),

            articulos AS (
                SELECT
                    Codigo,
                    Familia
                FROM PWST.CATALOGOS_Articulos
            ),

            ventas_sin_gtp AS (
                SELECT
                    A.Fecha,
                    A.NUR,
                    A.Cliente,
                    A.Cantidad,
                    A.Codigo_Articulo,
                    C.Familia,
                    CASE
                        WHEN B.Cliente IS NOT NULL THEN 1
                        ELSE 0
                    END AS existe_en_B
                FROM PWST.POWERSTREET_Venta_Diaria A
                LEFT JOIN PWST.CATALOGOS_Clientes_GTP B
                    ON A.Cliente = B.Cliente
                LEFT JOIN articulos C
                    ON A.Codigo_Articulo = C.Codigo
                INNER JOIN rutas R
                    ON A.NUR = R.NUR
                WHERE Fecha BETWEEN :fecha_inicio AND :fecha_fin
                AND A.NUR <> '1125632M29'
            ),

            venta_diaria AS (
                SELECT
                    Fecha,
                    DATEFROMPARTS(
                        YEAR(Fecha),
                        MONTH(Fecha),
                        1
                    ) AS Mes,
                    NUR,
                    SUM(Cantidad) AS Cantidad_Diaria
                FROM ventas_sin_gtp
                WHERE existe_en_B = 0
                GROUP BY
                    Fecha,
                    DATEFROMPARTS(
                        YEAR(Fecha),
                        MONTH(Fecha),
                        1
                    ),
                    NUR
            )

            SELECT
                Fecha,
                Mes,
                NUR,
                Cantidad_Diaria,
                SUM(Cantidad_Diaria) OVER (
                    PARTITION BY NUR, Mes
                ) AS Cantidad_Mensual,
                CAST(Cantidad_Diaria AS FLOAT) /
                SUM(Cantidad_Diaria) OVER (
                    PARTITION BY NUR, Mes
                ) AS Esfuerzo
            FROM venta_diaria
            ORDER BY
                Fecha DESC,
                NUR ASC;
        """),
        motor,
        params={
            "agencia": agencia,
            "fecha_inicio": fecha_inicio,
            "fecha_fin": fecha_fin
        }
    )

#--------------------------------------------------------
# OBTENCION DE CALENDARIO 
#--------------------------------------------------------
@manejar_error_conexion_sql
def obtener_calendario(fecha_fin: date):

    inicio_mes = (fecha_fin.replace(day=1) + relativedelta(months=1))
    fin_mes = (inicio_mes + relativedelta(months=1)- timedelta(days=1))
    motor = obtener_motor()

    return pd.read_sql(
        text("""
            SELECT *
            FROM PWST.CATALOGOS_Calendario
            WHERE Fecha BETWEEN :inicio_mes AND :fin_mes
        """),
        motor,
        params={
            "inicio_mes": inicio_mes,
            "fin_mes": fin_mes
        }
    )
