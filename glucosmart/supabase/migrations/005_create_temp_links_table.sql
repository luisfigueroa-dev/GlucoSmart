-- Migración para crear la tabla temp_links para enlaces cortos temporales
-- Esta migración crea la tabla temp_links con columnas para id, data y expires_at
-- Compatible con Supabase Postgres

-- Crear la tabla temp_links
CREATE TABLE temp_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    data JSONB NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índice en expires_at para optimizar consultas de expiración
CREATE INDEX idx_temp_links_expires_at ON temp_links(expires_at);

-- Deshabilitar Row Level Security para permitir acceso público a los enlaces
-- (Los enlaces son temporales y públicos para compartir datos)
ALTER TABLE temp_links DISABLE ROW LEVEL SECURITY;

-- Comentarios adicionales:
-- - La tabla almacena enlaces temporales con datos JSON y fecha de expiración
-- - No se requiere autenticación para acceder a los enlaces
-- - Se recomienda implementar un job para limpiar enlaces expirados periódicamente