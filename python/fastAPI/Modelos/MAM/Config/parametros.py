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
from Config.conexion_SQL import obtener_motor
motor=obtener_motor()


#---------------------------------------------------
# PARAMETROS REUSABLES
#---------------------------------------------------

#df con los pesos de cada uno de los meses evaluados en promedios ponderados
def obtener_ponderaciones():
    return pd.read_sql(
        text("""
            SELECT *
            FROM ANALYTICS.MAM_Ponderaciones
        """),
        motor
    )

#df con los paramteros ajustables por default que arrojará el modelo
def obtener_parametros_ajustables():
    return pd.read_sql(
        text("""
            SELECT *
            FROM ANALYTICS.MAM_Parametros_Ajustables
        """),
        motor
    )

#fecha de inicio de consulta y fin de consulta
def obtener_parametros(anio, mes, agencia):
    df_ponderaciones=obtener_ponderaciones()
    total_meses=df_ponderaciones["Mes"].max()
    
    hoy=hoy = datetime(anio, mes, 1)

    fecha_inicio = hoy.replace(day=1) - relativedelta(months=total_meses)
    fecha_fin = hoy.replace(day=1) - timedelta(days=1)

    return fecha_inicio,fecha_fin,agencia