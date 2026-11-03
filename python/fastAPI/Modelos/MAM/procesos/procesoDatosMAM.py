# Obtiene los datos, parámetros e indicadores requeridos para calcular
# la capacidad base y el volumen esperado de marcas estratégicas.

#-------------------------------------------------
# LIBRERIAS
#-------------------------------------------------
import logging
logger = logging.getLogger("uvicorn.error")

import pandas as pd

#---------------------------------------------
# IMPORTS
#---------------------------------------------
from fastAPI.Modelos.Core.validarDataFrame import validar_dataframe

from fastAPI.Modelos.MAM.Config.parametros import (
    obtener_ponderaciones,
    obtener_parametros_ajustables,
    obtener_parametros
)
from fastAPI.Modelos.MAM.datos.SQL import (
    obtener_tabla_ventas,
    obtener_tabla_ux,
    obtener_vigencias_me
)
from fastAPI.Modelos.MAM.datos.clientesActivos import clientes_activos
from fastAPI.Modelos.MAM.datos.eficienciaVentaMes import (
    clientes_unicos_por_mes,
    eficiencia_por_mes,
    eficiencia_ponderada
)
from fastAPI.Modelos.MAM.datos.ticketEsperado import (
    venta_por_cliente,
    ticket_esperado
)
from fastAPI.Modelos.MAM.datos.frecuenciaRecompraEsperada import (
    tickets_por_ruta_mes,
    frecuencia_por_mes,
    frecuencia_ponderada
)
from fastAPI.Modelos.MAM.datos.penetracionME import (
    venta_marca_mes_cliente,
    adopcion_marca_mes_cliente,
    penetracion_marca_mes_cliente,
    penetracionprom_mes,
    penetracion_ponderada,
    ventaprom_marca_mes,
    ventaprom_prom_mes,
    ventaprom_ponderada
)
from fastAPI.Modelos.MAM.procesos.compradoresEsperados import compradores_esperados
from fastAPI.Modelos.MAM.procesos.volumenEsperado import volumen_esperado
from fastAPI.Modelos.MAM.procesos.capacidadBase import capacidad_base
from fastAPI.Modelos.MAM.procesos.volumenMEEsperado import volumen_me_esperado

