# PROCESO DE OBTENCION de calendario del mes a modelar
#por cada ruta


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

#----------------------------------------------------------
# PROCESO DE OBTENCION DE CALENDARIO POR RUTA
#----------------------------------------------------------
def calendario_por_ruta(df_calendario: pd.DataFrame,
    df_esfuerzo_historico: pd.DataFrame,
    )-> pd.DataFrame:

    df_rutas = (
        df_esfuerzo_historico
        [["NUR"]]
        .drop_duplicates()
    )

    df_calendario["key"] = 1
    df_rutas["key"] = 1

    df_calendario_rutas = (
        df_calendario
        .merge(df_rutas, on="key")
        .drop(columns="key")
    )

    return df_calendario_rutas