import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class TermsScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final String? userRole; // 'patient' or 'nurse' to show specific tab

  const TermsScreen({
    super.key,
    this.onClose,
    this.userRole,
  });

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _patientAgreed = false;
  bool _nurseAgreed = false;
  bool _loading = true;

  static const String _kPatientKey = 'agreed_patient';
  static const String _kNurseKey = 'agreed_nurse';

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.userRole == 'nurse' ? 1 : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
    _loadConsent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConsent() async {
    final prefs = await SharedPreferences.getInstance();
    _patientAgreed = prefs.getBool(_kPatientKey) ?? false;
    _nurseAgreed = prefs.getBool(_kNurseKey) ?? false;
    setState(() => _loading = false);
  }

  Future<void> _saveConsent({required bool patient, required bool nurse}) async {
    final prefs = await SharedPreferences.getInstance();
    if (patient) await prefs.setBool(_kPatientKey, true);
    if (nurse) await prefs.setBool(_kNurseKey, true);
    setState(() {
      if (patient) _patientAgreed = true;
      if (nurse) _nurseAgreed = true;
    });
  }

  Future<void> _clearConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPatientKey);
    await prefs.remove(_kNurseKey);
    setState(() {
      _patientAgreed = false;
      _nurseAgreed = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Consent cleared'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleAgree(String role) {
    if (role == "patient") {
      _saveConsent(patient: true, nurse: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Patient terms agreed'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    if (role == "nurse") {
      _saveConsent(patient: false, nurse: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nurse terms agreed'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s16, bottom: AppSpacing.s8),
      child: Text(
        title,
        style: AppTypography.h3(context).copyWith(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: AppSpacing.s8),
            child: Icon(
              Icons.circle,
              size: 6,
              color: AppColors.primaryBlue,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body2(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _commonTerms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.s24),
        Divider(color: AppColors.primaryBlue.withOpacity(0.3)),
        const SizedBox(height: AppSpacing.s16),
        _sectionTitle("Common Terms (Applicable to Both)"),
        _bullet("Acceptance: By using the app, you agree to these Terms & Conditions and the Privacy Policy."),
        _bullet("Security: We use standard security measures, but no digital system is 100% risk-free."),
        _bullet("Account Suspension: Accounts may be limited or removed for misuse, violation of guidelines, or unauthorized access."),
        _bullet("Updates: Terms may be updated at any time. Continued use means you accept the updated terms."),
      ],
    );
  }

  Widget _patientTerms() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s24),
      children: [
          Text(
            "Terms & Conditions – Patients",
            style: AppTypography.h2(context).copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          _sectionTitle("1. Usage"),
          _bullet("This app is for monitoring your health/IV drip and communicating with nurses."),
          _bullet("This app is not for emergencies. For urgent issues, contact your hospital immediately."),
          _sectionTitle("2. Information Accuracy"),
          _bullet("You must provide correct personal and medical information."),
          _bullet("Do not share your login details with anyone."),
          _sectionTitle("3. Limitations"),
          _bullet("The app does not diagnose, treat, or replace medical care."),
          _bullet("Always follow the instructions of your healthcare provider."),
          _sectionTitle("4. Data & Privacy"),
          _bullet("Your health data will be shared only with authorized nurses/doctors for your care."),
          _bullet("We use secure methods to store and protect your data."),
          _sectionTitle("5. Liability"),
          _bullet("We are not responsible for incorrect data entered by the patient, network issues, or delayed alerts."),
          _commonTerms(),
          const SizedBox(height: AppSpacing.s24),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _patientAgreed ? AppColors.success : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _patientAgreed,
                  onChanged: (v) {
                    if (v == true) _handleAgree("patient");
                  },
                  activeColor: AppColors.success,
                ),
                Expanded(
                  child: Text(
                    "I agree to the Patient Terms & Conditions",
                    style: AppTypography.body1(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _patientAgreed
                      ? null
                      : () => _handleAgree("patient"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.success.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_patientAgreed ? "Agreed" : "Agree"),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
      ],
    );
  }

  Widget _nurseTerms() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s24),
      children: [
          Text(
            "Terms & Conditions – Nurses",
            style: AppTypography.h2(context).copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          _sectionTitle("1. Eligibility"),
          _bullet("Only authorized nurses or healthcare staff may use this app."),
          _sectionTitle("2. Professional Use"),
          _bullet("Use the app only for patient monitoring and clinical workflow."),
          _bullet("Verify all app data before making medical decisions."),
          _sectionTitle("3. Patient Data Handling"),
          _bullet("Maintain confidentiality and follow hospital data policies."),
          _bullet("Do not share, export, or misuse patient information."),
          _sectionTitle("4. Responsibilities"),
          _bullet("Ensure the accuracy of the medical data you update."),
          _bullet("Do not rely solely on app alerts—confirm with physical checks when needed."),
          _sectionTitle("5. Prohibited Actions"),
          _bullet("Sharing login details"),
          _bullet("Entering false or misleading data"),
          _bullet("Using the app outside assigned clinical scope"),
          _sectionTitle("6. Liability"),
          _bullet("The app supports your work but does not replace clinical judgement."),
          _bullet("We are not responsible for errors caused by incorrect entries or connectivity issues."),
          _commonTerms(),
          const SizedBox(height: AppSpacing.s24),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _nurseAgreed ? AppColors.primaryBlue : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _nurseAgreed,
                  onChanged: (v) {
                    if (v == true) _handleAgree("nurse");
                  },
                  activeColor: AppColors.primaryBlue,
                ),
                Expanded(
                  child: Text(
                    "I agree to the Nurse Terms & Conditions",
                    style: AppTypography.body1(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _nurseAgreed
                      ? null
                      : () => _handleAgree("nurse"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_nurseAgreed ? "Agreed" : "Agree"),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Terms & Conditions",
          style: AppTypography.h3(context).copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(text: "Patient"),
            Tab(text: "Nurse"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearConsent,
            tooltip: "Clear saved consent",
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              widget.onClose?.call();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _patientTerms(),
                _nurseTerms(),
              ],
            ),
    );
  }
}

