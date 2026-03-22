import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';
import 'friend_view_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _friendships = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.instance.fetchFriendships();
      setState(() { _friendships = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String get _myId => SupabaseService.instance.userId ?? '';

  List<Map<String, dynamic>> get _accepted =>
      _friendships.where((f) => f['status'] == 'accepted').toList();

  List<Map<String, dynamic>> get _pending =>
      _friendships.where((f) =>
          f['status'] == 'pending' && f['addressee_id'] == _myId).toList();

  Map<String, dynamic> _friendProfile(Map<String, dynamic> f) =>
      f['requester_id'] == _myId ? f['addressee'] : f['requester'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes amis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () async {
              await _showAddFriendDialog();
              _load();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Amis (${_accepted.length})'),
            Tab(text: 'Demandes (${_pending.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _FriendsList(
                  friends: _accepted,
                  myId: _myId,
                  getFriendProfile: _friendProfile,
                  onRemove: (f) async {
                    await SupabaseService.instance.removeFriend(f['id']);
                    _load();
                  },
                  onView: (f) {
                    final profile = _friendProfile(f);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FriendViewScreen(
                        friendId:   profile['id'],
                        friendName: profile['full_name'] ?? profile['username'],
                      ),
                    ));
                  },
                ),
                _PendingList(
                  pending: _pending,
                  getFriendProfile: _friendProfile,
                  onAccept: (f) async {
                    await SupabaseService.instance.acceptFriendRequest(f['id']);
                    _load();
                  },
                  onReject: (f) async {
                    await SupabaseService.instance.rejectFriendRequest(f['id']);
                    _load();
                  },
                ),
              ],
            ),
    );
  }

  Future<void> _showAddFriendDialog() async {
    final ctrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool searching = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Ajouter un ami',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom d\'utilisateur…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : null,
                ),
                onChanged: (v) async {
                  if (v.length < 2) { setDlgState(() => results = []); return; }
                  setDlgState(() => searching = true);
                  final r = await SupabaseService.instance.searchProfiles(v);
                  setDlgState(() { results = r; searching = false; });
                },
              ),
              const SizedBox(height: 12),
              if (results.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final p = results[i];
                    return ListTile(
                      leading: _Avatar(name: p['username'] ?? '?'),
                      title: Text(p['full_name'] ?? p['username'],
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('@${p['username']}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
                      trailing: TextButton(
                        onPressed: () async {
                          await SupabaseService.instance.sendFriendRequest(p['id']);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Demande envoyée !')));
                        },
                        child: const Text('Inviter'),
                      ),
                    );
                  },
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          ],
        ),
      ),
    );
  }
}

// ── Friends list ──────────────────────────────────────────────────────────────
class _FriendsList extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  final String myId;
  final Map<String, dynamic> Function(Map<String, dynamic>) getFriendProfile;
  final ValueChanged<Map<String, dynamic>> onRemove;
  final ValueChanged<Map<String, dynamic>> onView;

  const _FriendsList({
    required this.friends,
    required this.myId,
    required this.getFriendProfile,
    required this.onRemove,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_outline_rounded,
        message: 'Aucun ami pour l\'instant',
        sub: 'Ajoutez des amis avec le bouton +',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final f = friends[i];
        final p = getFriendProfile(f);
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: _Avatar(name: p['username'] ?? '?'),
            title: Text(p['full_name'] ?? p['username'],
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('@${p['username']}',
                style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded, color: AppTheme.primary),
                tooltip: 'Voir les données',
                onPressed: () => onView(f),
              ),
              IconButton(
                icon: Icon(Icons.person_remove_outlined,
                    color: Colors.grey.shade400),
                tooltip: 'Retirer',
                onPressed: () => onRemove(f),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ── Pending list ───────────────────────────────────────────────────────────────
class _PendingList extends StatelessWidget {
  final List<Map<String, dynamic>> pending;
  final Map<String, dynamic> Function(Map<String, dynamic>) getFriendProfile;
  final ValueChanged<Map<String, dynamic>> onAccept;
  final ValueChanged<Map<String, dynamic>> onReject;

  const _PendingList({
    required this.pending,
    required this.getFriendProfile,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return const _EmptyState(
        icon: Icons.mark_email_unread_outlined,
        message: 'Aucune demande en attente',
        sub: 'Les invitations de vos amis apparaîtront ici',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final f = pending[i];
        final p = getFriendProfile(f);
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: _Avatar(name: p['username'] ?? '?'),
            title: Text(p['full_name'] ?? p['username'],
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('@${p['username']}',
                style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success),
                tooltip: 'Accepter',
                onPressed: () => onAccept(f),
              ),
              IconButton(
                icon: const Icon(Icons.cancel_rounded, color: AppTheme.danger),
                tooltip: 'Refuser',
                onPressed: () => onReject(f),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppTheme.primary.withOpacity(0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: AppTheme.primary, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState({required this.icon, required this.message, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text(sub, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]),
    );
  }
}
