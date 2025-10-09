-- Migración para crear la tabla activity en GlucoSmart
-- Esta migración crea la tabla activity con sus índices, políticas RLS y trigger para updated_at
-- Compatible con Supabase Postgres

-- Crear la tabla activity
CREATE TABLE activity (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    steps INTEGER NOT NULL CHECK (steps >= 0), -- Pasos dados, debe ser positivo
    calories_burned NUMERIC(6,2) NOT NULL CHECK (calories_burned >= 0), -- Calorías quemadas, positivo
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    duration_minutes INTEGER CHECK (duration_minutes > 0), -- Duración en minutos, opcional pero positivo si presente
    activity_type TEXT, -- Tipo de actividad (opcional)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices para optimizar consultas
-- Índice compuesto en user_id y timestamp para consultas ordenadas por usuario y tiempo
CREATE INDEX idx_activity_user_timestamp ON activity(user_id, timestamp DESC);

-- Índice adicional en user_id para consultas por usuario
CREATE INDEX idx_activity_user_id ON activity(user_id);

-- Habilitar Row Level Security (RLS) para acceso seguro
ALTER TABLE activity ENABLE ROW LEVEL SECURITY;

-- Política RLS: Los usuarios solo pueden ver sus propios registros de actividad
CREATE POLICY "Users can view own activity records" ON activity
    FOR SELECT USING (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden insertar sus propios registros de actividad
CREATE POLICY "Users can insert own activity records" ON activity
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden actualizar sus propios registros de actividad
CREATE POLICY "Users can update own activity records" ON activity
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden eliminar sus propios registros de actividad
CREATE POLICY "Users can delete own activity records" ON activity
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at en cada modificación
-- Reutiliza la función existente update_updated_at_column creada en la migración inicial
CREATE TRIGGER trigger_update_activity_updated_at
    BEFORE UPDATE ON activity
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios adicionales:
-- - La tabla usa UUID para id y user_id para integrarse con el sistema de autenticación de Supabase
-- - CHECK constraints aseguran valores positivos para steps y calories_burned
-- - duration_minutes es opcional pero debe ser positivo si se proporciona
-- - activity_type permite categorizar el tipo de ejercicio (caminar, correr, etc.)
-- - Las políticas RLS garantizan que cada usuario solo acceda a sus propios datos de actividad
-- - El trigger mantiene updated_at actualizado automáticamente para auditoría
-- - El índice compuesto optimiza consultas por usuario ordenadas por timestamp descendente