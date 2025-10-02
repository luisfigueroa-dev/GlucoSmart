-- Migración para crear la tabla notifications en GlucoSmart
-- Esta migración crea la tabla notifications con sus índices, políticas RLS y trigger para updated_at
-- Compatible con Supabase Postgres

-- Crear la tabla notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL, -- Título de la notificación
    body TEXT, -- Cuerpo o mensaje de la notificación
    scheduled_time TIMESTAMPTZ NOT NULL, -- Fecha y hora programada para la notificación
    type TEXT NOT NULL, -- Tipo de notificación (ej. reminder, alert, warning)
    is_active BOOLEAN NOT NULL DEFAULT TRUE, -- Indica si la notificación está activa
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices para optimizar consultas
-- Índice compuesto en user_id y scheduled_time para consultas ordenadas por usuario y tiempo programado
CREATE INDEX idx_notifications_user_scheduled ON notifications(user_id, scheduled_time DESC);

-- Índice adicional en user_id para consultas por usuario
CREATE INDEX idx_notifications_user_id ON notifications(user_id);

-- Habilitar Row Level Security (RLS) para acceso seguro
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Política RLS: Los usuarios solo pueden ver sus propias notificaciones
CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden insertar sus propias notificaciones
CREATE POLICY "Users can insert own notifications" ON notifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden actualizar sus propias notificaciones
CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Política RLS: Los usuarios solo pueden eliminar sus propias notificaciones
CREATE POLICY "Users can delete own notifications" ON notifications
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at en cada modificación
-- Reutiliza la función existente update_updated_at_column creada en la migración inicial
CREATE TRIGGER trigger_update_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios adicionales:
-- - La tabla usa UUID para id y user_id para integrarse con el sistema de autenticación de Supabase
-- - scheduled_time permite programar notificaciones futuras, útil para recordatorios de medicación o controles de glucosa
-- - is_active permite desactivar notificaciones sin eliminarlas, manteniendo historial
-- - Las políticas RLS garantizan que cada usuario solo acceda a sus propias notificaciones
-- - El trigger mantiene updated_at actualizado automáticamente para auditoría
-- - El índice compuesto optimiza consultas por usuario ordenadas por scheduled_time descendente para notificaciones próximas