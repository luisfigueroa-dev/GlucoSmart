// @ts-ignore
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Configuración del cliente Supabase
// @ts-ignore
const supabaseUrl = Deno.env.get('SUPABASE_URL')!
// @ts-ignore
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!
const supabase = createClient(supabaseUrl, supabaseKey)

// Función principal del Edge Function
// @ts-ignore
Deno.serve(async (req: Request) => {
  // Headers CORS completos
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  // Manejar solicitudes OPTIONS para preflight CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  // Solo permitir solicitudes POST
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Método no permitido' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    })
  }

  try {
    // Obtener el cuerpo de la solicitud
    const body = await req.json()

    // Validación de entrada: verificar que se proporcione 'data' y que sea un objeto
    if (!body.data || typeof body.data !== 'object') {
      return new Response(JSON.stringify({ error: 'Datos inválidos: se requiere un objeto "data"' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      })
    }

    // Generar un UUID único para el enlace
    const linkId = crypto.randomUUID()

    // Calcular la fecha de expiración: 24 horas desde ahora
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

    // Almacenar en la tabla temporal 'temp_links'
    // Se asume que la tabla tiene columnas: id (uuid), data (jsonb), expires_at (timestamptz)
    const { error } = await supabase
      .from('temp_links')
      .insert({
        id: linkId,
        data: body.data,
        expires_at: expiresAt,
      })

    // Manejo de errores en la inserción
    if (error) {
      console.error('Error al insertar en temp_links:', error)
      return new Response(JSON.stringify({ error: 'Error interno del servidor' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      })
    }

    // Retornar el enlace corto generado
    const shortLink = `${supabaseUrl}/share/${linkId}`
    return new Response(JSON.stringify({ shortLink }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    })

  } catch (err) {
    // Manejo de errores generales
    console.error('Error en la función:', err)
    return new Response(JSON.stringify({ error: 'Error interno del servidor' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    })
  }
})