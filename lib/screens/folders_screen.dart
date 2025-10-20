import 'package:flutter/material.dart';
import '../repositories/folder_repository.dart';
import '../repositories/card_repository.dart';
import '../models/folder.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({Key? key}) : super(key: key);

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FolderRepository folderRepo = FolderRepository();
  final CardRepository cardRepo = CardRepository();

  late Future<List<Folder>> foldersFuture;

  @override
  void initState() {
    super.initState();
    foldersFuture = folderRepo.getAllFolders();
  }

  Future<void> _refreshFolders() async {
    setState(() {
      foldersFuture = folderRepo.getAllFolders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer App'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Folder>>(
        future: foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final folders = snapshot.data ?? [];

          if (folders.isEmpty) {
            return const Center(child: Text('No folders found.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshFolders,
            child: GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return FutureBuilder<int>(
                  future: folderRepo.countCardsInFolder(folder.id!),
                  builder: (context, countSnapshot) {
                    final cardCount = countSnapshot.data ?? 0;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CardsScreen(folder: folder),
                          ),
                        ).then((_) => _refreshFolders());
                      },
                      child: Card(
                        color: Colors.deepPurple[50],
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.deepPurple.shade200),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            folder.previewImage != null
                                ? Image.network(
                                    folder.previewImage!,
                                    height: 80,
                                  )
                                : const Icon(Icons.folder, size: 80, color: Colors.deepPurple),
                            const SizedBox(height: 10),
                            Text(
                              folder.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text('$cardCount cards'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
