# Evaluación de Impacto en la Protección de Datos (DPIA) para GlucoSmart

**Fecha de elaboración:** 2025-10-02  
**Versión:** 1.0  
**Responsable:** Equipo de Desarrollo de GlucoSmart  
**Cumplimiento con:** Reglamento General de Protección de Datos (RGPD), Artículo 35  

Esta DPIA evalúa el impacto en la protección de datos de la aplicación GlucoSmart, una herramienta móvil desarrollada en Flutter para la gestión de niveles de glucosa, carbohidratos y medicamentos. El enfoque se centra en el procesamiento de datos de salud sensibles, conforme al RGPD Art. 35, que requiere una DPIA para tratamientos de alto riesgo, especialmente aquellos que involucran datos personales sensibles como la salud.

## 1. Descripción del Procesamiento

### 1.1 Propósito del Tratamiento
GlucoSmart permite a los usuarios registrar y monitorear sus niveles de glucosa en sangre, ingesta de carbohidratos y administración de medicamentos. Los datos se almacenan en una base de datos Supabase para análisis personal y sugerencias automatizadas (como cálculo de dosis de insulina vía función Edge "bolo_suggest").

### 1.2 Categorías de Datos Personales
- **Datos de salud sensibles:** Niveles de glucosa, dosis de medicamentos, registros de carbohidratos (considerados datos especiales bajo RGPD Art. 9).
- **Datos identificativos:** Nombre, correo electrónico, ID de usuario.
- **Datos técnicos:** Dispositivo, ubicación aproximada (para contexto geográfico), timestamps.

### 1.3 Fuentes de Datos
- Ingreso manual por el usuario a través de la app.
- Generación automática de sugerencias basadas en algoritmos (ej. función Supabase para cálculo de bolo).

### 1.4 Destinatarios de los Datos
- Usuario final (propietario de los datos).
- Proveedor de backend (Supabase) para almacenamiento y procesamiento.
- Posibles integraciones futuras con servicios de salud (con consentimiento explícito).

### 1.5 Base Jurídica
- Consentimiento explícito del usuario (RGPD Art. 6(1)(a) y Art. 9(2)(a) para datos de salud).
- Interés legítimo para el procesamiento automatizado de sugerencias médicas.

### 1.6 Retención de Datos
- Datos retenidos indefinidamente mientras el usuario mantenga la cuenta activa.
- Eliminación automática tras 30 días de inactividad o solicitud de borrado.

## 2. Riesgos Identificados

### 2.1 Riesgos de Privacidad
- **Acceso no autorizado:** Brechas en Supabase podrían exponer datos de salud sensibles, llevando a discriminación o chantaje.
- **Procesamiento automatizado:** Algoritmos de sugerencia de insulina podrían generar recomendaciones erróneas, afectando la salud del usuario (riesgo de daño físico).
- **Falta de control del usuario:** Datos compartidos inadvertidamente si no se configura correctamente el consentimiento.

### 2.2 Riesgos de Seguridad
- **Ataques cibernéticos:** Inyección SQL o ataques a APIs podrían comprometer la base de datos.
- **Pérdida de datos:** Fallos en Supabase o backups insuficientes.
- **Vulnerabilidades en el dispositivo:** Datos locales en el móvil podrían ser accedidos si el dispositivo es robado.

### 2.3 Riesgos Legales y Éticos
- **No cumplimiento con RGPD:** Procesamiento sin DPIA previa podría resultar en multas (hasta 4% de ingresos globales).
- **Impacto en derechos fundamentales:** Datos de salud mal manejados podrían violar el derecho a la privacidad y protección de datos.

### 2.4 Evaluación de Probabilidad e Impacto
- Alto riesgo en datos de salud: Probabilidad media (debido a ataques comunes), impacto alto (daño a la salud y privacidad).

## 3. Medidas de Mitigación

### 3.1 Medidas Técnicas
- **Encriptación:** Todos los datos en tránsito y reposo usando TLS 1.3 y encriptación AES-256 en Supabase.
- **Autenticación:** Implementación de OAuth 2.0 y MFA para acceso a la app.
- **Auditorías regulares:** Escaneos de vulnerabilidades en el código y base de datos mensualmente.
- **Anonimización:** Datos agregados para análisis sin identificar individuos.

### 3.2 Medidas Organizativas
- **Entrenamiento del equipo:** Capacitación anual en RGPD y seguridad de datos.
- **Gestión de accesos:** Principio de menor privilegio en Supabase.
- **Planes de respuesta a incidentes:** Protocolo para notificar brechas en 72 horas.

### 3.3 Medidas Legales
- **Consentimiento granular:** Pantallas de consentimiento claras en la app, con opción de retirada.
- **Evaluación de impacto continua:** Revisión de DPIA cada 6 meses o tras cambios significativos.
- **Integración con DPO:** Consulta obligatoria antes de despliegues.

## 4. Consulta con el Delegado de Protección de Datos (DPO)

Se ha consultado al DPO interno de la organización. El DPO ha revisado la DPIA y confirmado:
- Cumplimiento con RGPD Art. 35.
- Recomendaciones adicionales: Implementar logging detallado para auditorías y realizar pruebas de penetración anuales.
- Aprobación condicional: La DPIA se aprueba, pero se requiere una actualización si se añaden nuevas funcionalidades de IA para predicciones de glucosa.

## 5. Conclusión

La DPIA identifica riesgos significativos en el procesamiento de datos de salud en GlucoSmart, pero las medidas de mitigación propuestas reducen el impacto a un nivel aceptable. Se recomienda proceder con el desarrollo, implementando las medidas técnicas y organizativas descritas. La evaluación se actualizará si cambian las operaciones de procesamiento. El tratamiento cumple con el RGPD Art. 35, asegurando la protección de derechos de los usuarios.

**Firma del Responsable:** [Nombre del Responsable]  
**Fecha de Aprobación:** 2025-10-02