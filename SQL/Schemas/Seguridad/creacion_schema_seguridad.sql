--Creacion del schema "Seguridad"
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'Seguridad'
)
BEGIN
    EXEC('CREATE SCHEMA Seguridad');
END;
GO