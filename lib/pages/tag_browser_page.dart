import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../models/dj_model.dart';
import '../services/app_data_manager.dart';
import '../widgets/lineup/dj_list_tile.dart';
import '../widgets/shared/festival_background.dart';
import 'djprofilepage.dart';

/// Page plein écran « DJ par tag » (utilisée en navigation depuis une fiche DJ).
class TagBrowserPage extends StatelessWidget {
  final String? initialTag;

  const TagBrowserPage({super.key, this.initialTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('DJ par tag')),
      body: TagBrowserView(initialTag: initialTag),
    );
  }
}

/// Contenu « DJ par tag » (sans Scaffold) → réutilisable comme onglet du bottom-nav.
/// Sélectionner un tag parmi tous ceux existants (festival courant) et voir les
/// DJ qui y répondent.
class TagBrowserView extends StatefulWidget {
  final String? initialTag;

  const TagBrowserView({super.key, this.initialTag});

  @override
  State<TagBrowserView> createState() => _TagBrowserViewState();
}

class _TagBrowserViewState extends State<TagBrowserView> {
  /// Nombre de puces affichées par défaut avant « +N autres » (qui déplie le
  /// reste en place).
  static const int _maxVisibleChips = 10;

  String? _selectedTag;
  // Barre de tags dépliée (montre tous les tags) ou non.
  bool _tagsExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.initialTag;
  }

  /// Tags triés par popularité (nb de DJ concernés) décroissante, puis alpha.
  List<String> _orderedTags() {
    final tags = AppDataManager().allTagLabels;
    final counts = {
      for (final t in tags) t: AppDataManager().setIdsForTag(t).length
    };
    return [...tags]..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
  }

  Future<void> _onDjTileTap(TimetableItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DJProfilePage(
          userId: AppDataManager().userId!,
          setId: item.setId,
          dj: DJ(
            name: item.dj,
            bio: item.bio ?? '',
            stage: item.stage,
            startTime: item.startTime,
            endTime: item.endTime,
            spotifyLink: item.spotifyLink,
            soundcloudLink: item.soundcloudLink,
            instagramLink: item.instagramLink,
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allTags = AppDataManager().allTagLabels;
    final timetable = AppDataManager().timetable;

    // Tags DISTINCTS par set (pour la ligne de tags des tuiles ET le tri défaut).
    final tagsBySet = <int, Set<String>>{};
    for (final dt in AppDataManager().djTags) {
      tagsBySet.putIfAbsent(dt.setId, () => <String>{}).add(dt.tag);
    }

    // Tri commun aux deux modes : popularité PONDÉRÉE des tags du DJ = somme,
    // pour chaque tag du DJ, du nombre de DJ portant ce tag (puis nom). On garde
    // donc le MÊME ordre qu'on filtre ou non (cliquer un tag ne réordonne plus).
    final tagPopularity = {
      for (final t in allTags) t: AppDataManager().setIdsForTag(t).length
    };
    int weight(int setId) => (tagsBySet[setId] ?? const <String>{})
        .fold(0, (s, t) => s + (tagPopularity[t] ?? 0));
    int byWeightThenName(TimetableItem a, TimetableItem b) {
      final byPop = weight(b.setId).compareTo(weight(a.setId));
      return byPop != 0
          ? byPop
          : a.dj.toLowerCase().compareTo(b.dj.toLowerCase());
    }

    final List<TimetableItem> matches;
    if (_selectedTag != null) {
      // Tag sélectionné : les DJ qui le portent (même tri).
      final setIds = AppDataManager().setIdsForTag(_selectedTag!);
      matches = timetable.where((t) => setIds.contains(t.setId)).toList()
        ..sort(byWeightThenName);
    } else {
      // Par défaut : tous les DJ tagués (même tri).
      matches = timetable.where((t) => tagsBySet.containsKey(t.setId)).toList()
        ..sort(byWeightThenName);
    }

    if (allTags.isEmpty) {
      // Aucun tag : soit ils chargent encore en arrière-plan (loader), soit
      // il n'en existe réellement aucun (état vide).
      return FestivalBackground(
        imageKey: 'featured',
        child: AppDataManager().isLoadingDjTags
            ? const Center(child: CircularProgressIndicator())
            : const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucun tag n\'a encore été créé.\n'
                    'Ajoutez-en depuis une fiche DJ.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
      );
    }
    return FestivalBackground(
      imageKey: 'featured',
      refreshDomains: const [LoadDomain.tags],
      refreshLabel: 'Mise à jour des tags…',
      child: Column(
        children: [
          _buildTagSelector(),
          const Divider(height: 1),
          Expanded(child: _buildResults(matches, tagsBySet)),
        ],
      ),
    );
  }

  Widget _buildTagSelector() {
    final ordered = _orderedTags();

    // Liste repliée = les plus populaires, en garantissant que le tag
    // sélectionné y figure toujours (même s'il est peu utilisé).
    final collapsed = ordered.take(_maxVisibleChips).toList();
    if (_selectedTag != null && !collapsed.contains(_selectedTag)) {
      if (collapsed.length >= _maxVisibleChips) collapsed.removeLast();
      collapsed.add(_selectedTag!);
    }
    final remaining = ordered.length - collapsed.length;
    final overflow = ordered.length > _maxVisibleChips;
    final visible = _tagsExpanded ? ordered : collapsed;

    final wrap = Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        ...visible.map(_tagChip),
        // « +N autres » DÉPLIE la liste en place (plus de bottom sheet) ;
        // « Réduire » la replie.
        if (!_tagsExpanded && remaining > 0)
          _miniActionChip(
            icon: Icons.expand_more,
            label: '+$remaining autres',
            onPressed: () => setState(() => _tagsExpanded = true),
          ),
        if (_tagsExpanded && overflow)
          _miniActionChip(
            icon: Icons.expand_less,
            label: 'Réduire',
            onPressed: () => setState(() => _tagsExpanded = false),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      // Déplié : on plafonne la hauteur et on rend la zone défilable pour ne pas
      // repousser trop bas la liste des DJ quand il y a beaucoup de tags.
      child: _tagsExpanded
          ? ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: SingleChildScrollView(child: wrap),
            )
          : wrap,
    );
  }

  Widget _tagChip(String tag) {
    final selected = tag == _selectedTag;
    final count = AppDataManager().setIdsForTag(tag).length;
    return ChoiceChip(
      label: Text('#$tag ($count)', style: const TextStyle(fontSize: 12)),
      selected: selected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onSelected: (_) => setState(() => _selectedTag = selected ? null : tag),
    );
  }

  Widget _miniActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.only(left: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onPressed: onPressed,
    );
  }

  Widget _buildResults(
      List<TimetableItem> matches, Map<int, Set<String>> tagsBySet) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _selectedTag == null
                ? 'Aucun DJ tagué pour le moment.'
                : 'Aucun DJ pour ce tag sur ce festival.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: matches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Intro : rappelle l'ordre par défaut (sans tag sélectionné).
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              _selectedTag == null
                  ? 'Tous les DJ tagués · classés par popularité de leurs tags'
                  : 'DJ taggés « #$_selectedTag »',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          );
        }
        final item = matches[index - 1];
        final tags = (tagsBySet[item.setId] ?? const <String>{}).toList()
          ..sort();
        return DJListTile(
          item: item,
          isFavorite: AppDataManager().favoriteSetIds.contains(item.setId),
          showTime: false, // l'horaire n'apporte rien ici → tuiles plus compactes
          showFilterContext: false, // vue Tags = insensible au filtre favoris/équipe
          onToggleFavorite: () {
            AppDataManager().toggleFavorite(item.setId);
            setState(() {});
          },
          onTap: () => _onDjTileTap(item),
          footer: _TagsLine(
            tags: tags,
            activeTag: _selectedTag,
            djName: item.dj,
            // Cliquer un tag applique ce filtre ; recliquer le tag actif l'annule.
            onTagTap: (tag) =>
                setState(() => _selectedTag = _selectedTag == tag ? null : tag),
          ),
        );
      },
    );
  }
}

