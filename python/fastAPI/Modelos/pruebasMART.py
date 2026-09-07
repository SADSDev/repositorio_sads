from fastAPI.Modelos.MART.Schemas.request import MARTRequest
from fastAPI.Modelos.MART.modeloMART import modeloMART
from fastAPI.Modelos.MART.procesos.procesoDatosMART import obtener_datos_modelo
request = MARTRequest(
    anio=2026,
    mes=4,
    agencia=1
)



df_mart = modeloMART(request)

resultados = obtener_datos_modelo(
    anio=request.anio,
    mes=request.mes,
    agencia=request.agencia
)

df_cal = resultados["df_calendario_rutas"]
df_suav = resultados["df_suavizado_jerarquico"]

print("Suavizado:")
print(df_suav[[
    "NUR",
    "Dia_Mes",
    "Dia_Semana",
    "Alpha",
    "Beta",
    "Upsilon",
    "Prom_Suavizado"
]].isna().sum())

print("\nTipos de datos:")
print(df_cal[["NUR", "Dia_Mes", "Dia_Semana"]].dtypes)
print(df_suav[["NUR", "Dia_Mes", "Dia_Semana"]].dtypes)

df_revision = df_cal.merge(
    df_suav[
        [
            "NUR",
            "Dia_Mes",
            "Dia_Semana",
            "Prom_Suavizado"
        ]
    ],
    on=["NUR", "Dia_Mes", "Dia_Semana"],
    how="left",
    indicator=True
)

print("\nResultado del merge:")
print(df_revision["_merge"].value_counts())

print("\nProm_Suavizado no nulos:")
print(df_suav["Prom_Suavizado"].notna().sum())

df_mart.to_excel(
    "df_mart.xlsx",
    index=False
)