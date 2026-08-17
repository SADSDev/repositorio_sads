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
anio_hoy=fecha_hoy.year
mes_inicio_proceso=fecha_hoy.month -(mes_max % 12) 
mes_fin_proceso= fecha_hoy.month -(mes_min % 12)  
meses = [
    ((mes_inicio_proceso - 1 + i) % 12) + 1
    for i in range(
        ((mes_fin_proceso - mes_inicio_proceso) % 12) + 1
    )
]


#==========================================================
# PROCESO
#==========================================================

df_mart=pd.DataFrame
for mes in meses:
    #solicitud al proceso MART
    request=MARTRequest(mes=mes, anio=anio_hoy, agencia=8)


