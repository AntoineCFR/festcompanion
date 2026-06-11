import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  Future<void> _select(String choice) async {
    await AppTheme.setChoice(choice);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final choice = AppTheme.choice;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Thème'),
        backgroundColor: AppTheme.surface,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_auto, color: Colors.white),
            title: const Text(
              'Automatique',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Suit le festival sélectionné',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: choice == 'auto'
                ? Icon(Icons.check, color: AppTheme.accent)
                : null,
            onTap: () => _select('auto'),
          ),
          const Divider(color: Colors.white24),
          ...AppTheme.all.map((palette) {
            final selected = choice == palette.id;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: palette.accent,
                radius: 16,
              ),
              title: Text(
                palette.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              trailing: selected
                  ? Icon(Icons.check, color: AppTheme.accent)
                  : null,
              onTap: () => _select(palette.id),
            );
          }),
        ],
      ),
    );
  }
}
