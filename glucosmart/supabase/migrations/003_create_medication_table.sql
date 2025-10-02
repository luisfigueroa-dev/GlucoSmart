-- Migración para crear la tabla medication en GlucoSmart
-- Esta migración crea la tabla medication con sus índices, políticas RLS y trigger para updated_at
-- Compatible con Supabase Postgres

-- Crear la tabla medication
CREATE TABLE medication (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL, -- Nombre del medicamento
    dose NUMERIC(6,2) NOT NULL CHECK (dose > 0), -- Dosis del medicamento, debe ser positiva
    unit TEXT NOT NULL, -- Unidad de la dosis (ej. mg, ml, unidades)
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Timestamp del registro
    type TEXT NOT NULL, -- Tipo de medicamento (ej. insulin, pill, injection)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices para optimizar consultas
-- Índice compuesto en user_id y timestamp para consultas ordenadas por usuario y tiempo
CREATE INDEX idx_medication_user_timestamp ON medication(user_id, timestamp DESC);

-- Índice adicional en user_id para consultas por usuario
CREATE INDEX idx_medication_user_id ON medication(user_id);

-- Habilitar Row Level Security (RLS) para acceso seguro
ALTER TABLE medication ENABLE ROW LEVEL SECURITY;

-- Política RLS: Los usuarios solo pueden ver sus propios registros de medicamentos
CREATE POLICY "Users can view own medication records" ON medication
    FOR SELECT USING (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden insertar sus propios registros de medicamentos
CREATE POLICY "Users can insert own medication records" ON medication
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden actualizar sus propios registros de medicamentos
CREATE POLICY "Users can update own medication records" ON medication
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden eliminar sus propios registros de medicamentos
CREATE POLICY "Users can delete own medication records" ON medication
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at en cada modificación
-- Reutiliza la función existente update_updated_at_column creada en la migración inicial
CREATE TRIGGER trigger_update_medication_updated_at
    BEFORE UPDATE ON medication
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios adicionales:
-- - La tabla usa UUID para id y user_id para integrarse con el sistema de autenticación de Supabase
-- - El CHECK en dose asegura valores positivos para la dosis del medicamento
-- - Las políticas RLS garantizan que cada usuario solo acceda a sus propios datos de medicamentos
-- - El trigger mantiene updated_at actualizado automáticamente para auditoría
-- - El índice compuesto optimiza consultas por usuario ordenadas por timestamp descendente