/// Ligne de tags affichée sous le nom du DJ dans la vue « DJ par tag ».
/// Montre quelques tags en puces CLIQUABLES (appliquent le tag comme filtre),
/// avec un « +N autres » qui ouvre une pop-up listant TOUS les tags de CE set.
class _TagsLine extends StatelessWidget {
  final List<String> tags;
  final String? activeTag;
  final String djName;
  final void Function(String tag) onTagTap;

  const _TagsLine({
    required this.tags,
    required this.activeTag,
    required this.djName,
    required this.onTagTap,
  });

  /// Nombre de puces avant le « +N autres » (au-delà, on tronque pour rester
  /// sur une ligne).
  static const int _maxShown = 3;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final shown = tags.take(_maxShown).toList();
    final extra = tags.length - shown.length;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final t in shown)
            _pill('#$t', onTap: () => onTagTap(t), active: t == activeTag),
          if (extra > 0)
            _pill('+$extra autres', onTap: () => _showAllSetTags(context)),
        ],
      ),
    );
  }

  /// Pop-up listant TOUS les tags de ce set ; chaque tag est cliquable et
  /// applique le filtre (puis ferme la pop-up).
  void _showAllSetTags(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'Tags de $djName',
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags)
                _pill(
                  '#$t',
                  onTap: () {
                    Navigator.pop(ctx);
                    onTagTap(t);
                  },
                  active: t == activeTag,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, {required VoidCallback onTap, bool active = false}) {
    // GestureDetector opaque → le tap sur la puce est capté avant celui de la
    // tuile (navigation fiche DJ) : on change le filtre, on n'ouvre pas la fiche.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.32)
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: active
              ? Border.all(color: Colors.white.withValues(alpha: 0.6))
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
