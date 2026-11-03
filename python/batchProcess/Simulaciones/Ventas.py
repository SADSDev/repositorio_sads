#Este proceso para cada una de las
#rutas evaluables, obtener la diferencia entre el comportamiento
#obtenido del MART vs el real durante cada uno de los 4 meses
#anteriores al actual, para proceder a simularlos y obtener un 
#una cantidad determinada de simulaciones por cada dia y ruta

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
import requests
#=================================================
#IMPORTS
#=================================================

#funciones
from batchProcess.Simulaciones.Config.conexion_SQL import(
    manejar_error_conexion_sql,
    obtener_motor
)

#variables de entorno
schema=os.getenv("SCHEMA")
tabla_calendario=os.getenv("TABLA_CALENDARIO")
tabla_ventas=os.getenv("TABLA_VENTAS")
tabla_simulaciones_diarias=os.getenv("TABLA_SIMULACIONES_DIARIAS")
tabla_simulaciones_mensuales=os.getenv("TABLA_SIMULACIONES_MENSUALES")
tabla_ponderaciones=os.getenv("TABLA_POND_MODELO")
tabla_rutas=os.getenv("TABLA_RUTAS")
tabla_clientesgtp=os.getenv("TABLA_CLIENTESGTP")
tabla_agencias=os.getenv("TABLA_AGENCIAS")
tabla_metas_diarias=os.getenv("TABLA_METASDIARIAS")
fastapi_url=os.getenv("FASTAPI_URL")
#======================================================
# FUNCIONES
#======================================================

#Subir df_final a sql
@manejar_error_conexion_sql
def subir_datos_sql(
    df_simulaciones: pd.DataFrame,
    schema:str,
    mes_actual:date,
    tabla_simulaciones_diarias:str,
    tabla_simulaciones_mensuales:str,
    tabla_calendario: str,
    nur_a_borrar:str)-> pd.DataFrame:

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
            dict(schema=schema, tabla=tabla_simulaciones_diarias)
        ).fetchall()        
        sql_columns = [row[0] for row in sql_column_result]
        if len(df.columns) != len(sql_columns):
            raise ValueError(f"❌ El DataFrame tiene {len(df.columns)} columnas pero la tabla SQL tiene {len(sql_columns)}.")

        #borrar datos existentes del nur de las tablas de simualciones
        conn.execute(text(f"""
            DELETE FROM {schema}.{tabla_simulaciones_diarias}
            WHERE NUR= '{nur_a_borrar}'
            """
            )
        )
        conn.execute(text(f"""
            DELETE FROM {schema}.{tabla_simulaciones_mensuales}
            WHERE NUR = '{nur_a_borrar}'
            AND MONTH(Mes)=MONTH('{mes_actual}')
            AND YEAR(Mes)=YEAR('{mes_actual}')
            """
            )
        )
        print(f"Registros anteriores de simulaciones de {nur_a_borrar} eliminados")

        #subir datos
        df.to_sql(
            name=tabla_simulaciones_diarias,
            con=conn,
            schema=schema,
            if_exists="append",
            chunksize=10000,
            method=None,
            index=False
        )

        # actualizar tabla de simulaciones mensuales con nuevos datos
        conn.execute(text(f"""
                SELECT
                    S.NUR,
                    S.Simulacion,
                    DATEFROMPARTS(YEAR(S.Fecha), MONTH(S.Fecha), 1) AS Mes,
                    SUM(S.Volumen_Simulado) AS Volumen_Simulado_Mensual
                INTO #simulaciones_mensuales
                FROM {schema}.{tabla_simulaciones_diarias} AS S
                INNER JOIN {schema}.{tabla_calendario} AS C
                    ON S.Fecha = C.Fecha
                WHERE
                    C.Es_Habil = 1
                    AND S.NUR = '{nur_a_borrar}'
                    AND S.Fecha >= '{mes_actual}'
                    AND S.Fecha < DATEADD(MONTH, 1, '{mes_actual}')
                GROUP BY
                    S.NUR,
                    S.Simulacion,
                    DATEFROMPARTS(YEAR(S.Fecha), MONTH(S.Fecha), 1)
                ORDER BY
                    S.NUR,
                    S.Simulacion ASC;

                INSERT INTO {schema}.{tabla_simulaciones_mensuales}
                (
                    NUR,
                    Simulacion,
                    Mes,
                    Volumen_Simulado_Mensual
                )
                SELECT
                    NUR,
                    Simulacion,
                    Mes,
                    Volumen_Simulado_Mensual
                FROM #simulaciones_mensuales;
            """
        ))
        print("✅ Datos insertados correctamente.")


