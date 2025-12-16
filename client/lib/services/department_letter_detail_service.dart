import 'dart:io';
import 'package:client/models/department_letter_detail_model.dart';
import 'package:client/services/base_service.dart';
import 'package:client/utils/api_wrapper.dart';
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class DepartmentLetterDetailService extends BaseService {
  DepartmentLetterDetailService._();
  static final DepartmentLetterDetailService instance = DepartmentLetterDetailService._();

  /// Get department detail with employees and their leaves
  Future<ApiResponse<DepartmentDetailModel>> getDepartmentDetail({
    required String departmentName,
    int? month,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null && month >= 1 && month <= 12) {
        queryParams['month'] = month;
      }

      final res = await dio.get(
        '/izin-dashboard',
        queryParameters: queryParams,
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'];

        final allLetters = (data['all_letters'] as List?)
                ?.where((e) => e['department_name'] == departmentName)
                .toList() ??
            [];

        final departments = data['departments'] as List?;
        final deptData = departments?.firstWhere(
          (d) => d['name'] == departmentName,
          orElse: () => {'count': '0 / 0'},
        );

        final countParts = (deptData?['count'] as String?)?.split(' / ') ?? ['0', '0'];
        final employeesWithLeave = int.tryParse(countParts[0]) ?? 0;
        final totalEmployees = int.tryParse(countParts[1]) ?? 0;

        final departmentDetail = DepartmentDetailModel(
          departmentName: departmentName,
          totalEmployees: totalEmployees,
          employeesWithLeave: employeesWithLeave,
          employees: allLetters
              .map((e) => EmployeeLeaveDetail.fromJson(e))
              .toList(),
        );

        return ApiResponse<DepartmentDetailModel>(
          message: "Berhasil memuat detail departemen",
          success: true,
          data: departmentDetail,
        );
      }

      return ApiResponse<DepartmentDetailModel>(
        message: res.data['message'] ?? "Gagal memuat data",
        success: false,
        data: null,
      );
    } catch (e) {
      return ApiResponse<DepartmentDetailModel>(
        message: e.toString(),
        success: false,
        data: null,
      );
    }
  }

  /// ✅ NEW: Generate and export Excel file
  Future<ApiResponse<String>> exportDepartmentExcel({
    required String departmentName,
    required List<EmployeeLeaveDetail> employees,
  }) async {
    try {
      if (employees.isEmpty) {
        return ApiResponse<String>(
          message: "Tidak ada data untuk diekspor",
          success: false,
          data: null,
        );
      }

      // ✅ Create Excel file
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // ✅ Set column widths
      sheet.setColWidth(0, 5);   // No
      sheet.setColWidth(1, 25);  // Nama
      sheet.setColWidth(2, 20);  // Total Cuti
      sheet.setColWidth(3, 50);  // Jenis Cuti

      // ✅ Header styling
      final headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('#00A8E8'),
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // ✅ Header row
      final headers = ['No', 'Nama Karyawan', 'Total Cuti Disetujui', 'Jenis Cuti & Tanggal'];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // ✅ Data rows
      final dataStyle = CellStyle(
        fontSize: 11,
        verticalAlign: VerticalAlign.Center,
      );

      for (int i = 0; i < employees.length; i++) {
        final employee = employees[i];
        final rowIndex = i + 1;

        // No
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        cell.value = IntCellValue(i + 1);
        cell.cellStyle = dataStyle;

        // Nama Karyawan
        cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
        cell.value = TextCellValue(employee.employeeName);
        cell.cellStyle = dataStyle;

        // Total Cuti Disetujui
        cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
        cell.value = IntCellValue(employee.totalApprovedLetters);
        cell.cellStyle = dataStyle;

        // Jenis Cuti + Tanggal
        final jenisCuti = employee.leaveTypes
            .map((lt) => "${lt.name} (${lt.date})")
            .join(", ");
        cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
        cell.value = TextCellValue(jenisCuti);
        cell.cellStyle = dataStyle;
      }

      // ✅ Save file
      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory("/storage/emulated/0/Download");
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        return ApiResponse<String>(
          message: "Tidak dapat menemukan direktori penyimpanan",
          success: false,
          data: null,
        );
      }

      final fileName = "Laporan_$departmentName.xlsx";
      final filePath = "${directory.path}/$fileName";

      final fileBytes = excel.encode();
      if (fileBytes == null) {
        return ApiResponse<String>(
          message: "Gagal menggenerate file Excel",
          success: false,
          data: null,
        );
      }

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      return ApiResponse<String>(
        message: "File berhasil disimpan di: $filePath",
        success: true,
        data: filePath,
      );
    } catch (e) {
      return ApiResponse<String>(
        message: "Error: $e",
        success: false,
        data: null,
      );
    }
  }

  /// ✅ Open Excel file
  Future<void> openExcelFile(String filePath) async {
    try {
      await OpenFilex.open(filePath);
    } catch (e) {
      throw Exception("Gagal membuka file: $e");
    }
  }
}

extension on Sheet {
  void setColWidth(int i, int j) {}
}