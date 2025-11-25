import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class ProgressInputScreen extends StatefulWidget {
  const ProgressInputScreen({super.key});

  @override
  State<ProgressInputScreen> createState() => _ProgressInputScreenState();
}

class _ProgressInputScreenState extends State<ProgressInputScreen> {
  String? selectedProductId;
  String? selectedStatus;
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('進捗入力')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 製品選択
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final products = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: '製品符号または部材種別'),
                  value: selectedProductId,
                  items: products.map((doc) {
                    final name = doc['name'] ?? '';
                    final type = doc['type'] ?? '';
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text('$name（$type）'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProductId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // 状態選択
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '状態'),
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'not_started', child: Text('未着手')),
                DropdownMenuItem(value: 'in_progress', child: Text('作業中')),
                DropdownMenuItem(value: 'completed', child: Text('完了')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // 日付選択
            Row(
              children: [
                Text(
                  selectedDate == null
                      ? '実施日を選択'
                      : '実施日: 	${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 1),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: const Text('日付選択'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (selectedProductId != null &&
                        selectedStatus != null &&
                        selectedDate != null)
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await FirebaseService().updateProductProgress(
                          productId: selectedProductId!,
                          status: selectedStatus!,
                          date: selectedDate!,
                        );
                        messenger
                            .showSnackBar(const SnackBar(content: Text('保存しました')));
                      }
                    : null,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
