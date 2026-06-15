import 'package:flutter/material.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    // L'édition se fait désormais au niveau du champ « Numéro de téléphone »
    // (bouton Éditer → Valider), seule donnée modifiable de la fiche : plus
    // besoin d'un bouton de sauvegarde global.
    return AppBar(
      title: const Text('Mon compte'),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}