#Este proceso se encarga de procesar para cada una de las
#rutas evaluables, obtener la diferencia entre el comportamiento
#obtenido del MART vs el real durante cada uno de los 4 meses
#anteriores al actual, para proceder a simularlos y obtener un 
#intervalo de confianza

#=================================================
#LIBRERIAS 
#=================================================
import pandas as pd
import numpy as np
from datetime import date
from sqlalchemy import text
from dateutil.relativedelta import relativedelta
from tqdm import tqdm
import random

#=================================================
#IMPORTS
#=================================================
from batchProcess.Simulaciones.Config.conexion_SQL import(
    manejar_error_conexion_sql,
    obtener_motor
)

from fastAPI.Modelos.MART.Schemas.request import MARTRequest
from fastAPI.Modelos.MART.modeloMART import modeloMART

#======================================================
# FUNCIONES
#======================================================

#obtencion de parametros 
@manejar_error_conexion_sql
def obtener_parametros_proceso():

    motor = obtener_motor()

    mes_max = pd.read_sql(
        text("""
            SELECT MAX(Mes) AS Mes
            FROM PWST.ANALYTICS_MAM_Ponderaciones
        """),
        con=motor
    )["Mes"].iloc[0]

    mes_min = pd.read_sql(
        text("""
            SELECT MIN(Mes) AS Mes
            FROM PWST.ANALYTICS_MAM_Ponderaciones
        """),
        con=motor
    )["Mes"].iloc[0]

    agencias_a_trabajar = pd.read_sql(
        text("""
            SELECT DISTINCT
                Agencia
            FROM PWST.CATALOGOS_Rutas_Evaluables
            WHERE Agencia NOT IN (2, 3, 9, 10)
            ORDER BY Agencia ASC
        """),
        con=motor
    )["Agencia"].tolist()

    motor.dispose()

    return mes_min, mes_max, agencias_a_trabajar

#obtencion de df´s extras de sql
@manejar_error_conexion_sql
def obtener_dfs_sql(fecha_inicio:date, fecha_fin:date):

    motor = obtener_motor()
    df_venta_diaria = pd.read_sql(
        text("""
            WITH rutas AS (
                SELECT
                    NUR
                FROM PWST.CATALOGOS_Rutas_Evaluables
            ),

            ventas_diarias AS (
                SELECT
                    V.NUR,
                    V.Fecha,
                    SUM(
                        CASE
                            WHEN B.Cliente IS NULL
                            THEN V.Cantidad
                            ELSE 0
                        END
                    ) AS Cantidad

                FROM PWST.POWERSTREET_Venta_Diaria V
                INNER JOIN rutas R
                    ON V.NUR = R.NUR
                LEFT JOIN PWST.CATALOGOS_Clientes_GTP B
                    ON V.Cliente = B.Cliente
                WHERE V.Fecha BETWEEN :fecha_inicio AND :fecha_fin

                GROUP BY
                    V.NUR,
                    V.Fecha
            )

            SELECT
                NUR,
                Fecha,
                Cantidad * 1.0 /
                    SUM(Cantidad) OVER (
                        PARTITION BY
                            NUR,
                            YEAR(Fecha),
                            MONTH(Fecha)
                    ) AS Peso_Real
            FROM ventas_diarias

            ORDER BY
                NUR,
                Fecha;
        """),
        con=motor,
        params={"fecha_inicio":fecha_inicio,"fecha_fin":fecha_fin}
    )

    df_claves_nur=pd.read_sql(
        text("""
        SELECT
            Agencia,
            Clave_NUR    
        FROM PWST.CATALOGOS_Agencias
        """),
        con=motor
    )
    motor.dispose()
    return df_venta_diaria, df_claves_nur

