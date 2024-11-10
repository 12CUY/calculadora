import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:expressions/expressions.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _expression = "";
  String _displayText = "0";
  String _result = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) => setState(() {
        String voiceInput = val.recognizedWords;
        _expression = _parseVoiceInput(voiceInput);
      }));
    } else {
      Fluttertoast.showToast(msg: "No se pudo iniciar el reconocimiento de voz");
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  String _parseVoiceInput(String input) {
    return input
        .replaceAll('por', '*')
        .replaceAll('dividido', '/')
        .replaceAll('más', '+')
        .replaceAll('menos', '-')
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^\d\+\-\*/\.]'), '');
  }

  void _evaluateExpression() {
    try {
      Expression exp = Expression.parse(_expression);
      final evaluator = const ExpressionEvaluator();
      double result = evaluator.eval(exp, {}) as double;
      setState(() {
        _result = result.toString();
      });
      _showResultDialog(result.toString());
    } catch (e) {
      setState(() {
        _result = "Error";
      });
      Fluttertoast.showToast(msg: "Error en la expresión");
    }
  }

  void _showResultDialog(String result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Resultado'),
          content: Text('El resultado es: $result'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "CE") {
        _expression = "";
        _displayText = "0";
        _result = "";
      } else if (buttonText == "=") {
        _evaluateExpression();
      } else {
        if (_expression == "0") {
          _expression = buttonText;
        } else {
          _expression += buttonText;
        }
        _displayText = _expression;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calculadora con Voz'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/anime.jpg'), // Asegúrate de que la ruta sea correcta
            fit: BoxFit.cover, // Hace que la imagen cubra toda la pantalla
          ),
        ),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Modo de Entrada por Voz'),
              value: _isListening,
              onChanged: (val) {
                if (val) {
                  _startListening();
                } else {
                  _stopListening();
                }
              },
            ),
            Container(
              padding: EdgeInsets.all(20),
              color: const Color.fromARGB(255, 246, 246, 246).withOpacity(0.6), // Fondo oscuro para el texto
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _expression.isNotEmpty ? _expression : _displayText,
                  style: TextStyle(color: Colors.blue, fontSize: 36),
                ),
              ),
            ),
            if (_result.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Resultado: $_result",
                  style: TextStyle(fontSize: 24, color: const Color(0xFF3E0000)),
                ),
              ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 10, // Espaciado horizontal
                mainAxisSpacing: 10,  // Espaciado vertical
                padding: EdgeInsets.all(10), // Espaciado externo de la cuadrícula
                children: [
                  ...['7', '8', '9', '/',
                      '4', '5', '6', '*',
                      '1', '2', '3', '-',
                      '0', 'CE', '=', '+']
                      .map((btnText) {
                    return ElevatedButton(
                      onPressed: () => _buttonPressed(btnText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(btnText), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Bordes no tan circulares
                        ),
                        elevation: 5, // Sombra
                      ),
                      child: Text(
                        btnText,
                        style: TextStyle(fontSize: 25, color: Colors.white),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Color _getButtonColor(String buttonText) {
  if (buttonText == "CE") {
    return Colors.red; // Color rojo para el botón "CE"
  } else if (['+', '-', '*', '/', '='].contains(buttonText)) {
    return Colors.deepOrange; // Color para los botones de operación
  }
  return Colors.blue; // Color por defecto para los demás botones
}

}
