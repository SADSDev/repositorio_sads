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


#-----------------------------------
# OBTENCION DE DATOS DEL MODELO
#-----------------------------------
def modeloMAM(request: MAMRequest):
    resultados = obtener_datos_modelo(
        anio=request.anio,
        mes=request.mes,
        agencia=request.agencia
    )

    df_venta = resultados["df_venta"]
    df_vigencias_me = resultados["df_vigencias_me"]
    df_compradores_esperados = resultados["df_compradores_esperados"]
    df_volumen_esperado = resultados["df_volumen_esperado"]
    df_capacidad_base = resultados["df_capacidad_base"]
    df_venta_marca_mes_cliente = resultados["df_venta_marca_mes_cliente"]
    df_adopcion_marca_mes_cliente = resultados["df_adopcion_marca_mes_cliente"]
    df_penetracion_marca_mes_cliente = resultados["df_penetracion_marca_mes_cliente"]
    df_penetracionprom_mes = resultados["df_penetracionprom_mes"]
    df_penetracion_ponderada = resultados["df_penetracion_ponderada"]
    df_ventaprom_marca_mes = resultados["df_ventaprom_marca_mes"]
    df_ventaprom_prom_mes = resultados["df_ventaprom_prom_mes"]
    df_ventaprom_ponderada = resultados["df_ventaprom_ponderada"]
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
    

    df_modelo_final = (
        df_pesos
        .assign(
            meta_vol=lambda x:
            x["peso_vol"] * request.meta_neta
        )
    )

    for marca in request.marcas_estrategicas:
        df_modelo_final[marca.marca] = (
            df_modelo_final["peso_vol_me"] * marca.meta
        )

    df_modelo_final = (
        df_modelo_final
        .drop(columns=["peso_vol", "peso_vol_me"])
    )   

    #-----------------------------------
    # DEBUG DE EXCEL
    #-----------------------------------
    with pd.ExcelWriter(
        r"D:\Descargas\debug_MAM.xlsx",
        engine="openpyxl"
    ) as writer:

        df_modelo_final.to_excel(
            writer,
            sheet_name="modelo",
            index=False
        )
        


    #-----------------------------------
    # DEBUG DE FORMAS
    #-----------------------------------
    print(df_venta.shape)
    print(df_vigencias_me.shape)
    print(df_venta_marca_mes_cliente.shape)

    return df_modelo_final