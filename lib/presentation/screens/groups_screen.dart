import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/database/database.dart';
import '../widgets/add_group_dialog.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: StreamBuilder<List<Group>>(
        // Use the DAO to watch groups
        stream: db.groupsDao.watchGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return const Center(child: Text('No groups yet. Add one below!'));
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: const Icon(Icons.storefront),
                title: Text(group.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  // Use the DAO to delete
                  onPressed: () => db.groupsDao.deleteGroup(group.id),
                ),
                onTap: () {
                  print('Selected group: ${group.name}');
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddGroupDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
