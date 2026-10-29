import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../market/market_screen.dart';
import '../dashboard/dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  final bool isUpgradingFromIndividual;

  const SignupScreen({super.key, this.isUpgradingFromIndividual = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 1; // 1: Form, 2: Phone OTP Verify
  String _accountType = 'INDIVIDUAL';

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  // Business Fields
  final _bizNameController = TextEditingController();
  String _bizCategory = 'Food & Bakery';
  String _estateId = 'est_citiview';
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 21, minute: 0);

  // OTP
  final _otpController = TextEditingController();
  String _generatedCodeForBanner = '';
  bool _showSmsBanner = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<Map<String, String>> _estates = [
    {'id': 'est_citiview', 'name': 'Citi-View Estate'},
    {'id': 'est_warewa', 'name': 'Warewa'},
    {'id': 'est_arepo', 'name': 'Arepo'},
    {'id': 'est_opic', 'name': 'Opic'},
    {'id': 'est_ibafo', 'name': 'Ibafo'},
  ];

  final List<String> _categories = [
    'Food & Bakery',
    'Electronics',
    'Fashion & Beauty',
    'Home & Laundry Services',
    'Supermarket',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isUpgradingFromIndividual || AuthService.currentUser != null) {
      _accountType = 'BUSINESS';
      final u = AuthService.currentUser;
      if (u != null) {
        _fullNameController.text = u.fullName;
        _phoneController.text = u.phoneNumber;
        _estateId = u.estateId;
      }
    }
  }

  void _handleSendOtp() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _passwordConfirmController.text;

    if (fullName.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required personal details')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Passwords do not match. Please ensure both passwords are identical.')),
      );
      return;
    }

    if (_accountType == 'BUSINESS' && _bizNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your business / brand name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'accountType': _accountType,
        'fullName': fullName,
        'phoneNumber': phone,
        'password': password,
        'estateId': _estateId,
        'businessName': _bizNameController.text.trim().toUpperCase(),
        'businessCategory': _bizCategory,
        'openTime': '${_openTime.hour.toString().padLeft(2, '0')}:${_openTime.minute.toString().padLeft(2, '0')}',
        'closeTime': '${_closeTime.hour.toString().padLeft(2, '0')}:${_closeTime.minute.toString().padLeft(2, '0')}',
      };

      final code = await ApiService.requestRegisterOtp(payload);

      setState(() {
        _generatedCodeForBanner = code;
        _showSmsBanner = true;
        _currentStep = 2;
        _otpController.clear(); // Field remains blank: user inputs manually
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    final phone = _phoneController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit verification code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.verifyRegisterOtp(
        phoneNumber: phone,
        code: code,
        accountType: _accountType,
      );

      final user = res['user'];
      final store = res['store'];

      await AuthService.saveSession(user: user, store: store);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🎉 Phone verified successfully! Welcome to Halljar, ${user.fullName}!')),
      );

      if (_accountType == 'BUSINESS' || store != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MarketScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBiz = _accountType == 'BUSINESS';
    final isUpgrading = widget.isUpgradingFromIndividual || AuthService.currentUser != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back to Marketplace Button at top
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF475569)),
                          label: Text(
                            isUpgrading ? 'Back to Marketplace' : 'Back to Sign In',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Community Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(radius: 3, backgroundColor: Color(0xFF22C55E)),
                              SizedBox(width: 6),
                              Text(
                                'JOIN HALLJAR COMMUNITY',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        isUpgrading ? 'Register Business & Open Store' : 'Create your Account',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUpgrading
                            ? 'Set up your merchant profile to sell to estate residents on Halljar.'
                            : 'Access verified stores, order hot food & essentials, or sell to local estate residents.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),

                      // Step Stepper Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepChip('1', 'Account Setup', _currentStep == 1, _currentStep > 1),
                          Container(width: 30, height: 2, color: _currentStep > 1 ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
                          _buildStepChip('2', 'Phone Verify', _currentStep == 2, false),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_currentStep == 1) ...[
                        // Account Selector Tabs (HIDDEN if upgrading from individual account)
                        if (!isUpgrading) ...[
                          const Text(
                            'SELECT ACCOUNT TYPE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.6),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _accountType = 'INDIVIDUAL'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: !isBiz ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: !isBiz ? const Color(0xFF0F766E) : Colors.transparent),
                                        boxShadow: !isBiz ? [const BoxShadow(color: Color(0x10000000), blurRadius: 6)] : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('👤', style: TextStyle(fontSize: 18)),
                                          Text('Shopper / Resident', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: !isBiz ? const Color(0xFF0F766E) : Colors.black87)),
                                          const Text('Browse, buy & order in estates', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _accountType = 'BUSINESS'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isBiz ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isBiz ? const Color(0xFF0F766E) : Colors.transparent),
                                        boxShadow: isBiz ? [const BoxShadow(color: Color(0x10000000), blurRadius: 6)] : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('🏬', style: TextStyle(fontSize: 18)),
                                          Text('Merchant / Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isBiz ? const Color(0xFF0F766E) : Colors.black87)),
                                          const Text('Sell inventory & receive orders', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Personal & Contact Info Card
                        _buildSectionBox(
                          title: 'Personal & Contact Info',
                          icon: Icons.person_outline,
                          children: [
                            Text(
                              isBiz ? 'Business Owner / Manager Name' : 'Your Full Name',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _fullNameController,
                              style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'e.g. Samuel Adekunle',
                                prefixIcon: const Icon(Icons.person, size: 18),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 12),

                            const Text(
                              'Phone Number (WhatsApp Active)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: '080 1234 5678',
                                prefixIcon: const Icon(Icons.phone, size: 18),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const Text('Used for order alerts & instant phone verification code.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            const SizedBox(height: 12),

                            // Primary Estate Location: Location icon beside label, pure black text
                            const Row(
                              children: [
                                Text('📍', style: TextStyle(fontSize: 15)),
                                SizedBox(width: 4),
                                Text(
                                  'Primary Estate / Location',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _estateId,
                              style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: _estates.map((e) => DropdownMenuItem(value: e['id'], child: Text(e['name']!, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)))).toList(),
                              onChanged: (val) => setState(() => _estateId = val ?? 'est_citiview'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Store & Vendor Details (When Business is Selected)
                        if (isBiz) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF0FDF4), Colors.white]),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('STORE & VENDOR DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Merchant Account', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                const Text('Business / Brand Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _bizNameController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w800),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. AMAKA BAKES OR DEJI TECH LAB',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const Text('Will be displayed in UPPERCASE to buyers.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                const SizedBox(height: 12),

                                // Business Category without emoji, pure black text
                                const Text('Business Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _bizCategory,
                                  style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)))).toList(),
                                  onChanged: (val) => setState(() => _bizCategory = val ?? 'Food & Bakery'),
                                ),
                                const SizedBox(height: 12),

                                // Opening & Closing Hours without emoji, pure black text
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Opening Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () async {
                                              final t = await showTimePicker(context: context, initialTime: _openTime);
                                              if (t != null) setState(() => _openTime = t);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(10)),
                                              child: Text(_openTime.format(context), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Closing Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () async {
                                              final t = await showTimePicker(context: context, initialTime: _closeTime);
                                              if (t != null) setState(() => _closeTime = t);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(10)),
                                              child: Text(_closeTime.format(context), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Security Section: Password & Confirm Password with Eye Toggles
                        _buildSectionBox(
                          title: 'Security',
                          icon: Icons.lock_outline,
                          children: [
                            const Text('Create Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Create a password',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixIcon: IconButton(
                                  icon: Text(_obscurePassword ? '👁️' : '🙈', style: const TextStyle(fontSize: 18)),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            const Text('Confirm Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _passwordConfirmController,
                              obscureText: _obscureConfirmPassword,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Re-enter your password',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: _passwordConfirmController.text.isEmpty
                                        ? const Color(0xFFCBD5E1)
                                        : (_passwordController.text == _passwordConfirmController.text ? const Color(0xFF22C55E) : const Color(0xFFE11D48)),
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Text(_obscureConfirmPassword ? '👁️' : '🙈', style: const TextStyle(fontSize: 18)),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),
                            ),
                            if (_passwordConfirmController.text.isNotEmpty && _passwordController.text != _passwordConfirmController.text)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('⚠️ Passwords do not match', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE11D48))),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('📲 Send Verification Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        ),

                        if (isUpgrading) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('← Cancel & Return to Marketplace', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                            ),
                          ),
                        ],
                      ] else ...[
                        // Step 2: OTP Verification Screen
                        const Center(child: Text('🛡️', style: TextStyle(fontSize: 36))),
                        const SizedBox(height: 8),
                        const Text('Verify Phone Number', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE))),
                          child: Text(
                            '📲 A 6-digit confirmation code has been dispatched via SMS to ${_phoneController.text.trim()}.\nPlease enter the code below to activate your account.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Enter 6-Digit Code', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _otpController,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 8, color: Color(0xFF0F766E)),
                          decoration: InputDecoration(
                            hintText: '••••••',
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('✅ Verify Code & Activate Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 12),

                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _currentStep = 1),
                            child: const Text('← Change phone number or edit details', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Top Floating Simulated SMS Notification Banner
            if (_showSmsBanner)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF0F172A),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SMS • ${_phoneController.text.trim()} • Just Now', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                              Text('Halljar Security: Your verification code is $_generatedCodeForBanner (valid 10 mins)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 16),
                          onPressed: () => setState(() => _showSmsBanner = false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepChip(String num, String title, bool isActive, bool isDone) {
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: isDone ? const Color(0xFF16A34A) : (isActive ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1)),
          child: Text(
            isDone ? '✓' : num,
            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 4),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? const Color(0xFF0F766E) : const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildSectionBox({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF475569)),
              const SizedBox(width: 6),
              Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
