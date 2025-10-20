import 'package:flutter/material.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';
import '../models/card.dart' as CardModel;
import '../models/folder.dart';

class CardsScreen extends StatefulWidget {
  final Folder folder;
  const CardsScreen({Key? key, required this.folder}) : super(key: key);

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final CardRepository cardRepo = CardRepository();
  final FolderRepository folderRepo = FolderRepository();

  late Future<List<CardModel.Card>> cardsFuture;

  @override
  void initState() {
    super.initState();
    cardsFuture = cardRepo.getCardsByFolder(widget.folder.id!);
  }

  Future<void> _refreshCards() async {
    setState(() {
      cardsFuture = cardRepo.getCardsByFolder(widget.folder.id!);
    });
  }

  Future<void> _deleteCard(int id) async {
    await cardRepo.deleteCard(id);
    await folderRepo.updateFolderPreview(widget.folder.id!);
    _refreshCards();
  }

  void _showCardLimitWarning(int count) {
    final msg = count >= 6
        ? 'This folder can only hold 6 cards.'
        : 'You need at least 3 cards in this folder.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folder.name} Cards'),
        backgroundColor: Colors.deepPurple,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final count = await cardRepo.countCardsInFolder(widget.folder.id!);
          if (count >= 6) {
            _showCardLimitWarning(count);
          } else {
            _addNewCard();
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<CardModel.Card>>(
        future: cardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final cards = snapshot.data ?? [];

          if (cards.isEmpty) {
            return const Center(child: Text('No cards in this folder.'));
          }

          if (cards.length < 3) {
            _showCardLimitWarning(cards.length);
          }

          return RefreshIndicator(
            onRefresh: _refreshCards,
            child: GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return Card(
                  color: Colors.deepPurple[50],
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.deepPurple.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      card.imageUrl.isNotEmpty
                          ? Image.network(card.imageUrl, height: 80)
                          : const Icon(Icons.image_not_supported, size: 80),
                      const SizedBox(height: 8),
                      Text(
                        card.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCard(card.id!),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Simple dialog for adding a new card manually
  Future<void> _addNewCard() async {
    final nameController = TextEditingController();
    final imageUrlController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Card Name')),
              TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newCard = CardModel.Card(
                    name: nameController.text,
                    suit: widget.folder.name,
                    imageUrl: imageUrlController.text.isEmpty
                        ? 'https://upload.wikimedia.org/wikipedia/commons/5/5a/Playing_card_blank.svg'
                        : imageUrlController.text,
                    folderId: widget.folder.id,
                    createdAt: DateTime.now(),
                  );
                  await cardRepo.insertCard(newCard);
                  await folderRepo.updateFolderPreview(widget.folder.id!);
                  Navigator.pop(context);
                  _refreshCards();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
