import 'dart:async';
import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sudokulegend/Models/state%20management/profile_provider.dart';
import 'package:sudokulegend/Widgets/connectivity_service.dart';
import 'package:sudokulegend/Widgets/helper.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  PROFILE PAGE
// ══════════════════════════════════════════════════════════════════════════════

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  // Controllers mirror provider state
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  bool _isOnline = ConnectivityService.instance.isOnline;
  StreamSubscription? _connectivitySubscription;

  // Which fields are currently unlocked for editing
  final Set<String> _unlocked = {};

  Country? _selectedCountry;
  bool _isSaving = false;

  late final AnimationController _avatarPulse;

  // Countries list — extend as needed
  static const _countries = [
    'Nigeria',
    'Ghana',
    'Kenya',
    'South Africa',
    'United Kingdom',
    'United States',
    'Canada',
    'Germany',
    'France',
    'India',
    'Brazil',
    'Australia',
    'Japan',
    'China',
    'Egypt',
  ];

  @override
  void initState() {
    super.initState();
    _avatarPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.96,
      upperBound: 1.04,
    )..repeat(reverse: true);

    final profile = ref.read(profileProvider);
    _nameCtrl = TextEditingController(text: profile.name);
    _usernameCtrl = TextEditingController(text: profile.username);
    _emailCtrl = TextEditingController(text: profile.email);
    _selectedCountry = profile.country;
    ConnectivityService.instance.initialize();
    _setupConnectivity();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _avatarPulse.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }



  void _setupConnectivity() async {
    _connectivitySubscription = ConnectivityService.instance.connectionStream
        .listen((online) {
          if (mounted) setState(() => _isOnline = online);
        });
  }

  void _toggleField(String field) {
    setState(() {
      if (_unlocked.contains(field)) {
        _unlocked.remove(field);
      } else {
        _unlocked.add(field);
      }
    });
  }

  bool _isUnlocked(String field) => _unlocked.contains(field);

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!_isOnline && mounted) {
      showSnackBar(
        context: context,
        message: "No internet Connection!",
        bgColor: Colors.red,
        fgColor: Colors.white,
      );
    }
    ref.read(profileProvider.notifier).updateAvatar(File(picked.path));
  }

  Future<void> _save() async {
    if (!_isOnline) {
      showSnackBar(
        context: context,
        message: "No internet Connection!",
        bgColor: Colors.red,
        fgColor: Colors.white,
      );
    } else {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    await ref
        .read(profileProvider.notifier)
        .updateProfile(
          name: _nameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          country: _selectedCountry,
        );

    // Lock all fields after save
    setState(() {
      _unlocked.clear();
      _isSaving = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated!'),
        backgroundColor: const Color(0xFF3D5A80),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A2B3C),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A2B3C),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar section ───────────────────────────────────
            Center(
              child: _AvatarSection(profile: profile, onTap: _pickAvatar),
            ),

            const SizedBox(height: 36),

            // ── Fields ───────────────────────────────────────────
            _FieldGroup(
              label: 'Name',
              controller: _nameCtrl,
              fieldKey: 'name',
              isUnlocked: _isUnlocked('name'),
              onPencilTap: () => _toggleField('name'),
              icon: Icons.person_outline_rounded,
            ),

            const SizedBox(height: 20),

            _FieldGroup(
              label: 'Username',
              controller: _usernameCtrl,
              fieldKey: 'username',
              isUnlocked: _isUnlocked('username'),
              onPencilTap: () => _toggleField('username'),
              icon: Icons.alternate_email_rounded,
            ),

            const SizedBox(height: 20),

            _FieldGroup(
              label: 'Email',
              controller: _emailCtrl,
              fieldKey: 'email',
              isUnlocked: _isUnlocked('email'),
              onPencilTap: () => _toggleField('email'),
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 20),

            // ── Country picker ─────────────────────────────────
            _CountryField(
              selectedCountry: _selectedCountry,
              countries: _countries,
              isUnlocked: _isUnlocked('country'),
              onPencilTap: () => _toggleField('country'),
              onChanged: (v) => {setState(() => _selectedCountry = v)},
            ),

            const SizedBox(height: 40),

            // ── Update button ────────────────────────────────────
            _UpdateButton(isSaving: _isSaving, onTap: _save),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  AVATAR SECTION
// ══════════════════════════════════════════════════════════════════════════════

class _AvatarSection extends StatelessWidget {
  final ProfileState profile;
  final VoidCallback onTap;

  const _AvatarSection({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Glow ring
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3D5A80), Color(0xFF7BA7CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3D5A80).withOpacity(0.30),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF2F6FB),
                  ),
                  child: ClipOval(
                    child: profile.localAvatar != null
                        ? Image.file(
                            profile.localAvatar!,
                            fit: BoxFit.cover,
                            width: 94,
                            height: 94,
                          )
                        : profile.avatarUrl != null
                        ? Image.network(
                            profile.avatarUrl!,
                            fit: BoxFit.cover,
                            width: 94,
                            height: 94,
                            errorBuilder: (context, error, stackTrace) =>
                                _PlaceholderAvatar(name: profile.name),
                          )
                        : Image.asset(
                            'assets/images/403024_avatar_boy_male_user_young_icon.png',
                          ),
                  ),
                ),
              ),

              // Plus badge
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D5A80),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF2F6FB),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3D5A80).withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Edit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D5A80),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  final String name;
  const _PlaceholderAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 94,
      height: 94,
      color: const Color(0xFFD0E8FF),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3D5A80),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FIELD GROUP  — label + locked/unlocked text field + pencil toggle
