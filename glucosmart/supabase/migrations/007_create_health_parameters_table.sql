-- Migración para crear la tabla health_parameters en GlucoSmart
-- Esta migración crea la tabla health_parameters con sus índices, políticas RLS y trigger para updated_at
-- Compatible con Supabase Postgres

-- Crear la tabla health_parameters
CREATE TABLE health_parameters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('weight', 'hba1c', 'bloodPressure', 'sleepHours')),
    value NUMERIC(6,2) NOT NULL CHECK (value > 0),
    unit TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices para optimizar consultas
-- Índice compuesto en user_id y timestamp para consultas ordenadas por usuario y tiempo
CREATE INDEX idx_health_parameters_user_timestamp ON health_parameters(user_id, timestamp DESC);

-- Índice adicional en user_id para consultas por usuario
CREATE INDEX idx_health_parameters_user_id ON health_parameters(user_id);

-- Índice en type para filtrar por tipo de parámetro
CREATE INDEX idx_health_parameters_type ON health_parameters(type);

-- Habilitar Row Level Security (RLS) para acceso seguro
ALTER TABLE health_parameters ENABLE ROW LEVEL SECURITY;

-- Política RLS: Los usuarios solo pueden ver sus propios parámetros de salud
CREATE POLICY "Users can view own health parameters" ON health_parameters
    FOR SELECT USING (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden insertar sus propios parámetros de salud
CREATE POLICY "Users can insert own health parameters" ON health_parameters
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden actualizar sus propios parámetros de salud
CREATE POLICY "Users can update own health parameters" ON health_parameters
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden eliminar sus propios parámetros de salud
CREATE POLICY "Users can delete own health parameters" ON health_parameters
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at en cada modificación
-- Reutiliza la función existente update_updated_at_column creada en la migración inicial
CREATE TRIGGER trigger_update_health_parameters_updated_at
    BEFORE UPDATE ON health_parameters
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios adicionales:
-- - La tabla usa UUID para id y user_id para integrarse con el sistema de autenticación de Supabase
-- - El CHECK en type asegura que solo se permitan tipos válidos de parámetros
-- - El CHECK en value asegura valores positivos
-- - unit es opcional ya que puede inferirse del type
-- - Las políticas RLS garantizan que cada usuario solo acceda a sus propios datos de salud
-- - El trigger mantiene updated_at actualizado automáticamente para auditoría
-- - Los índices optimizan consultas por usuario, tiempo y tipo