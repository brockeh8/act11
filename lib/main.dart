import 'package:flutter/material.dart';
import 'database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DB.instance.database; 
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Deck of Cards',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const FoldersScreen(),
        debugShowCheckedModeBanner: false,
      );
}

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});
  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  late Future<List<Map<String, dynamic>>> _folders;

  @override
  void initState() {
    super.initState();
    _folders = DB.instance.allFolders();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Folders (Suits)')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _folders,
          builder: (_, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final items = s.data!;
            if (items.isEmpty) return const Center(child: Text('No folders'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final f = items[i];
                return ListTile(
                  leading: f['previewImage'] == null
                      ? const Icon(Icons.folder)
                      : CircleAvatar(backgroundImage: NetworkImage(f['previewImage'] as String)),
                  title: Text(f['name'] as String),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CardsScreen(folder: f)),
                  ).then((_) => setState(() => _folders = DB.instance.allFolders())),
                );
              },
            );
          },
        ),
      );
}

class CardsScreen extends StatefulWidget {
  final Map<String, dynamic> folder;
  const CardsScreen({super.key, required this.folder});
  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  Future<List<Map<String, dynamic>>> _cards() =>
      DB.instance.cardsInFolder(widget.folder['id'] as int);
  Future<int> _count() => DB.instance.countInFolder(widget.folder['id'] as int);

  Future<void> _addOne() async {
    try {
      await DB.instance.assignOneToFolder(widget.folder['id'] as int);
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _removeOne() async {
    await DB.instance.removeOneFromFolder(widget.folder['id'] as int);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.folder['name'] as String),
          actions: [
            FutureBuilder<int>(
              future: _count(),
              builder: (_, s) {
                final n = s.data ?? 0;
                final warn = n < 3;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Cards: $n${warn ? " (min 3!)" : ""}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: warn ? Colors.amber : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _cards(),
          builder: (_, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final cards = s.data!;
            if (cards.isEmpty) {
              return const Center(child: Text('No cards yet in this folder'));
            }
            return GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .7,
              children: [
                for (final c in cards)
                  Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            c['imageUrl'] as String,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(c['name'] as String, textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _addOne, child: const Text('Add one'))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton(onPressed: _removeOne, child: const Text('Remove one'))),
              ],
            ),
          ),
        ),
      );
}