#obtencion de parametros 
@manejar_error_conexion_sql
def obtener_parametros_proceso(
    schema:str,
    tabla_ponderaciones:str,
    tabla_agencias:str):

    motor = obtener_motor()

    fecha_hoy=pd.read_sql(
        text(f"""
            SELECT DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS Fecha_Hoy
        """
        ),
        con=motor
    )["Fecha_Hoy"].iloc[0]

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

    return fecha_hoy, mes_min, mes_max, agencias_a_trabajar

#obtencion de df´s extras de sql
@manejar_error_conexion_sql
def obtener_dfs_sql(
    fecha_inicio:date, 
    fecha_fin:date,
    schema:str,
    tabla_rutas:str,
    tabla_ventas:str,
    tabla_clietesgtp:str,
    tabla_agencias:str):

    motor = obtener_motor()
    df_venta_diaria = pd.read_sql(
        text(f"""
            WITH rutas AS (
                SELECT DISTINCT
                    NUR
                FROM {schema}.{tabla_rutas} 
                WHERE Evaluable=1
            ),

            ventas_diarias AS (
                SELECT
                    V.NUR,
                    V.Fecha,
                    SUM(
                        CASE
                            WHEN C.Cliente IS NULL
                            THEN V.Cantidad
                            ELSE 0
                        END
                    ) AS Cantidad

                FROM {schema}.{tabla_ventas} V
                INNER JOIN rutas R
                    ON V.NUR = R.NUR
                LEFT JOIN {schema}.{tabla_clietesgtp} C
                    ON V.Cliente = C.Cliente
                WHERE V.Fecha BETWEEN :fecha_inicio AND :fecha_fin

                GROUP BY
                    V.NUR,
                    V.Fecha
            )

            SELECT
                NUR,
                Fecha,
                Cantidad,
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
        text(f"""
        SELECT
            Agencia,
            Clave_NUR    
        FROM {schema}.{tabla_agencias}
        """),
        con=motor
    )
    motor.dispose()
    return df_venta_diaria, df_claves_nur


#==========================================================
# VARIABLES, PARAMETROS Y DATOS
#==========================================================

#parametros
# pruebas: fecha_hoy = date(2026, 8, 1)
#fecha_hoy=date.today()+relativedelta(day=1)

fecha_hoy, mes_min, mes_max, agencias_a_trabajar = obtener_parametros_proceso(
    schema=schema,
    tabla_ponderaciones=tabla_ponderaciones,
    tabla_agencias=tabla_agencias
)

cortes_regimen = {
    "dia muy malo": 0.05,
    "dia malo": 0.15,
    "dia normal": 0.80
}
tamaño_muestra=10000


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
df_venta_diaria, df_claves_nur = obtener_dfs_sql(
    fecha_inicio=fecha_inicio,
    fecha_fin=fecha_fin,
    schema=schema,
    tabla_rutas=tabla_rutas,
    tabla_ventas=tabla_ventas,
    tabla_clietesgtp=tabla_clientesgtp,
    tabla_agencias=tabla_agencias)
df_venta_diaria["Fecha"] = pd.to_datetime(df_venta_diaria["Fecha"])

#==========================================================
# PROCESO
#==========================================================

#run de proceso MART de los ultimos 4 meses
resultados = []
for agencia in agencias_a_trabajar:

    for mes in meses:
        payload={
            "mes":mes.month,
            "anio":mes.year,
            "agencia":agencia
        }
        request=requests.post(f"{fastapi_url}/mart", json=payload, timeout=60)
        print(f"ejecutando MART de agencia: {agencia}, periodo: {mes.month}-{mes.year}")
        request.raise_for_status()
        
        df_mart = pd.DataFrame(request.json())
        resultados.append(df_mart)

df_mart_final = pd.concat(resultados,ignore_index=True)
df_mart_final["Fecha"] = pd.to_datetime(df_mart_final["Fecha"])
"""
df_mart_final.to_excel(
    "df_mart.xlsx",
    index=False
)
"""
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
for agencia in agencias_a_trabajar:

    fechas = pd.date_range(
        start=fecha_hoy,
        end=fecha_hoy + relativedelta(day=31),
        freq="D"
    )

    clave_nur = df_claves_nur.loc[
        df_claves_nur["Agencia"] == agencia,
        "Clave_NUR"
    ].iloc[0]

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

    df_simulaciones_agencia = df_simulaciones[
        df_simulaciones["NUR"].isin(rutas)
    ]
    
    # ==========================================
    # DISTRIBUCIONES HISTÓRICAS
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

            ventas = {
                regimen: filtrado.loc[
                    filtrado["Regimen"] == regimen,
                    "Cantidad"
                ].dropna().to_numpy()
                for regimen in probabilidades.index
            }

            distribuciones[(ruta, dia_semana)] = {
                "regimenes": probabilidades.index.to_numpy(),
                "probabilidades": probabilidades.values,
                "errores": errores,
                "ventas": ventas
            }

    # ==========================================
    # BOOTSTRAP POR NUR
    # ==========================================
    for ruta in rutas:

        resultados_ruta = []

        for fecha in tqdm(
            fechas,
            desc=f"Bootstrap {agencia} - {ruta}"
        ):

            dia_semana = fecha.dayofweek + 1

            if dia_semana == 7:
                continue

            dist = distribuciones[(ruta, dia_semana)]

            regimenes = np.random.choice(
                dist["regimenes"],
                size=tamaño_muestra,
                p=dist["probabilidades"]
            )

            errores_simulados = np.zeros(tamaño_muestra)
            ventas_simuladas = np.zeros(tamaño_muestra)

            for regimen in dist["regimenes"]:

                mascara = regimenes == regimen
                cantidad = mascara.sum()

                if cantidad == 0:
                    continue

                # ======================================
                # DÍA SIN OPERACIÓN
                # ======================================
                if regimen == "dia sin operacion":

                    errores_simulados[mascara] = 0
                    ventas_simuladas[mascara] = 0

                # ======================================
                # DÍAS CON OPERACIÓN
                # ======================================
                else:

                    errores_historicos = dist["errores"][regimen]
                    ventas_historicas = dist["ventas"][regimen]

                    # Validar que existan errores históricos
                    if len(errores_historicos) == 0:
                        raise ValueError(
                            f"Régimen sin errores históricos: "
                            f"Agencia={agencia}, "
                            f"NUR={ruta}, "
                            f"Fecha={fecha}, "
                            f"Régimen={regimen}"
                        )

                    # Validar que existan ventas históricas
                    if len(ventas_historicas) == 0:
                        raise ValueError(
                            f"Régimen sin ventas históricas: "
                            f"Agencia={agencia}, "
                            f"NUR={ruta}, "
                            f"Fecha={fecha}, "
                            f"Régimen={regimen}"
                        )

                    # ----------------------------------
                    # Venta histórica base
                    # ----------------------------------
                    indices = np.random.randint(
                        0,
                        len(ventas_historicas),
                        size=cantidad
                    )

                    ventas_base = ventas_historicas[indices]

                    # ----------------------------------
                    # Error histórico simulado
                    # ----------------------------------
                    errores_simulados[mascara] = np.random.choice(
                        errores_historicos,
                        size=cantidad,
                        replace=True
                    )

                    # ----------------------------------
                    # Venta simulada
                    # ----------------------------------
                    ventas_simuladas[mascara] = (
                        ventas_base *
                        errores_simulados[mascara]
                    )

            resultados_ruta.append(
                pd.DataFrame({
                    "Simulacion": np.arange(1, tamaño_muestra + 1),
                    "Agencia": agencia,
                    "NUR": ruta,
                    "Fecha": fecha,
                    "Error": errores_simulados,
                    "Volumen_Simulado": ventas_simuladas
                })
            )

        df_ruta = pd.concat(
            resultados_ruta,
            ignore_index=True
        )
        
        subir_datos_sql(
            df_simulaciones=df_ruta,
            schema=schema,
            mes_actual=fecha_hoy,
            tabla_simulaciones_diarias=tabla_simulaciones_diarias,
            tabla_simulaciones_mensuales=tabla_simulaciones_mensuales,
            tabla_calendario=tabla_calendario,
            nur_a_borrar=ruta
        )

        del resultados_ruta
        del df_ruta


#FIN

"""
df_bootstrap.to_excel(
    "df_bootstrap.xlsx",
    index=False
)
"""


