import 'package:flutter/material.dart';

class CheatModesSheet extends StatelessWidget {
  const CheatModesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hile modları',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Değişkenler'),
                  Tab(text: 'Kilitler'),
                  Tab(text: 'Işınlan'),
                  Tab(text: 'Envanter'),
                  Tab(text: 'Konsol'),
                  Tab(text: 'Fark'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _variables(),
                    _message('Dondurulmuş değişken yok'),
                    _message('Konum seçin'),
                    _message('Envanter boş'),
                    _console(),
                    _message('Başlangıç anlık görüntüsü hazır'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _variables() => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      TextField(
        decoration: InputDecoration(
          hintText: 'Değişken ara',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      SizedBox(height: 12),
      ListTile(
        title: Text('health'),
        subtitle: Text('100'),
        trailing: Icon(Icons.edit_outlined),
      ),
      ListTile(
        title: Text(r'$location'),
        subtitle: Text('Başlangıç'),
        trailing: Icon(Icons.edit_outlined),
      ),
    ],
  );

  Widget _console() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        const Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: Text('QSP konsolu'),
          ),
        ),
        TextField(
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'QSP komutu',
            suffixIcon: Icon(Icons.play_arrow_rounded),
          ),
        ),
      ],
    ),
  );

  Widget _message(String value) => Center(child: Text(value));
}
