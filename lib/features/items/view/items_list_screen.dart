import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> receipts = [];

  @override
  void initState() {
    super.initState();
    fetchReceipts();
  }

  Future<void> fetchReceipts() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final itemsResponse = await SupabaseConfig.client
          .from('items')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false);

      List<Map<String, dynamic>> tempReceipts = [];
      for (final item in itemsResponse) {
        final detailsResponse = await SupabaseConfig.client
            .from('item_detail')
            .select()
            .eq('item_id', item['id']);

        tempReceipts.add({
          "date": item['date'],
          "total": item['total'],
          "items": detailsResponse,
        });
      }

      setState(() {
        receipts = tempReceipts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching receipts: $e");
    }
  }

  void showReceiptDetail(BuildContext context, Map<String, dynamic> receipt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final List<dynamic> items = receipt['items'];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text("Detail Nota",
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Tanggal: ${receipt['date']}"),
                  Text("Total: Rp ${receipt['total']}"),
                ],
              ),
              const Divider(),
              ...List.generate(items.length, (index) {
                final item = items[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text("Qty: ${item['qty']}"),
                  trailing: Text("Rp ${item['price']}"),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Receipt Data"),
        // centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : receipts.isEmpty
              ? const Center(
                  child: Text(
                  "Sorry, you don't have any receipts yet. \nPlease upload a receipt first.",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ))
              : RefreshIndicator(
                  onRefresh: fetchReceipts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: receipts.length,
                    itemBuilder: (context, index) {
                      final receipt = receipts[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text("Date: ${receipt['date']}"),
                          subtitle: Text("Total: Rp ${receipt['total']}"),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => showReceiptDetail(context, receipt),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
