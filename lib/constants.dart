// constants.dart

const String apiDomain = 'https://macksonsmobi.synnexcloudpos.com';
const String verifyCompanyEndpoint = '/verifyCompany.php';
const String loginEndpoint = '/login.php';
const String addAttendanceEndpoint = '/add_attendance.php';
const String assignShiftsEndpoint = '/assign_shifts.php';
const String attendanceEndpoint = '/attendance.php';
const String attendanceReportEndpoint = '/attendance_report.php';
const String formerEmployeesCountEndpoint = '/former_employees_count.php';
const String loanCountEndpoint = '/loan_count.php';
const String leaveCountEndpoint = '/leave_count.php';
const String departmentEndpoint = '/department.php';
const String designationEndpoint = '/designation.php';
const String disciplinaryEndpoint = '/Disciplinary.php';
const String earnLeaveEndpoint = '/earn_leave.php';
const String empSalaryEndpoint = '/emp_salary.php';
const String employeeShiftsEndpoint = '/employee_shifts.php';
const String employeeEndpoint = '/employee.php';
const String holidaySectionEndpoint = '/holiday_section.php';
const String holidayEndpoint = '/holiday.php';
const String inactiveUsersEndpoint = '/inactive_users.php';
const String leaveApplicationEndpoint = '/leave_application.php';
const String leaveReportEndpoint = '/leave_report.php';
const String leaveTypeEndpoint = '/leave_type.php';
const String loanEndpoint = '/loan.php';
const String logoutEndpoint = '/logout.php';
const String noticeEndpoint = '/notice.php';
const String paySalaryEndpoint = '/pay_salary.php';
const String fetchPendingLeavesEndpoint = '/fetch_pending_leaves.php';
const String reviewLeaveRequestEndpoint = '/review_leave_request.php';
const String updateLeaveStatusEndpoint = '/update_leave_status.php';
const String shiftsEndpoint = '/shifts.php';
const String updateShiftEndpoint = '/update_shift.php';
const String deleteShiftEndpoint = '/delete_shift';
const String addShiftsEndpoint = '/add_shifts.php';
const String toDoTaskEndpoint = '/to-do-task.php';
const String bankAccountEndpoint = '/bank_account.php';
const String educationEndpoint = '/education.php';
const String updateEducationEndpoint = '/update_education.php';
const String experienceEndpoint = '/experience.php';
const String updateExperienceEndpoint = '/update_experience.php';
const String personalInfoEndpoint = '/personal_info.php';
const String updatePersonalInfoEndpoint = '/update_personal_info.php';
const String fetchPendingAttendanceEndpoint = "/fetch_pending_attendance.php";
const String updateAttendanceStatusEndpoint = "/update_attendance_status.php";
const String leaveSummaryEndpoint = "/leave_summary.php";



String getApiUrl(String endpoint) {
  return '$apiDomain$endpoint';
}
