import 'package:client/models/employee_model.dart';
import 'package:client/services/employee_service.dart';
import 'package:client/services/export_employee_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<EmployeeModel> _employees = [];
  List<EmployeeModel> _filteredEmployees = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(() {
      _performSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await EmployeeService.instance.getEmployees();

      if (response.success && response.data != null) {
        setState(() {
          // ✅ FILTER: Exclude user ID 1 & 2 (test accounts)
          _employees = response.data!
              .where((employee) => employee.userId != 1 && employee.userId != 2)
              .toList();
          _filteredEmployees = _employees;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message.isEmpty
              ? 'Gagal memuat data karyawan'
              : response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filteredEmployees = _employees);
      return;
    }

    setState(() {
      _filteredEmployees = _employees.where((emp) {
        final fullName = emp.fullName.toLowerCase();
        final position = emp.position?.name.toLowerCase() ?? '';
        final department = emp.department?.name.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return fullName.contains(searchQuery) ||
            position.contains(searchQuery) ||
            department.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _refresh() async {
    await _loadEmployees();
  }

  Future<void> _exportToExcel() async {
    // ✅ CHECK IF EMPTY
    if (_employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk di-export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // ✅ SHOW LOADING
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Mengekspor data ke Excel...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Color(0xFF22A9D6),
        ),
      );

      // ✅ EXPORT TO EXCEL
      final filePath = await ExcelService.instance.exportEmployees(_employees);

      // ✅ HIDE LOADING
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (filePath != null && mounted) {
        // ✅ SUCCESS
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ File berhasil disimpan!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Lokasi: $filePath', style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'BUKA',
              textColor: Colors.white,
              onPressed: () {
                ExcelService.instance.openFile(filePath);
              },
            ),
          ),
        );
      } else if (mounted) {
        // ✅ FAILED
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gagal mengekspor data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A9D6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF22A9D6),
        title: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daftar Karyawan",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Kelola data karyawan dengan mudah",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Image.asset('assets/logoPbl.png', width: 45, height: 45),
          ],
        ),
        toolbarHeight: 80,
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF22A9D6)),
          Positioned.fill(
            top: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, jabatan, atau departemen...',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF22A9D6),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await context.push(
                              "/admin/register",
                            );
                            if (result == true) {
                              _loadEmployees();
                            }
                          },
                          icon: const Icon(Icons.person_add, size: 20),
                          label: const Text("Tambah Karyawan"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22A9D6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _exportToExcel,
                        icon: const Icon(Icons.table_chart, size: 20),
                        label: const Text("Export"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      color: const Color(0xFF22A9D6),
                      child: _buildBody(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22A9D6)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22A9D6),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isNotEmpty
                  ? Icons.search_off
                  : Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Tidak ditemukan hasil untuk "${_searchController.text}"'
                  : 'Belum ada data karyawan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
                icon: const Icon(Icons.clear),
                label: const Text('Hapus Pencarian'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, i) {
        return _buildEmployeeCard(_filteredEmployees[i]);
      },
    );
  }

  Widget _buildEmployeeCard(EmployeeModel employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ✅ AVATAR WITH PHOTO
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1B7FA8),
              backgroundImage: employee.profilePhotoUrl != null
                  ? NetworkImage(employee.profilePhotoUrl!)
                  : null,
              child: employee.profilePhotoUrl == null
                  ? Text(
                      employee.fullName.isNotEmpty
                          ? employee.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // ✅ INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName.isEmpty
                        ? "Tanpa Nama"
                        : employee.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D8AB8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          employee.position?.name ?? 'Tidak ada jabatan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    employee.department?.name ?? 'Tidak ada department',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1B9FE2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ ACTION BUTTONS (EDIT & INFO)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol Edit
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      final result = await context.push(
                        "/admin/edit-employee",
                        extra: employee.id,
                      );
                      if (result == true) {
                        _loadEmployees();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 241, 165, 59),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol Info/Detail
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      final result = await context.push(
                        "/admin/profile-detail",
                        extra: employee.userId,
                      );
                      if (result == true) {
                        _loadEmployees();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22A9D6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 33,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
