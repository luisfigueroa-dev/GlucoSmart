-- Migración para crear la tabla user_stats en GlucoSmart
-- Esta migración crea la tabla user_stats con sus índices, políticas RLS y trigger para updated_at
-- Compatible con Supabase Postgres

-- Crear la tabla user_stats
CREATE TABLE user_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL DEFAULT 0 CHECK (points >= 0),
    level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
    streak_days INTEGER NOT NULL DEFAULT 0 CHECK (streak_days >= 0),
    last_activity TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    achievements TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices para optimizar consultas
-- Índice compuesto en user_id para consultas por usuario
CREATE INDEX idx_user_stats_user_id ON user_stats(user_id);

-- Habilitar Row Level Security (RLS) para acceso seguro
ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;

-- Política RLS: Los usuarios solo pueden ver sus propias estadísticas
CREATE POLICY "Users can view own stats" ON user_stats
    FOR SELECT USING (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden insertar sus propias estadísticas
CREATE POLICY "Users can insert own stats" ON user_stats
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden actualizar sus propias estadísticas
CREATE POLICY "Users can update own stats" ON user_stats
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden eliminar sus propias estadísticas
CREATE POLICY "Users can delete own stats" ON user_stats
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at en cada modificación
-- Reutiliza la función existente update_updated_at_column creada en la migración inicial
CREATE TRIGGER trigger_update_user_stats_updated_at
    BEFORE UPDATE ON user_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios adicionales:
-- - La tabla usa UUID para id y user_id para integrarse con el sistema de autenticación de Supabase
-- - points y level tienen checks para valores positivos
-- - achievements es un array de texto para logros desbloqueados
-- - Las políticas RLS garantizan que cada usuario solo acceda a sus propios datos
-- - El trigger mantiene updated_at actualizado automáticamente para auditoría