# PROGRAMA PRINCIPAL DEL MODELO
# Ejecuta la asignación final de metas por ruta a partir de los pesos
# de capacidad base y de volumen esperado de marcas estratégicas.

#-----------------------------------
# LIBRERIAS
#-----------------------------------
import pandas as pd


#-----------------------------------
# IMPORTS
#-----------------------------------
from MAM.procesos.procesoDatosMAM import obtener_datos_modelo
from MAM.Schemas.request import MAMRequest
from Core.redondear import redondear_conservando_total

#-----------------------------------
# OBTENCION DE DATOS DEL MODELO
#-----------------------------------
def modeloMAM(request: MAMRequest):
    resultados = obtener_datos_modelo(
        anio=request.anio,
        mes=request.mes,
        agencia=request.agencia
    )


    df_capacidad_base = resultados["df_capacidad_base"]

    df_volumen_me_esperado = resultados["df_volumen_me_esperado"]


    #------------------------------------------------------------
    # OBTENCION DE PESOS
    #------------------------------------------------------------

    # pesos para la meta de volumen gral
    df_pesos_volumen = (
        df_capacidad_base
        .assign(
            peso_vol=lambda x:
            x["capacidad_base"] / x["capacidad_base"].sum()
        )
    )

    # pesos para la(s) metas de volumen de ME
    df_pesos_volumen_me = (
        df_volumen_me_esperado
        .assign(
            peso_vol_me=lambda x:
            x["vol_me_esperado"] / x["vol_me_esperado"].sum()
        )
    )

    # df de ambos pesos
    df_pesos = (
        df_pesos_volumen
        .merge(
            df_pesos_volumen_me,
            on="NUR",
            how="left"
        )
    )


    #-----------------------------------
    # MODELO FINAL
    #-----------------------------------
    

    df_mam = (
        df_pesos
        .assign(
            meta_vol=lambda x:
            x["peso_vol"] * request.meta_neta
        )
    )

    for marca in request.marcas_estrategicas:
        df_mam[marca.marca] = (
            df_mam["peso_vol_me"] * marca.meta
        )

    df_mam = (
        df_mam
        .drop(columns=["capacidad_base",
                        "vol_me_esperado"
                          ])
        .assign(
            meta_vol= lambda x: redondear_conservando_total(
                x,
                "meta_vol",
                request.meta_neta  
            )
        )
    )
       
    for marca in request.marcas_estrategicas:
        df_mam[marca.marca] = redondear_conservando_total(
            df_mam,
            marca.marca,
            marca.meta
        )

    return df_mam