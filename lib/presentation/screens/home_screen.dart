import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import 'add_record_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
          () => context.read<VaccinationViewModel>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VaccinationViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Vaccination Records")),
      body: ListView.builder(
        itemCount: vm.records.length,
        itemBuilder: (_, i) {
          final r = vm.records[i];

          return Card(
            child: ListTile(
              title: Text(r.vaccineName),
              subtitle: Text("Dose ${r.dose} • ${r.date}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => vm.delete(r.id!),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddRecordScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}