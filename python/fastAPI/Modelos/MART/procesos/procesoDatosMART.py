# Obtiene los datos y ejecuta los procesos requeridos por MART

# -------------------------------------------------
# LIBRERIAS
# -------------------------------------------------
import logging

import pandas as pd

logger = logging.getLogger("uvicorn.error")


# -------------------------------------------------
# IMPORTS
# -------------------------------------------------
from Core.validarDataFrame import validar_dataframe

from MART.Config.parametros import (
    obtener_ponderaciones,
    obtener_parametros,
    parametro_c,
    bet
)

from MART.datos.SQL import (
    obtener_tabla_ventas,
    obtener_calendario
)

from MART.datos.esfuerzoHistorico import esfuerzo_historico
from MART.datos.n import parametro_n
from MART.datos.calendarioPorRuta import calendario_por_ruta

from MART.procesos.promediosPondTemporales import (
    promedio_pond_diames_diasem,
    promedio_pond_diames,
    promedio_pond_diasem
)

from MART.procesos.suavizadoJerarquico import suavizado_jerarquico


# -------------------------------------------------
# PROCESO DE DATOS DEL MODELO MART
# -------------------------------------------------
def obtener_datos_modelo(
    anio: int,
    mes: int,
    agencia: int
):
    # -------------------------------------------------
    # OBTENCION DE PARAMETROS Y DATOS
    # -------------------------------------------------
    df_ponderaciones = obtener_ponderaciones()
    validar_dataframe(df_ponderaciones, "df_ponderaciones")

    fecha_inicio, fecha_fin, agencia = obtener_parametros(
        anio,
        mes,
        agencia
    )

    logger.info(
        "MART | obteniendo ventas | agencia=%s",
        agencia
    )

    df_venta = obtener_tabla_ventas(
        agencia=agencia,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin
    )

    validar_dataframe(df_venta, "df_venta")

    df_venta["Fecha"] = pd.to_datetime(
        df_venta["Fecha"]
    )

    # -------------------------------------------------
    # CALCULO DEL ESFUERZO HISTORICO
    # -------------------------------------------------
    df_esfuerzo_historico = esfuerzo_historico(
        df_venta
    )

    validar_dataframe(
        df_esfuerzo_historico,
        "df_esfuerzo_historico"
    )

    # -------------------------------------------------
    # OBTENCION DEL CALENDARIO DEL MES A MODELAR
    # -------------------------------------------------
    df_calendario = obtener_calendario(
        fecha_fin
    )

    validar_dataframe(
        df_calendario,
        "df_calendario"
    )

    df_calendario["Fecha"] = pd.to_datetime(
        df_calendario["Fecha"]
    )

    # Se generan las columnas necesarias para el merge final
    df_calendario["Dia_Mes"] = (
        df_calendario["Fecha"].dt.day
    )

    df_calendario["Dia_Semana"] = (
        df_calendario["Fecha"].dt.dayofweek + 1
    )

    # -------------------------------------------------
    # CREACION DEL CALENDARIO POR RUTA
    # -------------------------------------------------
    df_calendario_rutas = calendario_por_ruta(
        df_calendario,
        df_esfuerzo_historico
    )

    validar_dataframe(
        df_calendario_rutas,
        "df_calendario_rutas"
    )



    # -------------------------------------------------
    # CALCULO DE n
    # -------------------------------------------------
    df_n = parametro_n(
        df_esfuerzo_historico
    )

    validar_dataframe(
        df_n,
        "df_n"
    )

    # -------------------------------------------------
    # CALCULO DE PROMEDIOS PONDERADOS
    # -------------------------------------------------
    df_prom_pond_diames_diasem = promedio_pond_diames_diasem(
        df_esfuerzo_historico,
        df_ponderaciones
    )

    df_prom_pond_diames = promedio_pond_diames(
        df_esfuerzo_historico,
        df_ponderaciones
    )

    df_prom_pond_diasem = promedio_pond_diasem(
        df_esfuerzo_historico,
        df_ponderaciones
    )

    # -------------------------------------------------
    # CALCULO DEL SUAVIZADO JERARQUICO
    # -------------------------------------------------
    df_suavizado_jerarquico = suavizado_jerarquico(
        df_prom_pond_diames_diasem,
        df_prom_pond_diames,
        df_prom_pond_diasem,
        df_n,
        parametro_c,
        bet
    )

    validar_dataframe(
        df_suavizado_jerarquico,
        "df_suavizado_jerarquico"
    )


    # -------------------------------------------------
    # RESULTADOS
    # -------------------------------------------------
    logger.info(
        "MART | datos y procesos calculados correctamente"
    )

    return {
        "df_ponderaciones": df_ponderaciones,
        "df_venta": df_venta,
        "df_esfuerzo_historico": df_esfuerzo_historico,
        "df_n": df_n,
        "df_prom_pond_diames_diasem": df_prom_pond_diames_diasem,
        "df_prom_pond_diames": df_prom_pond_diames,
        "df_prom_pond_diasem": df_prom_pond_diasem,
        "df_suavizado_jerarquico": df_suavizado_jerarquico,
        "df_calendario": df_calendario,
        "df_calendario_rutas": df_calendario_rutas
    }