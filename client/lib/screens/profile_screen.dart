import 'package:client/models/employee_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/services/auth_service.dart';
import 'package:client/services/user_service.dart';
import 'package:client/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

class ProfileScreen extends StatelessWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(title: "Informasi Profil"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===================== HEADER BIRU =====================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: const BoxDecoration(
                color: Color(0xFF22A9D6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Informasi Profil",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Data diri pegawai",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Image.asset(
                    'assets/logoPbl.png',
                    width: 50,
                    height: 50,
                  ),
                ],
              ),
            ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: FutureBuilder(
          future: UserService.instance.getUser(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return profileSection(context, snapshot.data?.data);
          },
        ),
      ),
    );
  }

  String parseGender(String gender) {
    if (gender == "P") {
      return "Perempuan";
    }
    if (gender == "L") {
      return "Laki-Laki";
    }
    return "";
  }

  Widget profileSection(BuildContext context, UserModel<EmployeeModel>? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Data diri pegawai",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),

        const SizedBox(height: 16),

            // ===================== FORM BODY (PUTIH MELENGKUNG) =====================
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ProfileField(title: "Nama Panjang", value: "John"),
                    const _ProfileField(title: "Email", value: "JohnDoe@gmail.com"),
                    const _ProfileField(title: "Jenis Kelamin", value: "Pria"),
                    const _ProfileField(
                        title: "Alamat",
                        value: "Jalan Jakarta no. 10, Jakarta Indonesia"),
                    const _ProfileField(
                        title: "Jabatan", value: "Front-End Developer"),
                    const _ProfileField(
                        title: "Departemen", value: "Teknologi Informasi"),

                    // Jatah Cuti Warna Khusus
                    const _ProfileField(
                      title: "Jatah Cuti",
                      value: "4",
                      color: Color(0x66D79A20),
                    ),
        // Form fields
        _ProfileField(
          title: "Nama Awal",
          value: user?.employee?.firstName ?? "",
        ),
        _ProfileField(
          title: "Nama Akhir",
          value: user?.employee?.lastName ?? "",
        ),
        _ProfileField(title: "Email", value: user?.email ?? ""),
        _ProfileField(
          title: "Jenis Kelamin",
          value: parseGender(user?.employee?.gender ?? ""),
        ),
        _ProfileField(title: "Alamat", value: user?.employee?.address ?? ""),
        _ProfileField(title: "Jabatan", value: "Front-End Developer"),
        _ProfileField(title: "Departemen", value: "Teknologi Informasi"),

        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () async {
              await AuthService.instance.logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Logout",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ===================== CUSTOM FIELD =====================
class _ProfileField extends StatelessWidget {
  final String title;
  final String value;

  const _ProfileField({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),

        TextField(
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: color ?? const Color(0xfff1f1f1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: value,
            hintStyle: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}