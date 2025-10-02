// @ts-ignore
console.log("Edge Function 'bolo_suggest' loaded");

// Función para calcular la sugerencia de bolo basada en carbohidratos, glucosa actual y fórmula openAPS simplificada
// @ts-ignore
Deno.serve(async (req: Request) => {
  // Manejar preflight CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    // Validar que la solicitud sea POST
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Método no permitido. Use POST." }), {
        status: 405,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    // Parsear el cuerpo de la solicitud
    const body = await req.json();
    const { carbs, current_glucose, carb_ratio = 10, sensitivity_factor = 50, target_glucose = 100 } = body;

    // Validación de entrada
    if (typeof carbs !== "number" || carbs <= 0) {
      return new Response(JSON.stringify({ error: "Los carbohidratos deben ser un número positivo." }), {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    if (typeof current_glucose !== "number" || current_glucose <= 0) {
      return new Response(JSON.stringify({ error: "La glucosa actual debe ser un número positivo." }), {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    if (typeof carb_ratio !== "number" || carb_ratio <= 0) {
      return new Response(JSON.stringify({ error: "El ratio de carbohidratos debe ser un número positivo." }), {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    if (typeof sensitivity_factor !== "number" || sensitivity_factor <= 0) {
      return new Response(JSON.stringify({ error: "El factor de sensibilidad debe ser un número positivo." }), {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    if (typeof target_glucose !== "number" || target_glucose <= 0) {
      return new Response(JSON.stringify({ error: "La glucosa objetivo debe ser un número positivo." }), {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    // Cálculo de la sugerencia de bolo usando fórmula openAPS simplificada
    // 1. Unidades para carbohidratos: dividir carbohidratos por el ratio carbohidratos/insulina
    const carb_units = carbs / carb_ratio;

    // 2. Unidades para corrección: calcular la diferencia entre glucosa actual y objetivo, dividir por factor de sensibilidad
    // Si la glucosa actual es mayor que el objetivo, agregar unidades de corrección; si es menor, restar (pero no negativo)
    const glucose_diff = current_glucose - target_glucose;
    const correction_units = glucose_diff > 0 ? glucose_diff / sensitivity_factor : 0;

    // 3. Total de unidades de bolo: sumar unidades de carbohidratos y corrección
    // Nota: En openAPS, la lógica es más compleja con predicciones, pero aquí se simplifica a una aproximación básica
    const total_bolus = carb_units + correction_units;

    // Redondear a 2 decimales para precisión razonable
    const suggested_bolus = Math.round(total_bolus * 100) / 100;

    // Respuesta exitosa
    return new Response(JSON.stringify({
      suggested_bolus,
      details: {
        carb_units: Math.round(carb_units * 100) / 100,
        correction_units: Math.round(correction_units * 100) / 100,
        parameters: { carb_ratio, sensitivity_factor, target_glucose }
      }
    }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });

  } catch (error) {
    // Manejo de errores generales
    console.error("Error en bolo_suggest:", error);
    return new Response(JSON.stringify({ error: "Error interno del servidor." }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});