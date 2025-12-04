import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:client/utils/constant.dart';

class AdminIzinManager extends StatefulWidget {
  const AdminIzinManager({super.key});

  @override
  State<AdminIzinManager> createState() => _AdminIzinManagerState();
}

class _AdminIzinManagerState extends State<AdminIzinManager> {
  String selectedFilter = "All";

  List<dynamic> izinData = [];
  bool loading = true;

  int approvedOrRejected = 0;
  int pending = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
    loadIzinList();
  }

  // ================================================================
  // LOAD DASHBOARD
  // ================================================================
  Future<void> loadDashboard() async {
    try {
      Dio dio = Dio();
      final res = await dio.get("${Constant.apiUrl}/izin-dashboard");

      setState(() {
        approvedOrRejected =
            res.data["data"]["total_letters_approved_or_rejected"];
        pending = res.data["data"]["total_letters_pending"];
      });
    } catch (e) {
      debugPrint("ERROR LOAD DASHBOARD: $e");
    }
  }

  // ================================================================
  // LOAD IZIN LIST – safe version
  // ================================================================
  Future<void> loadIzinList() async {
    try {
      setState(() => loading = true);

      Dio dio = Dio();
      final res = await dio.get("${Constant.apiUrl}/izin-list");

      final rawList = (res.data["data"] as List?) ?? [];

      // ----- map safely ------------------------------------------------
      final List<Map<String, dynamic>> mapped = rawList.map((item) {
        final int? rawStatus = item["status"] as int?;
        final String statusText;
        switch (rawStatus) {
          case 0:
            statusText = "Diproses";
            break;
          case 1:
            statusText = "Diterima";
            break;
          case 2:
            statusText = "Ditolak";
            break;
          default:
            statusText = "Unknown";
        }

        return {
          "id": item["id"] ?? 0,
          "status": rawStatus ?? -1,          // numeric
          "status_text": statusText,          // human readable
          "date": item["date"]?.toString() ?? "",
          "full_name": item["full_name"]?.toString() ?? "",
          "position": item["position"]?.toString() ?? "",
          "department": item["department_name"]?.toString() ?? "",
        };
      }).toList();

      setState(() {
        izinData = mapped;
        loading = false;          // always executed
      });
    } catch (e, st) {
      debugPrint("ERROR LOAD IZIN LIST: $e\n$st");
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredData = selectedFilter == "All" 
        ? izinData 
        : izinData.where((item) => item["status"].toString() == selectedFilter).toList();

    return Scaffold(
      backgroundColor: Colors.white,

      // ==================== APPBAR ====================
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A8E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
        centerTitle: true,
        title: const Text(
          "HRIS Manajemen Izin",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.apartment, color: Colors.blue),
            ),
          )
        ],
      ),

      // ==================== BODY ====================
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---------------- HEADER CARD ----------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0DB4E5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // CARD IZIN
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people, size: 35),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$approvedOrRejected / $pending",
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const Text("Surat Izin Diproses",
                                style: TextStyle(fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // SLIDER CARD
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      children: [
                        izinCardWithIcon(
                          title: "Buat Template",
                          icon: Icons.add_circle_outline,
                          onTap: () => context.push("/admin/template/add"),
                        ),
                        izinCardWithIcon(
                          title: "List Template",
                          icon: Icons.list_alt,
                          onTap: () => context.push("/admin/template/list"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- UPDATE LIST ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Update List",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => showFilterSheet(context),
                    child: const Icon(Icons.filter_list, size: 26),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    children: filteredData.map((item) {
                      return izinListItem(
                        status: item["status_text"],
                        date: item["date"],
                        fullName: item["full_name"],
                        position: item["position"],
                        department: item["department"],
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // FILTER SHEET
  // ======================================================
  void showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              filterOption("All", "All"),
              filterOption("Diproses", "0"),
              filterOption("Diterima", "1"),
              filterOption("Ditolak", "2"),
            ],
          ),
        );
      },
    );
  }

  Widget filterOption(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: selectedFilter == value
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: () {
        setState(() => selectedFilter = value);
        Navigator.pop(context);
      },
    );
  }

  // ======================================================
  // ITEM IZIN
  // ======================================================
  Widget izinListItem({
    required String status,
    required String date,
    required String fullName,
    required String position,
    required String department,
  }) {
    Color color = status == "Diproses"
        ? Colors.orange
        : status == "Diterima"
            ? Colors.green
            : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue,
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  "$fullName\nJabatan: $position\nDepartment: $department",
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  // ======================================================
  // CARD TEMPLATE
  // ======================================================
  Widget izinCardWithIcon({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}