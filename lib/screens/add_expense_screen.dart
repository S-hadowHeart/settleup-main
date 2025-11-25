import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String _category = 'Other';
  String? _selectedGroupId;
  String? _paidBy;

  bool _equalSplit = true;
  final Set<String> _selectedMembers = {};

  bool _didHandleRouteArg = false;
  bool _loading = false;

  String? _attachmentUrl;

  @override
  void initState() {
    super.initState();
    _paidBy = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didHandleRouteArg) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String) {
        _selectedGroupId = arg;
      }
      _didHandleRouteArg = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    Future<void> _pickAttachment() async {
      final picker = ImagePicker();

      dynamic picked;
      try {
        picked = await picker.pickImage(source: ImageSource.gallery);
      } catch (_) {
        picked = null;
      }

      if (picked == null) {
        return;
      }

      if (!mounted) return;
      setState(() => _loading = true);

      String? realPath;

      try {
        try {
          final p = (picked as dynamic).path;
          if (p != null && p is String && p.isNotEmpty) {
            realPath = p;
          }
        } catch (_) {
          realPath = null;
        }

        if (realPath == null) {
          try {
            final tmpDir = await getTemporaryDirectory();
            final tmpPath =
                '${tmpDir.path}/attachment_${DateTime.now().millisecondsSinceEpoch}.jpg';
            await (picked as dynamic).saveTo(tmpPath);
            if (File(tmpPath).existsSync()) realPath = tmpPath;
          } catch (_) {
            realPath = null;
          }
        }

        if (realPath == null) {
          try {
            final bytes = await (picked as dynamic).readAsBytes();
            if (bytes != null && bytes is List<int>) {
              final tmpDir = await getTemporaryDirectory();
              final tmpPath =
                  '${tmpDir.path}/attachment_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final f = File(tmpPath);
              await f.writeAsBytes(bytes);
              if (f.existsSync()) realPath = tmpPath;
            }
          } catch (_) {
            realPath = null;
          }
        }

        if (realPath == null) {
          try {
            final stream = (picked as dynamic).openRead();
            if (stream != null) {
              final tmpDir = await getTemporaryDirectory();
              final tmpPath =
                  '${tmpDir.path}/attachment_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final f = File(tmpPath);
              final sink = f.openWrite();
              await for (final chunk in stream) {
                sink.add(chunk as List<int>);
              }
              await sink.close();
              if (f.existsSync()) realPath = tmpPath;
            }
          } catch (_) {
            realPath = null;
          }
        }

        if (realPath == null) {
          throw Exception(
            'Could not obtain a usable file path or bytes from the selected image.',
          );
        }

        final file = File(realPath);
        if (!file.existsSync())
          throw Exception('Temp file does not exist: $realPath');

        FirebaseStorage storage;
        final defaultBucket = FirebaseStorage.instance.bucket;
        try {
          storage = FirebaseStorage.instance;
        } catch (_) {
          storage = FirebaseStorage.instanceFor(
            bucket: 'gs://YOUR_BUCKET_HERE',
          );
        }

        final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$uid.jpg';
        final groupSegment = (_selectedGroupId ?? 'general').toString();
        final storagePath = 'attachments/$groupSegment/$fileName';

        final ref = storage.ref().child(storagePath);

        final metadata = SettableMetadata(contentType: 'image/jpeg');

        final uploadTask = ref.putFile(file, metadata);

        final snapshot = await uploadTask.whenComplete(() => null);

        final downloadUrl = await ref.getDownloadURL();

        if (!mounted) return;
        setState(() {
          _attachmentUrl = downloadUrl;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Attachment uploaded')));
      } catch (e, st) {
        debugPrint('Attachment upload failed: $e\n$st');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final fire = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    String groupId = _selectedGroupId ?? "";

    if (groupId.isEmpty) {
      final snap = await fire
          .collection('groups')
          .where('members', arrayContains: uid)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You don't have any groups yet.")),
        );
        setState(() => _loading = false);
        return;
      }
      groupId = snap.docs.first.id;
    }

    final groupDoc = await fire.collection('groups').doc(groupId).get();
    final members =
        (groupDoc.data()?['members'] as List<dynamic>?)?.cast<String>() ?? [];

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    final chosenMembers = _equalSplit ? members : _selectedMembers.toList();

    final perShare = chosenMembers.isEmpty
        ? 0.0
        : amount / chosenMembers.length;

    final Map<String, double> splits = {
      for (final m in members) m: chosenMembers.contains(m) ? perShare : 0.0,
    };

    await fire.collection('groups').doc(groupId).collection('expenses').add({
      'title': title,
      'amount': amount,
      'category': _category,
      'paidBy': _paidBy ?? uid,
      'splits': splits,
      'attachmentUrl': _attachmentUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add expense")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              const Text(
                "Choose group",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 140,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final groups = snap.data!.docs;

                    if (groups.isEmpty) {
                      return const Center(child: Text("No groups"));
                    }

                    if (_selectedGroupId == null) {
                      _selectedGroupId = groups.first.id;
                    }

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final doc = groups[idx];
                        final g = doc.data() as Map<String, dynamic>;
                        final selected = _selectedGroupId == doc.id;

                        return GestureDetector(
                          onTap: () async {
                            setState(() {
                              _selectedGroupId = doc.id;
                              _selectedMembers.clear();
                            });

                            final memList =
                                (g['members'] as List?)?.cast<String>() ?? [];

                            setState(() {
                              _selectedMembers.addAll(memList);
                            });
                          },
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: selected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(context).cardColor,
                              border: selected
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(child: Text(g['emoji'] ?? '👥')),
                                const SizedBox(height: 8),
                                Text(
                                  g['name'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${(g['members'] as List?)?.length ?? 0} members",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                children: ['Food', 'Travel', 'Shopping', 'Other']
                    .map(
                      (c) => ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text("Equal split"),
                value: _equalSplit,
                onChanged: (v) => setState(() => _equalSplit = v),
              ),

              if (!_equalSplit)
                StreamBuilder<DocumentSnapshot>(
                  stream: _selectedGroupId != null
                      ? FirebaseFirestore.instance
                            .collection('groups')
                            .doc(_selectedGroupId)
                            .snapshots()
                      : null,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snap.data!.data() as Map<String, dynamic>?;
                    final mems =
                        (data?['members'] as List?)?.cast<String>() ?? [];

                    return Wrap(
                      spacing: 8,
                      children: mems.map((m) {
                        final selected = _selectedMembers.contains(m);

                        return FilterChip(
                          selected: selected,
                          label: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(m)
                                .get(),
                            builder: (context, us) {
                              if (!us.hasData) {
                                return const Text('...');
                              }
                              final u =
                                  us.data!.data() as Map<String, dynamic>?;
                              return Text(
                                "${u?['emoji'] ?? '🙂'} ${u?['name'] ?? m}",
                              );
                            },
                          ),
                          onSelected: (sel) {
                            setState(() {
                              sel
                                  ? _selectedMembers.add(m)
                                  : _selectedMembers.remove(m);
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _pickAttachment,
                      icon: const Icon(Icons.attach_file),
                      label: _loading
                          ? const Text("Uploading...")
                          : const Text("Attach bill"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Text("Save expense"),
                    ),
                  ),
                ],
              ),

              if (_attachmentUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    "Attached: Added successfully",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
