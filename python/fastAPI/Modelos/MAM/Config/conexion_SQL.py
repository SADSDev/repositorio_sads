#----------------------------
#LIBRERIAS
#-----------------------------
from functools import wraps

import pyodbc
from sqlalchemy import create_engine
from sqlalchemy.exc import InterfaceError, OperationalError


#----------------------------
#IMPORTS
#---------------------------
from Config.parametros import (
    servidor,
    bd,
    usuario,
    contrasena
)

from Core.exceptions import ErrorConexionSQL

#------------------------------------------------------------------------
# MANEJO DE ERRORES DE CONEXIÓN SQL
#------------------------------------------------------------------------
def manejar_error_conexion_sql(func):
    @wraps(func)
    def envoltura(*args, **kwargs):
        try:
            return func(*args, **kwargs)

        except (
            OperationalError,
            InterfaceError,
            pyodbc.Error
        ) as exc:
            raise ErrorConexionSQL(
                "No fue posible conectar con SQL Server."
            ) from exc

    return envoltura


#-------------------------------
#funciones para obtener driver del equipo y crear motor de conexion
#----------------------------------
def obtener_driver():

    drivers = pyodbc.drivers()

    drivers_prefer = [
        "ODBC Driver 18 for SQL Server",
        "ODBC Driver 17 for SQL Server",
        "ODBC Driver 13 for SQL Server",
        "ODBC Driver 12 for SQL Server"
    ]

    driver = next(
        (d for d in drivers_prefer if d in drivers),
        None
    )

    if driver is None:

        driver = next(
            (
                d
                for d in drivers
                if "SQL Server" in d
                and "ODBC Driver" in d
            ),
            None
        )

    if driver is None:
        raise RuntimeError(
            "No se encontró un driver SQL compatible"
        )

    return driver

def obtener_motor():

    driver = obtener_driver()

    direccion = (
        f"mssql+pyodbc://{usuario}:{contrasena}"
        f"@{servidor}:1433/{bd}"
        f"?driver={driver.replace(' ', '+')}"
        "&trustServerCertificate=Yes"
        "&Connection Timeout=30"
    )

    return create_engine(
        direccion,
        fast_executemany=True,
        pool_pre_ping=True
    )
