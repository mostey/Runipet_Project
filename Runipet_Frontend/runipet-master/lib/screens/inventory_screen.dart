import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import '../models/user_data.dart';

class InventoryScreen extends StatefulWidget {
  final UserData userData;
  final Function(UserData) onUserDataChanged;

  const InventoryScreen({
    super.key,
    required this.userData,
    required this.onUserDataChanged,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    // 인벤토리 아이템 로드
    Future.microtask(() => 
      Provider.of<InventoryProvider>(context, listen: false).loadInventoryItems()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        if (inventoryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (inventoryProvider.error != null) {
          return Center(child: Text('에러: ${inventoryProvider.error}'));
        }

        final items = inventoryProvider.items;

        return Scaffold(
          appBar: AppBar(
            title: const Text('인벤토리'),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildInventoryItem(item);
            },
          ),
        );
      },
    );
  }

  Widget _buildInventoryItem(InventoryItem item) {
    final itemCount = widget.userData.inventory[item.id] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.asset(
              item.imagePath,
              width: 80,
              height: 80,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '보유: $itemCount개',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: itemCount > 0
                            ? () async {
                                try {
                                  await Provider.of<InventoryProvider>(context, listen: false)
                                      .useItem(item.id);
                                  
                                  // 사용자 데이터 업데이트
                                  final newInventory = Map<String, int>.from(widget.userData.inventory);
                                  newInventory[item.id] = itemCount - 1;
                                  if (newInventory[item.id] == 0) {
                                    newInventory.remove(item.id);
                                  }
                                  
                                  final updatedUserData = widget.userData.copyWith(
                                    inventory: newInventory,
                                  );
                                  widget.onUserDataChanged(updatedUserData);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('아이템 사용 완료!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('아이템 사용 실패: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('사용'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
