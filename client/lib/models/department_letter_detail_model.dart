class DepartmentDetailModel {
  final String departmentName;
  final int totalEmployees;
  final int employeesWithLeave;
  final List<EmployeeLeaveDetail> employees;

  DepartmentDetailModel({
    required this.departmentName,
    required this.totalEmployees,
    required this.employeesWithLeave,
    required this.employees,
  });

  factory DepartmentDetailModel.fromJson(Map<String, dynamic> json) {
    // Parse employees dari all_letters
    final employeesList = (json['employees'] as List?)
            ?.map((e) => EmployeeLeaveDetail.fromJson(e))
            .toList() ??
        [];

    return DepartmentDetailModel(
      departmentName: json['department_name'] ?? '',
      totalEmployees: json['total_employees'] ?? 0,
      employeesWithLeave: json['employees_with_leave'] ?? 0,
      employees: employeesList,
    );
  }
}

class EmployeeLeaveDetail {
  final int employeeId;
  final String employeeName;
  final String departmentName;
  final int totalApprovedLetters;
  final List<LeaveTypeWithDate> leaveTypes;

  EmployeeLeaveDetail({
    required this.employeeId,
    required this.employeeName,
    required this.departmentName,
    required this.totalApprovedLetters,
    required this.leaveTypes,
  });

  factory EmployeeLeaveDetail.fromJson(Map<String, dynamic> json) {
    // Parse cuti_list dan cuti_dates
    final cutiList = (json['cuti_list'] as String?)?.split(', ') ?? [];
    final cutiDates = (json['cuti_dates'] as String?)?.split(',') ?? [];

    List<LeaveTypeWithDate> leaveTypes = [];
    for (int i = 0; i < cutiList.length; i++) {
      leaveTypes.add(LeaveTypeWithDate(
        name: cutiList[i],
        date: i < cutiDates.length ? cutiDates[i] : '-',
      ));
    }

    return EmployeeLeaveDetail(
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'] ?? '',
      departmentName: json['department_name'] ?? '',
      totalApprovedLetters: json['total_approved_letters'] ?? 0,
      leaveTypes: leaveTypes,
    );
  }
}

class LeaveTypeWithDate {
  final String name;
  final String date;

  LeaveTypeWithDate({
    required this.name,
    required this.date,
  });
}