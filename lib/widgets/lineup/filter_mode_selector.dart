import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../services/app_data_manager.dart';

/// Sélecteur 3 états (Tous / Mes fav. / Équipe) qui remplace les deux
/// anciens toggles indépendants.
class FilterModeSelector extends StatelessWidget {
  final FavoriteFilterMode filterMode;
  final void Function(FavoriteFilterMode) onChanged;

  const FilterModeSelector({
    super.key,
    required this.filterMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: [
        filterMode == FavoriteFilterMode.normal,
        filterMode == FavoriteFilterMode.myFavorites,
        filterMode == FavoriteFilterMode.teamFavorites,
      ],
      onPressed: (i) => onChanged(FavoriteFilterMode.values[i]),
      constraints: const BoxConstraints(minHeight: 34, minWidth: 52),
      borderRadius: BorderRadius.circular(8),
      color: Colors.white54,
      selectedColor: Colors.white,
      fillColor: AppTheme.accent,
      borderColor: Colors.white24,
      selectedBorderColor: AppTheme.accent,
      children: const [
        Text('Tous',     style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text('Mes fav.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text('Équipe',   style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
