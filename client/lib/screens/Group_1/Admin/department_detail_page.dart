import 'package:flutter/material.dart';
import 'package:client/services/department_letter_detail_service.dart';
import 'package:client/models/department_letter_detail_model.dart';
import 'package:go_router/go_router.dart';

class DepartmentDetailPage extends StatefulWidget {
  final Map<String, dynamic> departmentData;

  const DepartmentDetailPage({super.key, required this.departmentData});

  @override
  State<DepartmentDetailPage> createState() => _DepartmentDetailPageState();
}

class _DepartmentDetailPageState extends State<DepartmentDetailPage> {
  final TextEditingController searchController = TextEditingController();
  final DepartmentLetterDetailService _service =
      DepartmentLetterDetailService.instance;

  late int totalEmployees;
  late int employeesWithLeave;

  List<EmployeeLeaveDetail> employees = [];
  List<EmployeeLeaveDetail> filteredEmployees = [];

  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_runFilter);
    _loadDepartmentData();
  }

  Future<void> _loadDepartmentData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await _service.getDepartmentDetail(
        departmentName: widget.departmentData['name'],
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final data = response.data!;

        setState(() {
          employees = data.employees;
          filteredEmployees = List.from(employees);
          totalEmployees = data.totalEmployees;
          employeesWithLeave = data.employeesWithLeave;
          loading = false;
        });
      } else {
        setState(() {
          errorMessage = response.message;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error: $e";
          loading = false;
        });
      }
    }
  }

  void _runFilter() {
    String keyword = searchController.text.toLowerCase();

    setState(() {
      filteredEmployees = employees.where((e) {
        return e.employeeName.toLowerCase().contains(keyword);
      }).toList();
    });
  }

  // ✅ SIMPLIFIED: Export Excel using service
  Future<void> exportToExcel() async {
    if (filteredEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak ada data untuk diekspor"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(height: 16),
                  Text('Membuat file Excel...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // ✅ Call service to generate Excel
      final response = await _service.exportDepartmentExcel(
        departmentName: widget.departmentData['name'],
        employees: filteredEmployees,
      );

      // ✅ IMMEDIATELY close dialog (don't check mounted first)
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      if (response.success && response.data != null) {
        // ✅ Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("File Excel berhasil dibuat"),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 1500), // ✅ Shorter duration
          ),
        );

        // ✅ Open file immediately (non-blocking)
        _service.openExcelFile(response.data!).catchError((e) {
          debugPrint("Error opening file: $e");
        });

        // ✅ Shorter delay before navigation
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        // ✅ Navigate to refresh
        context.go('/admin/department-detail', extra: widget.departmentData);
      } else {
        // ✅ Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
              duration: const Duration(milliseconds: 1500),
            ),
          );
        }
      }
    } catch (e) {
      // ✅ IMMEDIATELY close dialog on error
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 2000),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dept = widget.departmentData;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/laporan-izin'),
        ),
        title: Text("Laporan Dept ${dept['name']}"),
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDepartmentData,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(dept),
                    const SizedBox(height: 20),

                    if (filteredEmployees.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Tidak ada data karyawan",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    else
                      ...filteredEmployees.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final e = entry.value;

                        return _buildEmployeeCard(
                          index: index,
                          name: e.employeeName,
                          totalCuti: e.totalApprovedLetters,
                          jenisCuti: e.leaveTypes
                              .map((lt) => "${lt.name} (${lt.date})")
                              .toList(),
                        );
                      }).toList(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  // ✅ EXISTING UI WIDGETS (UNCHANGED)
  Widget _buildHeader(Map<String, dynamic> dept) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF00A8E8),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dept. ${dept['name']}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              _buildEmployeeCountBox(dept),
              const SizedBox(width: 12),
              _buildSearchBox(),
            ],
          ),

          const SizedBox(height: 20),

          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildEmployeeCountBox(Map<String, dynamic> dept) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 32),
          const SizedBox(width: 8),
          Text(
            "$employeesWithLeave / $totalEmployees",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Expanded(
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search",
                ),
              ),
            ),
            const Icon(Icons.search),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return GestureDetector(
      onTap: exportToExcel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Export Excel",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard({
    required int index,
    required String name,
    required int totalCuti,
    required List<String> jenisCuti,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$index. $name",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Departemen: ${widget.departmentData['name']}",
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                "Total Cuti Disetujui: $totalCuti",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            "Jenis Cuti:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),
          ...jenisCuti.map(
            (e) => Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text("• $e"),
            ),
          ),
        ],
      ),
    );
  }
}
