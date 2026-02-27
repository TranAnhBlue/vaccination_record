import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/vaccination_record.dart';
import '../viewmodels/vaccination_viewmodel.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final name = TextEditingController();
  final dose = TextEditingController();
  final location = TextEditingController();
  final note = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VaccinationViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Record")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Vaccine")),
            TextField(controller: dose, decoration: const InputDecoration(labelText: "Dose")),
            TextField(controller: location, decoration: const InputDecoration(labelText: "Location")),
            TextField(controller: note, decoration: const InputDecoration(labelText: "Note")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await vm.add(
                  VaccinationRecord(
                    vaccineName: name.text,
                    dose: int.parse(dose.text),
                    date: DateTime.now().toString(),
                    location: location.text,
                    note: note.text,
                  ),
                );

                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}