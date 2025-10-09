-- Migración para crear la tabla personalized_plans en GlucoSmart
-- Esta migración crea la tabla personalized_plans con sus índices, políticas RLS y trigger para updated_at
-- Compatible con Supabase Postgres

-- Crear la tabla personalized_plans
CREATE TABLE personalized_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    goals TEXT[] DEFAULT '{}',
    recommendations JSONB NOT NULL,
    risk_level TEXT NOT NULL CHECK (risk_level IN ('low', 'medium', 'high')),
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices para optimizar consultas
-- Índice compuesto en user_id y generated_at para consultas ordenadas
CREATE INDEX idx_personalized_plans_user_generated ON personalized_plans(user_id, generated_at DESC);

-- Índice en user_id para consultas por usuario
CREATE INDEX idx_personalized_plans_user_id ON personalized_plans(user_id);

-- Índice en is_active para filtrar planes activos
CREATE INDEX idx_personalized_plans_active ON personalized_plans(is_active) WHERE is_active = true;

-- Índice en valid_until para expiración
CREATE INDEX idx_personalized_plans_valid_until ON personalized_plans(valid_until);

-- Habilitar Row Level Security (RLS) para acceso seguro
ALTER TABLE personalized_plans ENABLE ROW LEVEL SECURITY;

-- Política RLS: Los usuarios solo pueden ver sus propios planes
CREATE POLICY "Users can view own personalized plans" ON personalized_plans
    FOR SELECT USING (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden insertar sus propios planes
CREATE POLICY "Users can insert own personalized plans" ON personalized_plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden actualizar sus propios planes
CREATE POLICY "Users can update own personalized plans" ON personalized_plans
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden eliminar sus propios planes
CREATE POLICY "Users can delete own personalized plans" ON personalized_plans
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at en cada modificación
-- Reutiliza la función existente update_updated_at_column creada en la migración inicial
CREATE TRIGGER trigger_update_personalized_plans_updated_at
    BEFORE UPDATE ON personalized_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios adicionales:
-- - La tabla usa UUID para id y user_id para integrarse con el sistema de autenticación de Supabase
-- - recommendations es JSONB para almacenar estructura compleja de recomendaciones
-- - goals es array de texto para objetivos del plan
-- - valid_until permite expiración automática de planes
-- - is_active permite desactivar planes sin eliminarlos
-- - Las políticas RLS garantizan que cada usuario solo acceda a sus propios planes
-- - Los índices optimizan consultas por usuario, fecha y estado