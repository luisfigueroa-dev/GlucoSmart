# GlucoSmart

## Descripción

GlucoSmart es una aplicación móvil desarrollada en Flutter diseñada para ayudar a personas con diabetes a gestionar de manera efectiva sus niveles de glucosa, ingesta de carbohidratos y administración de medicación. La aplicación proporciona herramientas intuitivas para el seguimiento diario, sugerencias de dosis de insulina basadas en algoritmos simplificados, y visualización de tendencias a través de gráficos interactivos.

## Funcionalidades MVP

- **Registro de Glucosa**: Permite agregar mediciones de glucosa con timestamp y notas opcionales.
- **Registro de Carbohidratos**: Seguimiento de ingesta de carbohidratos con detalles de alimentos.
- **Registro de Medicación**: Administración de dosis de insulina (bolus, basal, corrección) y otros medicamentos.
- **Sugerencias de Bolo**: Cálculo automático de dosis de insulina basadas en carbohidratos, glucosa actual y factores personalizados.
- **Gráficos de Tendencias**: Visualización de niveles de glucosa a lo largo del tiempo usando gráficos interactivos.
- **Exportación de Datos**: Generación de reportes en formato PDF para compartir con profesionales de la salud.
- **Notificaciones Locales**: Recordatorios para mediciones y dosis.
- **Autenticación Segura**: Sistema de login/registro con Supabase Auth.

## Stack Técnico

- **Frontend**: Flutter (Dart) con Material Design 3
- **Backend**: Supabase (PostgreSQL, Authentication, Edge Functions)
- **Librerías Principales**:
  - `supabase_flutter`: Integración con backend
  - `provider`: Gestión de estado
  - `fl_chart`: Gráficos interactivos
  - `pdf` y `printing`: Exportación de documentos
  - `flutter_local_notifications`: Notificaciones locales
  - `flutter_logs`: Logging para debugging
- **Base de Datos**: PostgreSQL con Row Level Security (RLS)
- **Edge Functions**: Deno para cálculos de sugerencias de bolo

## Instalación

### Prerrequisitos

- Flutter SDK (^3.6.1)
- Dart SDK (^3.6.1)
- Cuenta de Supabase

### Pasos

1. Clona el repositorio:
   ```bash
   git clone https://github.com/tu-usuario/glucosmart.git
   cd glucosmart
   ```

2. Instala las dependencias:
   ```bash
   flutter pub get
   ```

3. Configura las variables de entorno:
   Crea un archivo `.env` en la raíz del proyecto con:
   ```
   SUPABASE_URL=tu_supabase_url
   SUPABASE_ANON=tu_supabase_anon_key
   ```

4. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## Uso

1. **Registro/Login**: Crea una cuenta o inicia sesión con tu email.
2. **Agregar Medición**: En la pantalla principal, agrega niveles de glucosa, carbohidratos o medicación.
3. **Ver Tendencias**: Navega a la sección de gráficos para visualizar tus datos.
4. **Sugerencias de Bolo**: Ingresa carbohidratos y glucosa actual para obtener recomendaciones.
5. **Exportar Datos**: Genera PDFs de tus registros para consultas médicas.

## Contribución

¡Las contribuciones son bienvenidas! Para contribuir:

1. Haz un fork del proyecto.
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`).
3. Realiza tus cambios y haz commit (`git commit -am 'Agrega nueva funcionalidad'`).
4. Push a la rama (`git push origin feature/nueva-funcionalidad`).
5. Abre un Pull Request.

Por favor, asegúrate de que tu código siga las guías de estilo de Flutter y pase los tests.

## Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Documentación

- [Política de Privacidad](docs/privacy_policy.md)

---

# GlucoSmart

## Description

GlucoSmart is a Flutter-developed mobile application designed to help people with diabetes effectively manage their glucose levels, carbohydrate intake, and medication administration. The app provides intuitive tools for daily tracking, insulin dose suggestions based on simplified algorithms, and trend visualization through interactive charts.

## MVP Features

- **Glucose Logging**: Allows adding glucose measurements with timestamp and optional notes.
- **Carbohydrate Logging**: Tracking of carbohydrate intake with food details.
- **Medication Logging**: Management of insulin doses (bolus, basal, correction) and other medications.
- **Bolus Suggestions**: Automatic calculation of insulin doses based on carbohydrates, current glucose, and personalized factors.
- **Trend Charts**: Visualization of glucose levels over time using interactive charts.
- **Data Export**: Generation of PDF reports for sharing with healthcare professionals.
- **Local Notifications**: Reminders for measurements and doses.
- **Secure Authentication**: Login/registration system with Supabase Auth.

## Tech Stack

- **Frontend**: Flutter (Dart) with Material Design 3
- **Backend**: Supabase (PostgreSQL, Authentication, Edge Functions)
- **Main Libraries**:
  - `supabase_flutter`: Backend integration
  - `provider`: State management
  - `fl_chart`: Interactive charts
  - `pdf` and `printing`: Document export
  - `flutter_local_notifications`: Local notifications
  - `flutter_logs`: Logging for debugging
- **Database**: PostgreSQL with Row Level Security (RLS)
- **Edge Functions**: Deno for bolus suggestion calculations

## Installation

### Prerequisites

- Flutter SDK (^3.6.1)
- Dart SDK (^3.6.1)
- Supabase account

### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/glucosmart.git
   cd glucosmart
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure environment variables:
   Create a `.env` file in the project root with:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON=your_supabase_anon_key
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## Usage

1. **Register/Login**: Create an account or log in with your email.
2. **Add Measurement**: On the main screen, add glucose levels, carbohydrates, or medication.
3. **View Trends**: Navigate to the charts section to visualize your data.
4. **Bolus Suggestions**: Enter carbohydrates and current glucose to get recommendations.
5. **Export Data**: Generate PDFs of your records for medical consultations.

## Contributing

Contributions are welcome! To contribute:

1. Fork the project.
2. Create a feature branch (`git checkout -b feature/new-feature`).
3. Make your changes and commit (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature/new-feature`).
5. Open a Pull Request.

Please ensure your code follows Flutter style guidelines and passes tests.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Documentation

- [Privacy Policy](docs/privacy_policy.md)
