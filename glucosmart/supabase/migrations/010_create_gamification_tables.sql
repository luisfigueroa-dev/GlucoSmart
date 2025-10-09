-- Migración para crear las tablas de gamificación en GlucoSmart
-- Esta migración crea las tablas achievements y user_gamification_stats
-- Compatible con Supabase Postgres

-- Crear la tabla achievements
CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('glucose', 'activity', 'nutrition', 'education', 'adherence', 'social', 'milestone')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_name TEXT NOT NULL,
    points INTEGER NOT NULL CHECK (points > 0),
    target_value INTEGER NOT NULL CHECK (target_value > 0),
    current_value INTEGER NOT NULL DEFAULT 0 CHECK (current_value >= 0),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    is_claimed BOOLEAN NOT NULL DEFAULT FALSE,
    date_earned TIMESTAMPTZ,
    category TEXT NOT NULL CHECK (category IN ('health', 'knowledge', 'community', 'special')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear la tabla user_gamification_stats
CREATE TABLE user_gamification_stats (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    total_points INTEGER NOT NULL DEFAULT 0 CHECK (total_points >= 0),
    level INTEGER NOT NULL DEFAULT 1 CHECK (level > 0),
    current_level_points INTEGER NOT NULL DEFAULT 0 CHECK (current_level_points >= 0),
    points_to_next_level INTEGER NOT NULL DEFAULT 100 CHECK (points_to_next_level > 0),
    total_achievements INTEGER NOT NULL DEFAULT 0 CHECK (total_achievements >= 0),
    completed_achievements INTEGER NOT NULL DEFAULT 0 CHECK (completed_achievements >= 0),
    current_streak INTEGER NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
    longest_streak INTEGER NOT NULL DEFAULT 0 CHECK (longest_streak >= 0),
    last_activity_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices para optimizar consultas
-- Índices para achievements
CREATE INDEX idx_achievements_user_id ON achievements(user_id);
CREATE INDEX idx_achievements_user_type ON achievements(user_id, type);
CREATE INDEX idx_achievements_user_completed ON achievements(user_id, is_completed) WHERE is_completed = true;
CREATE INDEX idx_achievements_user_category ON achievements(user_id, category);

-- Índices para user_gamification_stats
CREATE INDEX idx_user_gamification_stats_level ON user_gamification_stats(level);
CREATE INDEX idx_user_gamification_stats_streak ON user_gamification_stats(current_streak);

-- Habilitar Row Level Security (RLS) para ambas tablas
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_gamification_stats ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para achievements
CREATE POLICY "Users can view own achievements" ON achievements
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements" ON achievements
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own achievements" ON achievements
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own achievements" ON achievements
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas RLS para user_gamification_stats
CREATE POLICY "Users can view own gamification stats" ON user_gamification_stats
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own gamification stats" ON user_gamification_stats
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own gamification stats" ON user_gamification_stats
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Trigger para actualizar updated_at en ambas tablas
CREATE TRIGGER trigger_update_achievements_updated_at
    BEFORE UPDATE ON achievements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_user_gamification_stats_updated_at
    BEFORE UPDATE ON user_gamification_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Función para inicializar estadísticas de gamificación para nuevos usuarios
CREATE OR REPLACE FUNCTION initialize_user_gamification_stats()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_gamification_stats (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para inicializar stats cuando se crea un usuario
CREATE TRIGGER trigger_initialize_user_gamification_stats
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION initialize_user_gamification_stats();

-- Comentarios adicionales:
-- - achievements almacena todos los logros disponibles y progreso del usuario
-- - user_gamification_stats mantiene estadísticas globales del usuario
-- - RLS asegura que cada usuario solo acceda a sus propios datos
-- - Los índices optimizan consultas por usuario, tipo y estado
-- - Trigger automático inicializa stats para nuevos usuarios
-- - CHECK constraints validan valores positivos y enums válidos