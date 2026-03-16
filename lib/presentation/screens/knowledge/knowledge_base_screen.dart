import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/vaccine_info.dart';
import '../../../data/repositories/vaccine_info_repository.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final _repository = VaccineInfoRepository();
  late List<VaccineInfo> _allVaccines;
  List<VaccineInfo> _filteredVaccines = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allVaccines = _repository.getAllVaccines();
    _filteredVaccines = _allVaccines;
  }

  void _filterVaccines(String query) {
    setState(() {
      _filteredVaccines = _allVaccines
          .where((v) =>
              v.name.toLowerCase().contains(query.toLowerCase()) ||
              v.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Cẩm nang Vắc-xin"),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterVaccines,
              decoration: InputDecoration(
                hintText: "Tìm kiếm vắc-xin...",
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredVaccines.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredVaccines.length,
                    itemBuilder: (context, index) {
                      return _buildVaccineCard(_filteredVaccines[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Không tìm thấy vắc-xin phù hợp",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineCard(VaccineInfo vaccine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(vaccine.icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          vaccine.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          vaccine.category,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedAlignment: Alignment.topLeft,
        children: [
          _buildDetailSection("Mô tả:", vaccine.description),
          const SizedBox(height: 12),
          _buildDetailSection("Lịch tiêm:", vaccine.schedule),
          const SizedBox(height: 12),
          _buildDetailSection("Phản ứng phụ:", vaccine.sideEffects),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
        ),
      ],
    );
  }
}