@manejar_error_conexion_sql
def obtener_meta_volumen(fecha_inicio: date):
    motor = obtener_motor()

    df = pd.read_sql(
        text("""
            SELECT
                Fecha,
                ((DATEPART(WEEKDAY, Fecha) + @@DATEFIRST - 2) % 7) + 1 AS Dia_Semana,
                (
                    DAY(Fecha)
                    +
                    (
                        (
                            DATEPART(
                                WEEKDAY,
                                DATEFROMPARTS(
                                    YEAR(Fecha),
                                    MONTH(Fecha),
                                    1
                                )
                            )
                            + @@DATEFIRST - 2
                        ) % 7
                    )
                    - 1
                ) / 7 + 1 AS Semana_Mes,
                NUR,
                Valor_Meta AS Meta_Volumen
            FROM PWST.SADS_SegOper_Metas
            WHERE Fecha >= DATEFROMPARTS(
                YEAR(:fecha_inicio),
                MONTH(:fecha_inicio),
                1
            )
            AND Fecha < DATEADD(
                DAY,
                1,
                EOMONTH(:fecha_inicio)
            )
            ORDER BY
                Fecha ASC,
                NUR ASC;
        """),
        con=motor,
        params={"fecha_inicio": fecha_inicio}
    )
    motor.dispose()
    return df
#=====================================================
# VARIABLES, PARAMETROS Y DATOS
#=====================================================

#parametros
mes_min, mes_max, agencias_a_trabajar = obtener_parametros_proceso()
cortes_regimen = {
    "dia muy malo": 0.05,
    "dia malo": 0.15,
    "dia normal": 0.80
}
tamaño_muestra=100


#variables
fecha_hoy = date(2026, 8, 1)
#fecha_hoy=date.today()+relativedelta(day=1)
mes_inicio_proceso=fecha_hoy+relativedelta(day=1, months=-mes_max) 
mes_fin_proceso= fecha_hoy+relativedelta(day=1, months=-mes_min)
fecha_inicio=mes_inicio_proceso
fecha_fin= mes_fin_proceso+relativedelta(day=31)

meses = pd.date_range(
    start=mes_inicio_proceso,
    end=mes_fin_proceso,
    freq="MS"
)

#datos
df_venta_diaria, df_claves_nur = obtener_dfs_sql(fecha_inicio=fecha_inicio, fecha_fin=fecha_fin)
df_meta_volumen_mensual = obtener_meta_volumen(fecha_inicio=fecha_hoy)

df_venta_diaria["Fecha"] = pd.to_datetime(df_venta_diaria["Fecha"])
df_meta_volumen_mensual["Fecha"]=pd.to_datetime(df_meta_volumen_mensual["Fecha"])
#==========================================================
# PROCESO
#==========================================================

#run de proceso MART de los ultimos 4 meses
resultados = []
for agencia in agencias_a_trabajar:

    for mes in meses:

        request = MARTRequest(mes=mes.month,anio=mes.year,agencia=agencia)
        df_mart = modeloMART(request=request)
        resultados.append(df_mart)

df_mart_final = pd.concat(resultados,ignore_index=True)
df_mart_final["Fecha"] = pd.to_datetime(df_mart_final["Fecha"])

#obtencion de error entre peso real y peso esperado
df_simulaciones=(
    df_mart_final
    .merge(
        df_venta_diaria,
        on=["NUR", "Fecha"],
        how="left"
    )
    .assign(
        Error=lambda x: x["Peso_Real"]/x["Peso_Esperado"],
        Regimen=lambda x: np.select(
            [
                x["Error"].isna(),
                x["Error"] <= x["Error"].quantile(cortes_regimen["dia muy malo"]),
                x["Error"] <= x["Error"].quantile(cortes_regimen["dia malo"]),
                x["Error"] <= x["Error"].quantile(cortes_regimen["dia normal"])
            ],
            [
                "dia sin operacion",
                "dia muy malo",
                "dia malo",
                "dia normal"
            ],
            default="dia bueno"
        ) 
    )
)
df_simulaciones.to_excel(
    "df_simulaciones.xlsx",
    index=False
)