// ══════════════════════════════════════════════════════════════════════════════

class _FieldGroup extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String fieldKey;
  final bool isUnlocked;
  final VoidCallback onPencilTap;
  final IconData icon;
  final TextInputType keyboardType;

  const _FieldGroup({
    required this.label,
    required this.controller,
    required this.fieldKey,
    required this.isUnlocked,
    required this.onPencilTap,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B3C),
              letterSpacing: 0.2,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnlocked ? const Color(0xFF3D5A80) : Colors.grey[100]!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnlocked
                    ? const Color(0xFF3D5A80).withOpacity(0.10)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isUnlocked ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Leading icon
              if (isUnlocked)
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isUnlocked
                        ? const Color(0xFF3D5A80)
                        : Colors.grey[400],
                  ),
                ),
              // Text field
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: isUnlocked,
                  keyboardType: keyboardType,
                  onTapOutside: (event) {
                    onPencilTap();
                    Focus.of(context).unfocus();
                  },
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isUnlocked
                        ? const Color(0xFF1A2B3C)
                        : Colors.grey[500],
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
              // Pencil toggle
              GestureDetector(
                onTap: onPencilTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 14, 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isUnlocked
                          ? Icons.check_circle_rounded
                          : Icons.edit_outlined,
                      key: ValueKey(isUnlocked),
                      size: 20,
                      color: isUnlocked
                          ? const Color(0xFF3D5A80)
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  COUNTRY DROPDOWN FIELD
// ══════════════════════════════════════════════════════════════════════════════

class _CountryField extends StatelessWidget {
  final Country? selectedCountry;
  final List<String> countries;
  final bool isUnlocked;
  final VoidCallback onPencilTap;
  final Function(Country) onChanged;

  const _CountryField({
    required this.selectedCountry,
    required this.countries,
    required this.isUnlocked,
    required this.onPencilTap,
    required this.onChanged,
  });

  void showCountryPickerBottomSheet(BuildContext context) {
    showCountryPicker(context: context, onSelect: (value) => onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Country',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B3C),
              letterSpacing: 0.2,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnlocked ? const Color(0xFF3D5A80) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnlocked
                    ? const Color(0xFF3D5A80).withOpacity(0.10)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isUnlocked ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => showCountryPickerBottomSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedCountry != null
                              ? selectedCountry!.name
                              : "Select Country",
                          style: TextStyle(
                            fontSize: 16,
                            color: !isUnlocked
                                ? Colors.grey
                                : const Color(0xFF3D5A80),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isUnlocked ? Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey(isUnlocked),
                              size: 20,
                              color: isUnlocked
                                  ? const Color(0xFF3D5A80)
                                  : Colors.grey[400],
                            ) : Image.asset("assets/icons/Direction.png", key: ValueKey(isUnlocked), errorBuilder: (context, error, stackTrace) => Icon(Icons.keyboard_arrow_down),),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Pencil / lock icon
              // GestureDetector(
              //   onTap: onPencilTap,
              //   behavior: HitTestBehavior.opaque,
              //   child: Padding(
              //     padding: const EdgeInsets.fromLTRB(0, 0, 14, 0),
              //     child: AnimatedSwitcher(
              //       duration: const Duration(milliseconds: 200),
              //       child: Icon(
              //         isUnlocked
              //             ? Icons.check_circle_rounded
              //             : Icons.edit_outlined,
              //         key: ValueKey(isUnlocked),
              //         size: 20,
              //         color: isUnlocked
              //             ? const Color(0xFF3D5A80)
              //             : Colors.grey[400],
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  UPDATE BUTTON
// ══════════════════════════════════════════════════════════════════════════════

class _UpdateButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onTap;

  const _UpdateButton({required this.isSaving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSaving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D5A80), Color(0xFF53698A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSaving
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF3D5A80).withOpacity(0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Update',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}
