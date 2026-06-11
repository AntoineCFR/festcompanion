import 'package:flutter/material.dart';

/// Bouton SOS « appui maintenu » avec un anneau de progression qui se remplit
/// pendant la durée d'appui. Donne un retour visuel clair : l'utilisateur voit
/// que son action déclenche quelque chose. Le SOS n'est envoyé qu'à 100 %.
class SosHoldButton extends StatefulWidget {
  final Duration holdDuration;
  final VoidCallback onCompleted;
  final VoidCallback onCancel;

  const SosHoldButton({
    super.key,
    this.holdDuration = const Duration(seconds: 5),
    required this.onCompleted,
    required this.onCancel,
  });

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_fired) {
          _fired = true;
          widget.onCompleted();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_fired) return;
    _controller.forward(from: 0);
  }

  void _cancelHold() {
    if (_fired) return;
    _controller.stop();
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Maintenez pour SOS',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        const SizedBox(height: 24),
        Listener(
          onPointerDown: (_) => _startHold(),
          onPointerUp: (_) => _cancelHold(),
          onPointerCancel: (_) => _cancelHold(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final percent = (_controller.value * 100).round();
              return SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Anneau de progression
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: _controller.value,
                        strokeWidth: 10,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    // Cercle rouge central
                    Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(255, 0, 0, 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber, size: 54, color: Colors.white),
                          if (_controller.value > 0)
                            Text(
                              '$percent%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text('Maintenez 5 secondes', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: widget.onCancel,
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