# simulación bootstrap
resultados_bootstrap = []
for agencia in agencias_a_trabajar:

    # Fechas del mes a simular
    fechas = pd.date_range(
        start=fecha_hoy,
        end=fecha_hoy + relativedelta(day=31),
        freq="D"
    )

    # Obtener clave de la agencia
    clave_nur = df_claves_nur.loc[
        df_claves_nur["Agencia"] == agencia,
        "Clave_NUR"
    ].iloc[0]

    # Obtener NURs de la agencia
    rutas = (
        df_simulaciones.loc[
            df_simulaciones["NUR"].str.contains(
                clave_nur,
                regex=False
            ),
            "NUR"
        ]
        .unique()
    )

    # Filtrar simulaciones de la agencia
    df_simulaciones_agencia = df_simulaciones[
        df_simulaciones["NUR"].isin(rutas)
    ]

    # ==========================================
    # CONSTRUIR DISTRIBUCIONES HISTÓRICAS
    # ==========================================
    distribuciones = {}
    for ruta in rutas:

        for dia_semana in range(1, 7):

            filtrado = df_simulaciones_agencia[
                (df_simulaciones_agencia["NUR"] == ruta) &
                (df_simulaciones_agencia["Fecha"].dt.dayofweek + 1 == dia_semana)
            ]

            probabilidades = (
                filtrado["Regimen"]
                .value_counts(normalize=True)
            )

            errores = {
                regimen: filtrado.loc[
                    filtrado["Regimen"] == regimen,
                    "Error"
                ].dropna().to_numpy()
                for regimen in probabilidades.index
            }

            distribuciones[(ruta, dia_semana)] = {
                "regimenes": probabilidades.index.to_numpy(),
                "probabilidades": probabilidades.values,
                "errores": errores
            }

    # ==========================================
    # BOOTSTRAP
    # ==========================================
    for ruta in rutas:

        for i in tqdm(
            range(1, tamaño_muestra + 1),
            desc=f"Bootstrap {agencia} - {ruta}"
        ):

            for fecha in fechas:

                dia_semana = fecha.dayofweek + 1

                if dia_semana == 7:
                    continue

                dist = distribuciones[(ruta, dia_semana)]
                
                regimen = np.random.choice(
                    dist["regimenes"],
                    p=dist["probabilidades"]
                )

                if regimen == "dia sin operacion":
                    error = 0
                else:
                    if len(dist["errores"][regimen]) == 0:
                        print(
                            f"""
                            🚨 RÉGIMEN SIN ERRORES
                            Agencia: {agencia}
                            NUR: {ruta}
                            Fecha: {fecha}
                            Día semana: {dia_semana}
                            Régimen: {regimen}
                            """
                        )
                        raise ValueError("Régimen seleccionado sin errores históricos")

                    error = np.random.choice(
                        dist["errores"][regimen]
                    )

                resultados_bootstrap.append({
                    "Agencia": agencia,
                    "Simulacion": i,
                    "NUR": ruta,
                    "Fecha": fecha,
                    "Dia_Semana": dia_semana,
                    "Regimen": regimen,
                    "Error": error
                })

df_bootstrap = pd.DataFrame(resultados_bootstrap)
df_bootstrap.to_excel(
    "df_bootstrap.xlsx",
    index=False
)

print("BOOTSTRAP:")
print(df_bootstrap.shape)
print(df_bootstrap[["NUR", "Fecha", "Error"]].head())

print("\nMETA:")
print(df_meta_volumen_mensual.shape)
print(df_meta_volumen_mensual[["NUR", "Fecha", "Meta_Volumen"]].head())

print("\nTIPOS:")
print(df_bootstrap[["NUR", "Fecha"]].dtypes)
print(df_meta_volumen_mensual[["NUR", "Fecha"]].dtypes)

df_prueba = df_bootstrap.merge(
    df_meta_volumen_mensual,
    on=["NUR", "Fecha"],
    how="left"
)

print("\nDESPUÉS DEL MERGE:")
print(df_prueba.shape)

print("\nMETA ENCONTRADA:")
print(df_prueba["Meta_Volumen"].notna().sum())

print("\nMETA NO ENCONTRADA:")
print(df_prueba["Meta_Volumen"].isna().sum())

print(df_prueba[[
    "NUR",
    "Fecha",
    "Error",
    "Meta_Volumen"
]].head(20))

#Conversion de errores a paquetes
df_conversion = (
    df_bootstrap
    .merge(
        df_meta_volumen_mensual,
        on=["NUR", "Fecha"],
        how="left"
    )
    .assign(
        Volumen_Simulado=lambda x:
            x["Meta_Volumen"] * x["Error"]
    )
    .groupby(
        ["Simulacion", "NUR", "Semana_Mes"],
        as_index=False
    )["Volumen_Simulado"]
    .sum()
)   

df_conversion.to_excel(
    "df_conversion.xlsx",
    index=False
)