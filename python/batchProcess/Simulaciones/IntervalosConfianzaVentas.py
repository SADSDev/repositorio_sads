#Este proceso se encarga de procesar para cada una de las
#rutas evaluables, obtener la diferencia entre el comportamiento
#obtenido del MART vs el real durante cada uno de los 4 meses
#anteriores al actual, para proceder a simularlos y obtener un 
#intervalo de confianza

#=================================================
#LIBRERIAS 
#=================================================
import pandas as pd
from datetime import date
from sqlalchemy import text
from dateutil.relativedelta import relativedelta

#=================================================
#IMPORTS
#=================================================
from Config.conexion_SQL import(
    manejar_error_conexion_sql,
    obtener_motor
)

from fastAPI.Modelos.MART.Schemas.request import MARTRequest
from fastAPI.Modelos.MART.modeloMART import modeloMART
from fastAPI.Modelos.MART.procesos.procesoDatosMART import obtener_datos_modelo


#======================================================
# VARIABLES
#======================================================
@manejar_error_conexion_sql
def obtener_parametros_proceso():

    motor = obtener_motor()

    mes_max = pd.read_sql(
        text("""
            SELECT MAX(Mes) AS Mes
            FROM CATALOGOS.Ponderaciones
        """),
        con=motor
    )["Mes"].iloc[0]

    mes_min = pd.read_sql(
        text("""
            SELECT MIN(Mes) AS Mes
            FROM CATALOGOS.Ponderaciones
        """),
        con=motor
    )["Mes"].iloc[0]

    agencias_a_trabajar = pd.read_sql(
        text("""
            SELECT DISTINCT
                Agencia
            FROM CATALOGOS.Rutas_Evaluables
            ORDER BY Agencia ASC
        """),
        con=motor
    )["Agencia"].tolist()

    motor.dispose()

    return mes_min, mes_max, agencias_a_trabajar


mes_min, mes_max, agencias_a_trabajar = obtener_parametros_proceso()
fecha_hoy=date.today()
mes_inicio_proceso=fecha_hoy+relativedelta(day=1, months=-mes_max) 
mes_fin_proceso= fecha_hoy+relativedelta(day=1, months=-mes_min)
meses = pd.date_range(
    start=mes_inicio_proceso,
    end=mes_fin_proceso,
    freq="MS"
)

#==========================================================
# PROCESO
#==========================================================

df_mart_final=pd.DataFrame

for agencia in agencias_a_trabajar:
    for mes in meses:
        #solicitud al proceso MART
        request=MARTRequest(mes=mes.month, anio=mes.year, agencia=agencia)
        df_mart=modeloMART(request=request)
        


