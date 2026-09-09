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
import os

#=================================================
#IMPORTS
#=================================================

#funciones
from batchProcess.Simulaciones.Config.conexion_SQL import(
    manejar_error_conexion_sql,
    obtener_motor
)
from fastAPI.Modelos.MART.Schemas.request import MARTRequest
from fastAPI.Modelos.MART.modeloMART import modeloMART

#variables de entorno
schema=os.getenv("SCHEMA")
tabla_ventas=os.getenv("TABLA_VENTAS")
tabla_simulaciones=os.getenv("TABLA_SIMULACIONES")
tabla_ponderaciones=os.getenv("TABLA_POND_MODELO")
tabla_rutas=os.getenv("TABLA_RUTAS")
tabla_clientesgtp=os.getenv("TABLA_CLIENTESGTP")
tabla_agencias=os.getenv("TABLA_AGENCIAS")
tabla_metas_diarias=os.getenv("TABLA_METASDIARIAS")

#======================================================
# FUNCIONES
#======================================================

#Subir df_final a sql
@manejar_error_conexion_sql
def subir_datos_sql(
    df_simulaciones: pd.DataFrame,
    schema:str,
    tabla_simulaciones:str)-> pd.DataFrame:

    df=df_simulaciones
    motor=obtener_motor()
    with motor.begin() as conn:
        # Obtener nombres de columnas exactos desde SQL Server en orden
        sql_column_query = text("""
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = :schema AND TABLE_NAME = :tabla
            ORDER BY ORDINAL_POSITION
        """)
        sql_column_result = conn.execute(
            sql_column_query,
            dict(schema=schema, tabla=tabla_simulaciones)
        ).fetchall()        
        sql_columns = [row[0] for row in sql_column_result]
        if len(df.columns) != len(sql_columns):
            raise ValueError(f"❌ El DataFrame tiene {len(df.columns)} columnas pero la tabla SQL tiene {len(sql_columns)}.")

        #borrar datos existentes
        conn.execute(text(f"""
            DELETE FROM {schema}.{tabla_simulaciones} 
            """
            )
        )
        print("Registros anteriores de simulaciones eliminados")

        #subir datos
        df.to_sql(
            name=tabla_simulaciones,
            con=conn,
            schema=schema,
            if_exists="append",
            chunksize=10000,
            method=None,
            index=False
        )
        print("✅ Datos insertados correctamente.")


#obtencion de parametros 
@manejar_error_conexion_sql
def obtener_parametros_proceso(
    schema:str,
    tabla_ponderaciones:str,
    tabla_agencias:str):

    motor = obtener_motor()
    mes_max = pd.read_sql(
        text(f"""
            SELECT MAX(Mes) AS Mes
            FROM {schema}.{tabla_ponderaciones}
        """),
        con=motor
    )["Mes"].iloc[0]

    mes_min = pd.read_sql(
        text(f"""
            SELECT MIN(Mes) AS Mes
            FROM {schema}.{tabla_ponderaciones}
        """),
        con=motor
    )["Mes"].iloc[0]

    agencias_a_trabajar = pd.read_sql(
        text(f"""
            SELECT DISTINCT
                Agencia
            FROM {schema}.{tabla_agencias}
            WHERE Agencia NOT IN (2, 3, 9, 10)
            ORDER BY Agencia ASC
        """),
        con=motor
    )["Agencia"].tolist()

    motor.dispose()

    return mes_min, mes_max, agencias_a_trabajar

