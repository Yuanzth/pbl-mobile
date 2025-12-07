import 'dart:io';
import 'package:client/models/employee_model.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart';

class ExcelService {
  static final ExcelService instance = ExcelService._internal();
  ExcelService._internal();

  /// Export employees to Excel file
  Future<String?> exportEmployees(List<EmployeeModel> employees) async {
    try {
      // 1. Create Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Daftar Karyawan'];

      // 2. Style untuk header
      CellStyle headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#1B7FA8'),
        fontColorHex: ExcelColor.white,
        bold: true,
        fontSize: 12,
      );

      // 3. Header columns
      List<String> headers = [
        'No',
        'Nama Lengkap',
        'Email',
        'Gender',
        'Alamat',
        'Status',
        'Posisi',
        'Departemen',
        'Bergabung',
      ];

      // 4. Insert header
      for (var i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // 5. Insert data
      for (var i = 0; i < employees.length; i++) {
        var emp = employees[i];
        var row = i + 1;

        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = IntCellValue(
          i + 1,
        );

        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(
          emp.fullName,
        );

        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(
          emp.user?.email ?? '-',
        );

        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = TextCellValue(
          _capitalizeGender(emp.gender),
        );

        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(
          emp.address,
        );

        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = TextCellValue(
          _capitalizeStatus(emp.employmentStatus),
        );

        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = TextCellValue(
          emp.position?.name ?? '-',
        );

        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
            .value = TextCellValue(
          emp.department?.name ?? '-',
        );

        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
            .value = TextCellValue(
          _formatDate(emp.createdAt),
        );
      }

      // 6. Auto-size columns
      for (var i = 0; i < headers.length; i++) {
        sheetObject.setColumnWidth(i, 20);
      }

      // 7. Save file
      var fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      // 8. Get file path with fallback
      String? filePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Daftar_Karyawan_$timestamp.xlsx';

      if (Platform.isAndroid) {
        // ✅ TRY MULTIPLE LOCATIONS
        try {
          // Try 1: Request storage permission
          var status = await Permission.storage.status;
          debugPrint('Storage permission status: $status');

          if (!status.isGranted) {
            status = await Permission.storage.request();
            debugPrint('After request: $status');
          }

          // Try 2: manageExternalStorage for Android 11+
          if (!status.isGranted) {
            var manageStatus = await Permission.manageExternalStorage.status;
            debugPrint('Manage storage status: $manageStatus');

            if (!manageStatus.isGranted) {
              manageStatus = await Permission.manageExternalStorage.request();
              debugPrint('After manage request: $manageStatus');
            }

            if (manageStatus.isGranted) {
              status = PermissionStatus.granted;
            }
          }

          // ✅ FALLBACK: Use app directory if permission denied
          if (status.isGranted || status.isLimited) {
            // Try Download folder
            final downloadDir = Directory('/storage/emulated/0/Download');
            if (await downloadDir.exists()) {
              filePath = '${downloadDir.path}/$fileName';
              debugPrint('✅ Using Download folder: $filePath');
            }
          }

          // ✅ FALLBACK 2: Use Documents folder
          if (filePath == null) {
            final docsDir = Directory('/storage/emulated/0/Documents');
            if (!await docsDir.exists()) {
              await docsDir.create(recursive: true);
            }
            filePath = '${docsDir.path}/$fileName';
            debugPrint('✅ Using Documents folder: $filePath');
          }
        } catch (e) {
          debugPrint('⚠️ External storage failed: $e');
        }

        // ✅ FALLBACK 3: Use app internal storage
        if (filePath == null) {
          final appDir = await getApplicationDocumentsDirectory();
          filePath = '${appDir.path}/$fileName';
          debugPrint('✅ Using app directory: $filePath');
        }
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$fileName';
      } else {
        final directory = await getDownloadsDirectory();
        filePath = '${directory!.path}/$fileName';
      }

      // 9. Write file
      final file = File(filePath);
      await file.writeAsBytes(fileBytes, flush: true);

      debugPrint('✅ Excel file saved: $filePath');
      debugPrint('✅ File exists: ${await file.exists()}');
      debugPrint('✅ File size: ${await file.length()} bytes');

      return filePath;
    } catch (e, stackTrace) {
      debugPrint('❌ Error exporting Excel: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Open Excel file after export
  Future<void> openFile(String filePath) async {
    try {
      debugPrint('Opening file: $filePath');
      final result = await OpenFilex.open(filePath);
      debugPrint('Open result: ${result.type} - ${result.message}');
    } catch (e) {
      debugPrint('❌ Error opening file: $e');
    }
  }

  String _capitalizeGender(String gender) {
    if (gender.toLowerCase() == 'l') return 'Laki-laki';
    if (gender.toLowerCase() == 'p') return 'Perempuan';
    return gender;
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return '-';
    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return date;
    }
  }
}
