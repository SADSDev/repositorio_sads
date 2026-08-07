#PROGRAMA PRINCIPAL DEL MODELO
#DEFINE FUNCION QUE OBTIENE DATOS Y EJECUTA 
#EL PROCESO MATEMATICO DEL MODELO

#proceso encargado de modelar el mes de interes, repartiendo
#los promedios de cada ruta sobre el mes


#----------------------------------------------------------------
# LIBRERIAS 
# ---------------------------------------------------------------
import pandas as pd

#----------------------------------------------------------------
# IMPORTS 
#----------------------------------------------------------------
from MART.procesos.procesoDatosMART import obtener_datos_modelo
from MART.Schemas.request import MARTRequest

#-----------------------------------
# OBTENCION DE DATOS DEL MODELO
#-----------------------------------


def modeloMART(request: MARTRequest):
    resultados = obtener_datos_modelo(
        anio=request.anio,
        mes=request.mes,
        agencia=request.agencia
    )

    return normalizacion_promedios(
        resultados["df_calendario_rutas"],
        resultados["df_suavizado_jerarquico"]
    )


#----------------------------------------------------------------
# PROCESO DE NORMALIZACION Y REPARTICION
#----------------------------------------------------------------
def normalizacion_promedios(df_calendario_rutas: pd.DataFrame,
    df_suavizado_jerarquico: pd.DataFrame)-> pd.DataFrame:

    df_mart = (
    df_calendario_rutas
    .loc[
        lambda x: (x["Dia_Semana"] != 7) & (x["Es_Habil"])
    ]
    .merge(
        df_suavizado_jerarquico[
            [
                "NUR",
                "Dia_Mes",
                "Dia_Semana",
                "Prom_Suavizado"
            ]
        ],
        on=[
            "NUR",
            "Dia_Mes",
            "Dia_Semana"
        ],
        how="left"
    )
    .assign(
        Peso=lambda x:
            x["Prom_Suavizado"] /
            x.groupby("NUR")["Prom_Suavizado"]
             .transform("sum")
    )
    [["Fecha","NUR","Dia_Mes", "Dia_Semana","Peso"]]
)

    return df_mart