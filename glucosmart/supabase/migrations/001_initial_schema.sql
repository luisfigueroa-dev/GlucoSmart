-- Migración inicial para el esquema de la base de datos de GlucoSmart
-- Esta migración crea la tabla glucose con sus índices, políticas RLS y triggers necesarios
-- Compatible con Supabase Postgres

-- Habilitar la extensión UUID si no está activada
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Crear la tabla glucose
CREATE TABLE glucose (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    value NUMERIC(5,2) NOT NULL CHECK (value > 0 AND value < 1000), -- Valor en mg/dL, rango razonable
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices para optimizar consultas
-- Índice compuesto en user_id y timestamp para consultas ordenadas por usuario y tiempo
CREATE INDEX idx_glucose_user_timestamp ON glucose(user_id, timestamp DESC);

-- Índice adicional en user_id para consultas por usuario
CREATE INDEX idx_glucose_user_id ON glucose(user_id);

-- Habilitar Row Level Security (RLS) para acceso seguro
ALTER TABLE glucose ENABLE ROW LEVEL SECURITY;

-- Política RLS: Los usuarios solo pueden ver sus propios registros
CREATE POLICY "Users can view own glucose records" ON glucose
    FOR SELECT USING (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden insertar sus propios registros
CREATE POLICY "Users can insert own glucose records" ON glucose
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden actualizar sus propios registros
CREATE POLICY "Users can update own glucose records" ON glucose
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden eliminar sus propios registros
CREATE POLICY "Users can delete own glucose records" ON glucose
    FOR DELETE USING (auth.uid() = user_id);

-- Función para actualizar automáticamente updated_at
-- Esta función se usa en el trigger para mantener la columna updated_at actualizada
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at en cada modificación
-- Se ejecuta antes de UPDATE en la tabla glucose
CREATE TRIGGER trigger_update_glucose_updated_at
    BEFORE UPDATE ON glucose
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios adicionales:
-- - La tabla usa UUID para id y user_id para integrarse con el sistema de autenticación de Supabase
-- - El CHECK en value asegura valores razonables de glucosa (0-1000 mg/dL)
-- - Las políticas RLS garantizan que cada usuario solo acceda a sus propios datos
-- - El trigger mantiene updated_at actualizado automáticamente para auditoría