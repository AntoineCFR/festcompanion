import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../models/dj_tag.dart';
import '../../models/user_model.dart';
import '../../services/app_data_manager.dart';
import '../../pages/search_page.dart';
import '../team/user_avatar.dart';

/// Section « Tags » de la fiche DJ. Tout utilisateur peut ajouter un tag
/// (texte sans espace, préfixé de « # »). Chaque tag = une puce avec la photo
/// de son auteur. Cliquer sur SON tag → confirmation de suppression ; cliquer
/// sur celui d'un autre → page « DJ par tag » filtrée sur ce tag.
class TagsSection extends StatefulWidget {
  final int userId;
  final int setId;
  final VoidCallback? onChanged;

  const TagsSection({
    super.key,
    required this.userId,
    required this.setId,
    this.onChanged,
  });

  @override
  State<TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends State<TagsSection> {
  User _userFor(int id) => AppDataManager().users.firstWhere(
        (u) => u.id == id,
        orElse: () => User(id: id, username: '?'),
      );

  Future<void> _openAddDialog() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final preview = DjTag.normalize(controller.text);
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text('Ajouter un tag',
                  style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setLocal(() {}),
                    onSubmitted: (_) => Navigator.pop(ctx, controller.text),
                    decoration: const InputDecoration(
                      hintText: 'ex : techno',
                      hintStyle: TextStyle(color: Colors.white38),
                      prefixText: '# ',
                      prefixStyle: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    preview.isEmpty ? 'Aperçu : —' : 'Aperçu : #$preview',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: preview.isEmpty
                      ? null
                      : () => Navigator.pop(ctx, controller.text),
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );

    if (raw != null && DjTag.normalize(raw).isNotEmpty) {
      // addDjTag insère le tag localement AVANT son premier await → on affiche
      // tout de suite (optimiste), puis on attend la synchro serveur (et un
      // éventuel rollback) avant de reconcilier l'UI.
      final future = AppDataManager().addDjTag(widget.setId, raw);
      if (mounted) setState(() {});
      await future;
      if (mounted) setState(() {});
      widget.onChanged?.call();
    }
  }

  Future<void> _confirmDelete(String tag) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Supprimer le tag',
            style: TextStyle(color: Colors.white)),
        content: Text('Supprimer votre tag #$tag ?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (ok == true) {
      // Suppression optimiste : removeDjTag retire le tag localement avant son
      // premier await → on rafraîchit aussitôt, puis on synchronise.
      final future = AppDataManager().removeDjTag(widget.setId, tag);
      if (mounted) setState(() {});
      await future;
      if (mounted) setState(() {});
      widget.onChanged?.call();
    }
  }

  void _onTapTag(DjTag tag) {
    if (tag.userId == widget.userId) {
      _confirmDelete(tag.tag);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchPage(initialTag: tag.tag),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = AppDataManager().tagsForSet(widget.setId)
      ..sort((a, b) => a.tag.compareTo(b.tag));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _openAddDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un tag'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (tags.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Aucun tag pour l\'instant.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((t) {
              return _TagChip(
                user: _userFor(t.userId),
                tag: t.tag,
                isMine: t.userId == widget.userId,
                onTap: () => _onTapTag(t),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ── Puce d'un tag : avatar de l'auteur + #tag (croix si c'est le mien) ───────
class _TagChip extends StatelessWidget {
  final User user;
  final String tag;
  final bool isMine;
  final VoidCallback onTap;

  const _TagChip({
    required this.user,
    required this.tag,
    required this.isMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: isMine ? Border.all(color: AppTheme.accent, width: 1.2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(user: user, radius: 10),
            const SizedBox(width: 6),
            Text('#$tag',
                style: const TextStyle(fontSize: 13, color: Colors.white)),
            if (isMine) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close, size: 13, color: Colors.white54),
            ],
          ],
        ),
      ),
    );
  }
}
