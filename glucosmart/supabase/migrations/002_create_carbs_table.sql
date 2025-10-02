-- Migración para crear la tabla carbs en GlucoSmart
-- Esta migración crea la tabla carbs con sus índices, políticas RLS y trigger para updated_at
-- Compatible con Supabase Postgres

-- Crear la tabla carbs
CREATE TABLE carbs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    grams NUMERIC(6,2) NOT NULL CHECK (grams >= 0 AND grams <= 1000), -- Gramos de carbohidratos, rango razonable 0-1000g
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    food TEXT NOT NULL, -- Descripción del alimento
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices para optimizar consultas
-- Índice compuesto en user_id y timestamp para consultas ordenadas por usuario y tiempo
CREATE INDEX idx_carbs_user_timestamp ON carbs(user_id, timestamp DESC);

-- Índice adicional en user_id para consultas por usuario
CREATE INDEX idx_carbs_user_id ON carbs(user_id);

-- Habilitar Row Level Security (RLS) para acceso seguro
ALTER TABLE carbs ENABLE ROW LEVEL SECURITY;

-- Política RLS: Los usuarios solo pueden ver sus propios registros de carbohidratos
CREATE POLICY "Users can view own carbs records" ON carbs
    FOR SELECT USING (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden insertar sus propios registros de carbohidratos
CREATE POLICY "Users can insert own carbs records" ON carbs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden actualizar sus propios registros de carbohidratos
CREATE POLICY "Users can update own carbs records" ON carbs
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden eliminar sus propios registros de carbohidratos
CREATE POLICY "Users can delete own carbs records" ON carbs
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at en cada modificación
-- Reutiliza la función existente update_updated_at_column creada en la migración inicial
CREATE TRIGGER trigger_update_carbs_updated_at
    BEFORE UPDATE ON carbs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios adicionales:
-- - La tabla usa UUID para id y user_id para integrarse con el sistema de autenticación de Supabase
-- - El CHECK en grams asegura valores positivos y razonables de carbohidratos
-- - Las políticas RLS garantizan que cada usuario solo acceda a sus propios datos de carbohidratos
-- - El trigger mantiene updated_at actualizado automáticamente para auditoría
-- - El índice compuesto optimiza consultas por usuario ordenadas por timestamp descendente