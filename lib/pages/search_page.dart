import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../models/dj_model.dart';
import '../services/app_data_manager.dart';
import '../utils/utils.dart';
import '../widgets/lineup/dj_list_tile.dart';
import '../widgets/shared/festival_background.dart';
import 'djprofilepage.dart';

/// Page plein écran « Search » (utilisée en navigation depuis une fiche DJ,
/// pré-filtrée sur un tag).
class SearchPage extends StatelessWidget {
  final String? initialTag;

  const SearchPage({super.key, this.initialTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Search')),
      body: SearchView(initialTag: initialTag),
    );
  }
}

/// Contenu « Search » (sans Scaffold) → onglet du bottom-nav.
/// Recherche textuelle (surtout par nom de DJ, mais aussi scène, jour, tag) +
/// une rangée de boutons de filtres (Jour / Scène / Tags) ouvrant chacun une
/// feuille de sélection multiple. Les filtres se COMBINENT : ET entre catégories,
/// OU à l'intérieur d'une même catégorie (ex. « samedi » + « Area V »). Chaque
/// résultat est une tuile DJ → fiche DJ au tap.
class SearchView extends StatefulWidget {
  final String? initialTag;

  const SearchView({super.key, this.initialTag});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Filtres actifs (vides = pas de contrainte sur la catégorie).
  final Set<String> _selectedDays = {};
  final Set<String> _selectedStages = {};
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialTag != null) _selectedTags.add(widget.initialTag!);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _selectedDays.isNotEmpty ||
      _selectedStages.isNotEmpty ||
      _selectedTags.isNotEmpty;

  /// Tags d'un set (distincts) indexés par setId.
  Map<int, Set<String>> _tagsBySet() {
    final m = <int, Set<String>>{};
    for (final dt in AppDataManager().djTags) {
      m.putIfAbsent(dt.setId, () => <String>{}).add(dt.tag);
    }
    return m;
  }

  /// Compteurs CONTEXTUELS d'une facette ('day' | 'stage' | 'tag') : pour chaque
  /// option, le nombre de DJ (sets DISTINCTS) qui matcheraient compte tenu des
  /// AUTRES filtres + la recherche texte. On n'applique pas la facette elle-même
  /// (sinon les options non cochées tomberaient à 0). Distinct par setId → un tag
  /// posé par plusieurs users sur le même set ne compte qu'une fois.
  Map<String, int> _facetCounts(String facet, Map<int, Set<String>> tagsBySet) {
    final byOption = <String, Set<int>>{};
    for (final t in AppDataManager().timetable) {
      final tg = tagsBySet[t.setId] ?? const <String>{};
      if (facet != 'day' &&
          _selectedDays.isNotEmpty &&
          !_selectedDays.contains(t.day)) {
        continue;
      }
      if (facet != 'stage' &&
          _selectedStages.isNotEmpty &&
          !_selectedStages.contains(t.stage)) {
        continue;
      }
      if (facet != 'tag' &&
          _selectedTags.isNotEmpty &&
          _selectedTags.intersection(tg).isEmpty) {
        continue;
      }
      if (!_matchesQuery(t, tg)) continue;

      if (facet == 'day') {
        byOption.putIfAbsent(t.day, () => <int>{}).add(t.setId);
      } else if (facet == 'stage') {
        byOption.putIfAbsent(t.stage, () => <int>{}).add(t.setId);
      } else {
        for (final tag in tg) {
          byOption.putIfAbsent(tag, () => <int>{}).add(t.setId);
        }
      }
    }
    return {for (final e in byOption.entries) e.key: e.value.length};
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

  /// Normalise pour comparaison de recherche : minuscules + trim.
  String _norm(String s) => s.toLowerCase().trim();

  /// Un set correspond-il à la requête texte ? Cherche dans le nom du DJ (usage
  /// principal), la scène, le jour et les tags du set.
  bool _matchesQuery(TimetableItem item, Set<String> tagsOfSet) {
    final q = _norm(_query);
    if (q.isEmpty) return true;
    if (_norm(item.dj).contains(q)) return true;
    if (_norm(item.stage).contains(q)) return true;
    if (_norm(item.day).contains(q)) return true;
    for (final t in tagsOfSet) {
      if (_norm(t).contains(q)) return true;
    }
    return false;
  }

  /// Le set passe-t-il les filtres actifs (ET entre catégories, OU au sein d'une
  /// catégorie) ET la requête texte ?
  bool _passesFilters(TimetableItem item, Set<String> tagsOfSet) {
    if (_selectedDays.isNotEmpty && !_selectedDays.contains(item.day)) {
      return false;
    }
    if (_selectedStages.isNotEmpty && !_selectedStages.contains(item.stage)) {
      return false;
    }
    if (_selectedTags.isNotEmpty &&
        _selectedTags.intersection(tagsOfSet).isEmpty) {
      return false;
    }
    return _matchesQuery(item, tagsOfSet);
  }

  /// Libellé du jour en français (les jours sont stockés en anglais minuscule).
  String _dayLabel(String d) => AppUtils.getDayName(d);

  @override
  Widget build(BuildContext context) {
    final allTags = AppDataManager().allTagLabels;
    final timetable = AppDataManager().timetable;

    // Tags DISTINCTS par set (pour le filtre tags ET la ligne de tags des tuiles).
    final tagsBySet = _tagsBySet();

    // Jours distincts, ordonnés par dayInt.
    final dayOrder = <String, int>{};
    for (final t in timetable) {
      if (t.day.isNotEmpty) dayOrder.putIfAbsent(t.day, () => t.dayInt);
    }
    final days = dayOrder.keys.toList()
      ..sort((a, b) => dayOrder[a]!.compareTo(dayOrder[b]!));

    // Scènes distinctes, ordonnées par stageOrder (repli alpha).
    final stageOrder = <String, int?>{};
    for (final t in timetable) {
      if (t.stage.isNotEmpty) stageOrder.putIfAbsent(t.stage, () => t.stageOrder);
    }
    final stages = stageOrder.keys.toList()
      ..sort((a, b) {
        final ao = stageOrder[a];
        final bo = stageOrder[b];
        if (ao != null && bo != null && ao != bo) return ao.compareTo(bo);
        if (ao != null && bo == null) return -1;
        if (ao == null && bo != null) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    // Filtres + requête, puis tri alphabétique par nom de DJ.
    final matches = timetable
        .where((t) =>
            _passesFilters(t, tagsBySet[t.setId] ?? const <String>{}))
        .toList()
      ..sort((a, b) => a.dj.toLowerCase().compareTo(b.dj.toLowerCase()));

    return FestivalBackground(
      imageKey: 'featured',
      refreshDomains: const [LoadDomain.timetable, LoadDomain.tags],
      refreshLabel: 'Mise à jour…',
      child: Column(
        children: [
          _buildSearchField(),
          _buildFilterBar(days, stages, allTags),
          const Divider(height: 1),
          Expanded(child: _buildResults(matches, tagsBySet, timetable.isEmpty)),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Rechercher un DJ, une scène, un jour, un tag…',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Rangée de boutons de filtres (défilable horizontalement). Chaque bouton
  /// ouvre une feuille de sélection ; le compteur reflète les choix actifs.
  Widget _buildFilterBar(
      List<String> days, List<String> stages, List<String> allTags) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterButton(
              label: 'Jour',
              icon: Icons.calendar_today,
              count: _selectedDays.length,
              onTap: () => _openFilterSheet(
                facet: 'day',
                title: 'Filtrer par jour',
                options: days,
                selected: _selectedDays,
                labelOf: _dayLabel,
              ),
            ),
            _filterButton(
              label: 'Scène',
              icon: Icons.location_city,
              count: _selectedStages.length,
              onTap: () => _openFilterSheet(
                facet: 'stage',
                title: 'Filtrer par scène',
                options: stages,
                selected: _selectedStages,
              ),
            ),
            if (allTags.isNotEmpty)
              _filterButton(
                label: 'Tags',
                icon: Icons.tag,
                count: _selectedTags.length,
                onTap: () => _openFilterSheet(
                  facet: 'tag',
                  title: 'Filtrer par tag',
                  options: allTags, // allTagLabels = déjà trié alphabétiquement
                  selected: _selectedTags,
                  labelOf: (t) => '#$t',
                ),
              ),
            if (_hasActiveFilters)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _selectedDays.clear();
                    _selectedStages.clear();
                    _selectedTags.clear();
                  }),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Effacer'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton({
    required String label,
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) {
    final active = count > 0;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active
            ? AppTheme.accent.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  active ? '$label ($count)' : label,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.expand_more, size: 16, color: Colors.white54),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Feuille de sélection multiple pour une catégorie de filtre. Applique les
  /// changements en direct (la liste derrière se met à jour à chaque toggle).
  Future<void> _openFilterSheet({
    required String facet,
    required String title,
    required List<String> options,
    required Set<String> selected,
    String Function(String)? labelOf,
  }) async {
    // Compteurs contextuels figés à l'ouverture (les autres facettes/la requête
    // ne changent pas tant que la feuille est ouverte).
    final counts = _facetCounts(facet, _tagsBySet());
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (selected.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setSheetState(selected.clear);
                                setState(() {});
                              },
                              child: const Text('Tout effacer'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final opt in options)
                                FilterChip(
                                  label: Text(
                                      '${labelOf != null ? labelOf(opt) : opt}'
                                      ' (${counts[opt] ?? 0})'),
                                  selected: selected.contains(opt),
                                  onSelected: (on) {
                                    setSheetState(() {
                                      if (on) {
                                        selected.add(opt);
                                      } else {
                                        selected.remove(opt);
                                      }
                                    });
                                    setState(() {}); // maj de la liste derrière
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResults(List<TimetableItem> matches,
      Map<int, Set<String>> tagsBySet, bool timetableEmpty) {
    if (matches.isEmpty) {
      // Timetable encore vide → données en cours de chargement (au tout premier
      // accès) plutôt qu'un vrai « aucun résultat ».
      if (timetableEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final filtering = _query.isNotEmpty || _hasActiveFilters;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            filtering
                ? 'Aucun DJ ne correspond à ces critères.'
                : 'Aucun DJ.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final item = matches[index];
        final tags = (tagsBySet[item.setId] ?? const <String>{}).toList()
          ..sort();
        return DJListTile(
          item: item,
          isFavorite: AppDataManager().favoriteSetIds.contains(item.setId),
          showTime: false, // l'horaire n'apporte rien ici → tuiles plus compactes
          showFilterContext: false, // vue Search = insensible au filtre favoris/équipe
          onToggleFavorite: () {
            AppDataManager().toggleFavorite(item.setId);
            setState(() {});
          },
          onTap: () => _onDjTileTap(item),
          footer: _TagsLine(
            tags: tags,
            activeTags: _selectedTags,
            djName: item.dj,
            // Clic sur un tag d'une tuile = sélection EXCLUSIVE : un tag inactif
            // remplace le filtre Tags par lui seul ; un tag actif vide le filtre.
            onTagTap: (tag) => setState(() {
              final wasActive = _selectedTags.contains(tag);
              _selectedTags.clear();
              if (!wasActive) _selectedTags.add(tag);
            }),
          ),
        );
      },
    );
  }
}

/// Ligne de tags affichée sous le nom du DJ dans la vue « Search ».
/// Montre quelques tags en puces CLIQUABLES (ajoutent/retirent le tag du filtre),
/// avec un « +N autres » qui ouvre une pop-up listant TOUS les tags de CE set.
class _TagsLine extends StatelessWidget {
  final List<String> tags;
  final Set<String> activeTags;
  final String djName;
  final void Function(String tag) onTagTap;

  const _TagsLine({
    required this.tags,
    required this.activeTags,
    required this.djName,
    required this.onTagTap,
  });

  /// Style (gras, conservateur) servant à MESURER la largeur des puces pour
  /// décider combien tiennent sur une seule ligne.
  static const TextStyle _measureStyle =
      TextStyle(fontSize: 11, fontWeight: FontWeight.w600);

  /// Largeur estimée d'une puce pour un libellé (texte + padding + sécurité).
  double _pillWidth(String text, TextScaler scaler) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _measureStyle),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    return tp.width + 18; // padding horizontal (8+8) + marge bordure/arrondi
  }

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    const spacing = 6.0;
    final scaler = MediaQuery.textScalerOf(context);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      // Une SEULE ligne : on calcule combien de puces tiennent dans la largeur
      // dispo (selon la longueur RÉELLE des libellés), le reste bascule en
      // « +N autres ». Toutes les tuiles ont ainsi la même hauteur.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final shown = <String>[];
          double used = 0;
          for (var i = 0; i < tags.length; i++) {
            final w = _pillWidth('#${tags[i]}', scaler);
            final addition = (shown.isEmpty ? 0 : spacing) + w;
            final remainingAfter = tags.length - (i + 1);
            // Réserve la place d'un « +N autres » s'il restera des tags après.
            final reserve = remainingAfter > 0
                ? spacing + _pillWidth('+$remainingAfter autres', scaler)
                : 0.0;
            if (used + addition + reserve <= maxW) {
              shown.add(tags[i]);
              used += addition;
            } else {
              break;
            }
          }
          final extra = tags.length - shown.length;

          final children = <Widget>[];
          for (final t in shown) {
            if (children.isNotEmpty) children.add(const SizedBox(width: spacing));
            children.add(_pill('#$t',
                onTap: () => onTagTap(t), active: activeTags.contains(t)));
          }
          if (extra > 0) {
            if (children.isNotEmpty) children.add(const SizedBox(width: spacing));
            children.add(
                _pill('+$extra autres', onTap: () => _showAllSetTags(context)));
          }
          return Row(mainAxisSize: MainAxisSize.min, children: children);
        },
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
                  active: activeTags.contains(t),
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