#obtencion de df´s extras de sql
@manejar_error_conexion_sql
def obtener_dfs_sql(
    fecha_inicio:date, 
    fecha_fin:date,
    fecha_hoy:date,
    schema:str,
    tabla_rutas:str,
    tabla_ventas:str,
    tabla_clietesgtp:str,
    tabla_metas_diarias:str,
    tabla_agencias:str):

    motor = obtener_motor()
    df_venta_diaria = pd.read_sql(
        text(f"""
            WITH rutas AS (
                SELECT DISTINCT
                    R.NUR
                FROM {schema}.{tabla_rutas} R
                INNER JOIN {schema}.{tabla_metas_diarias} M
                    ON R.NUR = M.NUR
                WHERE M.Indicador = 'VOLUMEN'
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

                FROM {schema}.{tabla_ventas} V
                INNER JOIN rutas R
                    ON V.NUR = R.NUR
                LEFT JOIN {schema}.{tabla_clietesgtp} B
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

    df_meta_volumen_mensual = pd.read_sql(
        text(f"""
            SELECT
                Fecha,
                ((DATEPART(WEEKDAY, Fecha) + @@DATEFIRST - 2) % 7) + 1 AS Dia_Semana,
                NUR,
                Valor_Meta AS Meta_Volumen
            FROM {schema}.{tabla_metas_diarias}
            WHERE Fecha >= DATEFROMPARTS(
                YEAR(:fecha_hoy),
                MONTH(:fecha_hoy),
                1
            )
            AND Fecha < DATEADD(
                DAY,
                1,
                EOMONTH(:fecha_hoy)
            )
            AND Indicador='VOLUMEN'
            ORDER BY
                Fecha ASC,
                NUR ASC;
        """),
        con=motor,
        params={"fecha_hoy": fecha_hoy}
    )

    df_claves_nur=pd.read_sql(
        text(f"""
        SELECT
            Agencia,
            Clave_NUR    
        FROM {schema}.{tabla_agencias}
        """),
        con=motor
    )
    motor.dispose()
    return df_venta_diaria, df_claves_nur, df_meta_volumen_mensual


#==========================================================
# VARIABLES, PARAMETROS Y DATOS
#==========================================================

#parametros
fecha_hoy = date(2026, 8, 1)
#fecha_hoy=date.today()+relativedelta(day=1)

mes_min, mes_max, agencias_a_trabajar = obtener_parametros_proceso(
    schema=schema,
    tabla_ponderaciones=tabla_ponderaciones,
    tabla_agencias=tabla_agencias
)

cortes_regimen = {
    "dia muy malo": 0.05,
    "dia malo": 0.15,
    "dia normal": 0.80
}
tamaño_muestra=100


#variables
mes_inicio_proceso=fecha_hoy+relativedelta(day=1, months=-mes_max) 
mes_fin_proceso= fecha_hoy+relativedelta(day=1, months=-mes_min)
fecha_inicio=mes_inicio_proceso
fecha_fin= mes_fin_proceso+relativedelta(day=31)
meses = pd.date_range(
    start=mes_inicio_proceso,
    end=mes_fin_proceso,
    freq="MS")

#df´s
df_venta_diaria, df_claves_nur, df_meta_volumen_mensual = obtener_dfs_sql(
    fecha_inicio=fecha_inicio,
    fecha_fin=fecha_fin,
    fecha_hoy=fecha_hoy,
    schema=schema,
    tabla_rutas=tabla_rutas,
    tabla_ventas=tabla_ventas,
    tabla_clietesgtp=tabla_clientesgtp,
    tabla_metas_diarias=tabla_metas_diarias,
    tabla_agencias=tabla_agencias)
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
# y clasificacion de regimen de error por nur
df_simulaciones = (
    df_mart_final
    .merge(
        df_venta_diaria,
        on=["NUR", "Fecha"],
        how="left"
    )
    .assign(
        Error=lambda x: x["Peso_Real"] / x["Peso_Esperado"],

        Q05=lambda x:
            x.groupby("NUR")["Error"]
             .transform(
                 lambda s: s.quantile(
                     cortes_regimen["dia muy malo"]
                 )
             ),

        Q15=lambda x:
            x.groupby("NUR")["Error"]
             .transform(
                 lambda s: s.quantile(
                     cortes_regimen["dia malo"]
                 )
             ),

        Q80=lambda x:
            x.groupby("NUR")["Error"]
             .transform(
                 lambda s: s.quantile(
                     cortes_regimen["dia normal"]
                 )
             ),

        Regimen=lambda x: np.select(
            [
                x["Error"].isna(),
                x["Error"] <= x["Q05"],
                x["Error"] <= x["Q15"],
                x["Error"] <= x["Q80"]
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
    .drop(columns=["Q05", "Q15", "Q80"])
)
"""
df_simulaciones.to_excel(
    "df_simulaciones.xlsx",
    index=False
)
"""

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
"""
df_bootstrap.to_excel(
    "df_bootstrap.xlsx",
    index=False
)
"""


#Conversion de errores a paquetes
df_conversion = (
    df_bootstrap
    .merge(
        df_meta_volumen_mensual,
        on=["NUR", "Fecha"],
        how="inner",
        validate="many_to_one"
    )
    .assign(
        Volumen_Simulado=lambda x:
            (x["Meta_Volumen"] * x["Error"]).round(6)
    )
    [["Simulacion", "Agencia", "NUR", "Fecha", "Volumen_Simulado"]]
)

#subir a sql
subir_datos_sql(
    df_simulaciones=df_conversion,
    schema=schema,
    tabla_simulaciones=tabla_simulaciones)

df_conversion.to_excel(
    "df_conversion.xlsx",
    index=False
)