#-----------------------------------------------------
# PROCESO DE DATOS DEL MODELO
#-----------------------------------------------------
# procesoDatosMAM.py
def obtener_datos_modelo(anio: int, mes: int, agencia: int):

    #-----------------------------------
    # OBTENCION DE DATOS
    #-----------------------------------
    df_ponderaciones = obtener_ponderaciones()
    df_parametros_ajustables = obtener_parametros_ajustables()
    fecha_inicio, fecha_fin, agencia = obtener_parametros(
        anio,
        mes,
        agencia
    )   

    logger.info("MAM | obteniendo ventas | agencia=%s",agencia)
    df_venta = obtener_tabla_ventas(
        agencia=agencia,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin
    )
    validar_dataframe(df_venta, "df_venta")
    df_venta["Fecha"] = pd.to_datetime(df_venta["Fecha"])

    logger.info("MAM | obteniendo universo de clientes | agencia=%s",agencia)
    df_ux = obtener_tabla_ux(agencia=agencia)
    validar_dataframe(df_ux, "df_ux")

    logger.info("MAM | obteniendo marcas estratégicas | agencia=%s",agencia)
    df_vigencias_me = obtener_vigencias_me(
        agencia=agencia,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin
    )
    validar_dataframe(df_vigencias_me, "df_vigencias_me")

    #-----------------------------------
    # OBTENCION DE PARAMETROS
    #-----------------------------------
    alpha = (
        df_parametros_ajustables
        .loc[
            df_parametros_ajustables["Parametro"] == "alpha",
            "Valor"
        ]
        .item()
    )

    #-----------------------------------
    # CALCULO DE EFICIENCIA
    #-----------------------------------
    df_clientes_activos = clientes_activos(df_ux)

    df_clientes_unicos_por_mes = clientes_unicos_por_mes(df_venta)

    df_eficiencia_por_mes = eficiencia_por_mes(
        df_clientes_unicos_por_mes,
        df_clientes_activos,
        df_ponderaciones
    )

    df_eficiencia_ponderada = eficiencia_ponderada(
        df_eficiencia_por_mes
    )

    #-----------------------------------
    # CALCULO DE TICKET Y FRECUENCIA
    #-----------------------------------
    df_venta_por_cliente = venta_por_cliente(df_venta)

    df_ticket_esperado = ticket_esperado(
        df_venta_por_cliente
    )

    df_tickets_por_ruta_mes = tickets_por_ruta_mes(
        df_venta_por_cliente
    )

    df_frecuencia_por_mes = frecuencia_por_mes(
        df_tickets_por_ruta_mes,
        df_clientes_unicos_por_mes,
        df_ponderaciones
    )

    df_frecuencia_ponderada = frecuencia_ponderada(
        df_frecuencia_por_mes
    )

    #-----------------------------------
    # CALCULO DE PENETRACION ME
    #-----------------------------------
    df_venta_marca_mes_cliente = venta_marca_mes_cliente(
        df_venta,
        df_vigencias_me
    )

    df_adopcion_marca_mes_cliente = adopcion_marca_mes_cliente(
        df_venta_marca_mes_cliente
    )

    df_penetracion_marca_mes_cliente = penetracion_marca_mes_cliente(
        df_adopcion_marca_mes_cliente,
        df_clientes_activos
    )

    df_penetracionprom_mes = penetracionprom_mes(
        df_penetracion_marca_mes_cliente
    )

    df_penetracion_ponderada = penetracion_ponderada(
        df_penetracionprom_mes,
        df_ponderaciones
    )

    df_ventaprom_marca_mes = ventaprom_marca_mes(
        df_venta_marca_mes_cliente,
        df_adopcion_marca_mes_cliente
    )

    df_ventaprom_prom_mes = ventaprom_prom_mes(
        df_ventaprom_marca_mes
    )

    df_ventaprom_ponderada = ventaprom_ponderada(
        df_ventaprom_prom_mes,
        df_ponderaciones
    )

    #-----------------------------------
    # PROCESOS DEL MODELO
    #-----------------------------------
    df_compradores_esperados = compradores_esperados(
        df_clientes_activos,
        df_eficiencia_ponderada
    )

    df_volumen_esperado = volumen_esperado(
        df_compradores_esperados,
        df_ticket_esperado,
        df_frecuencia_ponderada
    )

    df_capacidad_base = capacidad_base(
        df_volumen_esperado,
        df_compradores_esperados,
        df_clientes_activos,
        alpha
    )

    df_volumen_me_esperado = volumen_me_esperado(
        df_penetracion_ponderada,
        df_ventaprom_ponderada,
        df_clientes_activos
    )

    #-----------------------------------
    # RESULTADOS
    #-----------------------------------
    logger.info("Datos obtenidos con éxito")
    return {
        "df_venta": df_venta,
        "df_vigencias_me": df_vigencias_me,
        "df_compradores_esperados": df_compradores_esperados,
        "df_volumen_esperado": df_volumen_esperado,
        "df_capacidad_base": df_capacidad_base,
        "df_venta_marca_mes_cliente": df_venta_marca_mes_cliente,
        "df_adopcion_marca_mes_cliente": df_adopcion_marca_mes_cliente,
        "df_penetracion_marca_mes_cliente": df_penetracion_marca_mes_cliente,
        "df_penetracionprom_mes": df_penetracionprom_mes,
        "df_penetracion_ponderada": df_penetracion_ponderada,
        "df_ventaprom_marca_mes": df_ventaprom_marca_mes,
        "df_ventaprom_prom_mes": df_ventaprom_prom_mes,
        "df_ventaprom_ponderada": df_ventaprom_ponderada,
        "df_volumen_me_esperado": df_volumen_me_esperado
    }