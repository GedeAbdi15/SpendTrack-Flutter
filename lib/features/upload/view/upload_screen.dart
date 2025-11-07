import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/gemini_service.dart';
import '../../../core/supabase_client.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _imageFile;
  bool _loading = false;
  Map<String, dynamic>? _parsedResult;

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
        return;
      }
    } else {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery permission denied')),
        );
        return;
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
      _parsedResult = null;
    });
    await _processImage();
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;
    setState(() => _loading = true);

    try {
      print("Processing image: ${_imageFile!.path}");
      final result = await GeminiService.parseReceipt(_imageFile!);
      print("Gemini result: $result");

      setState(() {
        _parsedResult = result;
        // _loading = false;
      });
    } catch (e, s) {
      print("Error in _processImage: $e\n$s");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses gambar: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveToDatabase() async {
    if (_parsedResult == null) return;

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final itemsInsert = await SupabaseConfig.client
        .from('items')
        .insert({
          'user_id': user.id,
          'date': _parsedResult!['date'],
          'total': _parsedResult!['total'],
        })
        .select()
        .single();

    final itemId = itemsInsert['id'];

    final details =
        List<Map<String, dynamic>>.from(_parsedResult!['items'] ?? []);
    for (var detail in details) {
      await SupabaseConfig.client.from('item_detail').insert({
        'item_id': itemId,
        'name': detail['name'],
        'qty': detail['qty'],
        'price': detail['price'],
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data saved successfully!')),
    );
  }

  Widget _buildPreview() {
    if (_parsedResult == null) return const SizedBox.shrink();

    final items =
        List<Map<String, dynamic>>.from(_parsedResult!['items'] ?? []);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${_parsedResult!['date']}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Total: Rp ${_parsedResult!['total']}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Text("Item Details:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFEFEFEF)),
                  children: [
                    Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('Name',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('Qty',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('Price',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                ...items.map((item) => TableRow(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(item['name'].toString())),
                        Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(item['qty'].toString())),
                        Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(item['price'].toString())),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Receipt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, height: 200),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            _buildPreview(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _parsedResult != null ? _saveToDatabase : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
