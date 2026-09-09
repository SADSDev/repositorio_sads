#-----------------------------------
#LIBRERIAS
#-----------------------------------
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
from sqlalchemy import text
import pandas as pd

#----------------------------------------------------
# IMPORTS
#----------------------------------------------------
from Config.conexion_SQL import (
    manejar_error_conexion_sql,
    obtener_motor
)


#---------------------------------------------------
# PARAMETROS REUSABLES
#---------------------------------------------------

#df con los pesos de cada uno de los meses evaluados en promedios ponderados
@manejar_error_conexion_sql
def obtener_ponderaciones():
    motor=obtener_motor()
    return pd.read_sql(
        text("""
            SELECT *
            FROM PWST.ANALYTICS_MAM_Ponderaciones
        """),
        motor
    )



#fecha de inicio de consulta y fin de consulta
def obtener_parametros(anio, mes):
    df_ponderaciones=obtener_ponderaciones()
    total_meses=df_ponderaciones["Mes"].max()
    
    hoy = datetime(anio, mes, 1)

    fecha_inicio = hoy.replace(day=1) - relativedelta(months=total_meses)
    fecha_fin = hoy.replace(day=1) - timedelta(days=1)

    return fecha_inicio,fecha_fin

#parametros para el suavizado de jerarquizacion
parametro_c=5
bet=0.5
