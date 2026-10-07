import 'package:flutter/material.dart';

class SaveSlotsSheet extends StatefulWidget {
  const SaveSlotsSheet({super.key});

  @override
  State<SaveSlotsSheet> createState() => _SaveSlotsSheetState();
}

class _SaveSlotsSheetState extends State<SaveSlotsSheet> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final start = _page * 6;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kayıtlar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.autorenew_rounded),
                  title: const Text('Otomatik kayıt'),
                  subtitle: const Text('Son oyun durumu'),
                  trailing: FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('Yükle'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: 6,
                  itemBuilder: (context, index) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${start + index + 1}'),
                      ),
                      title: Text('Kayıt yuvası ${start + index + 1}'),
                      subtitle: const Text('Boş'),
                      trailing: IconButton(
                        icon: const Icon(Icons.save_outlined),
                        tooltip: 'Kaydet',
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _page == 0
                        ? null
                        : () => setState(() => _page--),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Center(child: Text('Sayfa ${_page + 1} / 10')),
                  ),
                  IconButton(
                    onPressed: _page == 9
                        ? null
                        : () => setState(() => _page++),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('İçe aktar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Dışa aktar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
