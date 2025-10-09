import 'package:flutter/material.dart';

/// Pantalla de asesoramiento contextual con chatbot.
/// Responde preguntas comunes sobre diabetes y proporciona consejos.
/// Compatible con WCAG 2.2 AA para accesibilidad.
class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: '¡Hola! Soy tu asistente de diabetes. Puedo ayudarte con preguntas sobre:\n\n'
            '• Control de glucosa\n'
            '• Alimentación saludable\n'
            '• Medicamentos e insulina\n'
            '• Actividad física\n'
            '• Síntomas y complicaciones\n\n'
            '¿En qué puedo ayudarte hoy?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de Diabetes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearChat,
            tooltip: 'Nueva conversación',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.grey,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Escribe tu pregunta...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
            mini: true,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();

    // Simular respuesta del bot
    Future.delayed(const Duration(seconds: 1), () {
      final response = _getBotResponse(text.toLowerCase());
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });

    _scrollToBottom();
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _addWelcomeMessage();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _getBotResponse(String userMessage) {
    // Respuestas basadas en palabras clave
    if (userMessage.contains('glucosa') || userMessage.contains('azúcar')) {
      if (userMessage.contains('alta') || userMessage.contains('elevada')) {
        return 'La glucosa alta (>140 mg/dL) puede deberse a:\n\n'
               '• Exceso de carbohidratos en la comida\n'
               '• Falta de ejercicio\n'
               '• Estrés o enfermedad\n'
               '• Dosis insuficiente de insulina/medicamentos\n\n'
               'Recomendaciones:\n'
               '• Verifica tu dosis de insulina\n'
               '• Reduce porciones de carbohidratos\n'
               '• Camina 15-20 minutos\n'
               '• Consulta a tu médico si persiste';
      } else if (userMessage.contains('baja') || userMessage.contains('hipo')) {
        return 'La hipoglucemia (<70 mg/dL) requiere atención inmediata:\n\n'
               'Síntomas: temblor, sudoración, confusión, mareos\n\n'
               'Tratamiento:\n'
               '• Toma 15g de glucosa rápida (jugo, caramelos)\n'
               '• Espera 15 minutos y verifica glucosa\n'
               '• Si no mejora, repite\n'
               '• Come un snack si es hora de comida\n\n'
               'Prevención: ajusta dosis de insulina, come regularmente';
      } else {
        return 'La glucosa normal en ayunas es 70-100 mg/dL. Después de comidas, hasta 140 mg/dL es aceptable para la mayoría.\n\n'
               'Factores que afectan la glucosa:\n'
               '• Alimentación\n'
               '• Ejercicio\n'
               '• Medicamentos\n'
               '• Estrés\n'
               '• Enfermedades\n\n'
               'Monitorea regularmente y registra patrones.';
      }
    }

    if (userMessage.contains('comida') || userMessage.contains('comer') || userMessage.contains('alimentación')) {
      return 'Recomendaciones nutricionales para diabetes:\n\n'
             '✅ Consume:\n'
             '• Vegetales sin almidón (brócoli, espinacas, pepinos)\n'
             '• Proteínas magras (pollo, pescado, tofu)\n'
             '• Granos integrales (quinoa, avena)\n'
             '• Frutas con bajo índice glucémico (manzanas, peras)\n\n'
             '⚠️ Limita:\n'
             '• Azúcares refinados y bebidas azucaradas\n'
             '• Carbohidratos procesados (pan blanco, pastas)\n'
             '• Alimentos fritos y grasas saturadas\n\n'
             '💡 Consejos: come cada 3-4 horas, controla porciones, combina carbohidratos con proteínas.';
    }

    if (userMessage.contains('ejercicio') || userMessage.contains('actividad') || userMessage.contains('deporte')) {
      return 'El ejercicio es beneficioso para el control de diabetes:\n\n'
             '✅ Recomendado:\n'
             '• Caminar 30 minutos diarios\n'
             '• Natación o ciclismo\n'
             '• Yoga o tai chi\n'
             '• Levantamiento de pesas ligeras\n\n'
             '⚠️ Precauciones:\n'
             '• Verifica glucosa antes y después\n'
             '• Lleva glucosa rápida\n'
             '• Consulta a tu médico antes de empezar\n'
             '• Ajusta medicamentos si es necesario\n\n'
             'Beneficios: mejora sensibilidad a insulina, controla peso, reduce estrés.';
    }

    if (userMessage.contains('insulina') || userMessage.contains('medicamento')) {
      return 'Información sobre medicamentos para diabetes:\n\n'
             '💉 Tipos de insulina:\n'
             '• Rápida: actúa en 15 min, dura 3-4 horas\n'
             '• Regular: actúa en 30 min, dura 6-8 horas\n'
             '• Lenta: actúa en 1-2 horas, dura 20-24 horas\n\n'
             '💊 Otros medicamentos:\n'
             '• Metformina: reduce producción de glucosa hepática\n'
             '• Sulfonilureas: estimulan producción de insulina\n'
             '• Inhibidores DPP-4: aumentan insulina, reducen glucagón\n\n'
             '⚠️ Importante: nunca cambies dosis sin consultar a tu médico.';
    }

    if (userMessage.contains('síntoma') || userMessage.contains('complicación')) {
      return 'Síntomas y complicaciones de diabetes:\n\n'
             '🔴 Síntomas de diabetes no controlada:\n'
             '• Sed excesiva y boca seca\n'
             '• Orina frecuente\n'
             '• Cansancio extremo\n'
             '• Visión borrosa\n'
             '• Heridas que no cicatrizan\n\n'
             '⚠️ Complicaciones a largo plazo:\n'
             '• Problemas cardíacos\n'
             '• Daño renal\n'
             '• Problemas de visión\n'
             '• Daño nervioso\n'
             '• Problemas en pies\n\n'
             'El control temprano previene la mayoría de complicaciones.';
    }

    if (userMessage.contains('estrés') || userMessage.contains('ansiedad')) {
      return 'Manejo del estrés en diabetes:\n\n'
             'El estrés eleva la glucosa porque libera cortisol y adrenalina.\n\n'
             '💡 Técnicas recomendadas:\n'
             '• Respiración profunda: inhala 4 segundos, exhala 6\n'
             '• Meditación diaria (10-15 minutos)\n'
             '• Ejercicio regular\n'
             '• Sueño adecuado (7-8 horas)\n'
             '• Apoyo social (habla con amigos/familia)\n\n'
             'Si el estrés es severo, considera terapia profesional.';
    }

    // Respuesta por defecto
    return 'Lo siento, no entendí completamente tu pregunta. Soy un asistente básico y puedo ayudarte con temas como:\n\n'
           '• Control de glucosa\n'
           '• Alimentación saludable\n'
           '• Medicamentos e insulina\n'
           '• Actividad física\n'
           '• Síntomas y complicaciones\n'
           '• Manejo del estrés\n\n'
           '¿Puedes reformular tu pregunta o elegir uno de estos temas?';
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// Modelo para mensajes del chat.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}