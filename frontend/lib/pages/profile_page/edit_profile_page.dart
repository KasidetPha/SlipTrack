import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/services/profile_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

final editProfileLoadingProvider = StateProvider<bool>((ref) => false);

class EditProfilePage extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const EditProfilePage({super.key, this.onBack});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _geminiController = TextEditingController();

  bool _hideGeminiToken = true;
  bool _hasSetInitialValue = false;

  bool _isVerifyingGemini = false;
  bool? _isGeminiValid;

  @override
  void dispose() {
    _fullNameController.dispose();
    _geminiController.dispose();
    super.dispose();
  }

  Future<void> _verifyGeminiToken() async {
    final token = _geminiController.text.trim();

    if (token.isEmpty || token.contains("****")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณากรอก Gemini API Key ใหม่ก่อนตรวจสอบ"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingGemini = true;
      _isGeminiValid = null;
    });

    final isValid = await ProfileService().verifyGeminiToken(token);

    if (!mounted) return;

    setState(() {
      _isVerifyingGemini = false;
      _isGeminiValid = isValid;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isValid
              ? "Gemini API Key ใช้งานได้"
              : "Gemini API Key ใช้งานไม่ได้",
        ),
        backgroundColor: isValid ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _fullNameController.text.trim();
    final geminiText = _geminiController.text.trim();

    String? geminiApiKey;

    final isNewGeminiToken =
      geminiText.isNotEmpty && !geminiText.contains("****");

    if (isNewGeminiToken && _isGeminiValid != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาตรวจสอบ Gemini Token ก่อนบันทึก'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (geminiText.isEmpty) {
      geminiApiKey = "";
    } else if (geminiText.contains("****")) {
      geminiApiKey = null;
    } else {
      geminiApiKey = geminiText;
    }

    ref.read(editProfileLoadingProvider.notifier).state = true;

    try {
      final profile = await ref.read(userProfileDetailProvider.future);
      
      final success = await ProfileService().updateProfile(
        fullName: fullName,
        geminiApiKey: geminiApiKey,
        imageUrl: profile.profileImage,
      );

      if (!success) {
        throw Exception('Update profile failed');
      }

      _hasSetInitialValue = false;

      ref.invalidate(userProfileProvider);
      ref.invalidate(userProfileDetailProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) {
        ref.read(editProfileLoadingProvider.notifier).state = false;
      }
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: "Your full name",
      hintStyle: GoogleFonts.prompt(color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFFF7F7FB),
      prefixIcon: const Icon(
        Icons.person_rounded,
        color: Color(0xFF6D5DF6),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF6D5DF6),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(editProfileLoadingProvider);
    final profileAsync = ref.watch(userProfileDetailProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: Stack(
        children: [
          const _TopGradient(),
      
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                _Header(onBack: widget.onBack),
      
                const SizedBox(height: 72),
      
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 74, 22, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6D5DF6).withOpacity(0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: profileAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text(
                      'โหลดข้อมูลไม่สำเร็จ',
                      style: GoogleFonts.prompt(color: Colors.red),
                    ),
                    data: (profile) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_hasSetInitialValue) {
                          _fullNameController.text = profile.fullname;

                          if (profile.hasGeminiApiKey) {
                            _geminiController.text = profile.maskedGeminiApiKey ?? '';
                          } else {
                            _geminiController.clear();
                          }

                          _hasSetInitialValue = true;
                        }
                      });

                      return Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 28),
          
                            Text(
                              "Full Name",
                              style: GoogleFonts.prompt(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF201A35),
                              ),
                            ),
          
                            const SizedBox(height: 10),
          
                            TextFormField(
                              controller: _fullNameController,
                              style: GoogleFonts.prompt(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _inputDecoration(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            Text(
                              "Gemini API Token",
                              style: GoogleFonts.prompt(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF201A35),
                              ),
                            ),

                            const SizedBox(height: 10),

                            TextFormField(
                              controller: _geminiController,
                              obscureText: _hideGeminiToken,
                              style: GoogleFonts.prompt(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: "Optional",
                                helperStyle: GoogleFonts.prompt(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF7F7FB),
                                prefixIcon: const Icon(
                                  Icons.key_rounded,
                                  color: Color(0xFF6D5DF6),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _hideGeminiToken
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _hideGeminiToken = !_hideGeminiToken;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 18,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6D5DF6),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
          
                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: _isVerifyingGemini ? null : _verifyGeminiToken,
                                icon: _isVerifyingGemini
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(
                                        _isGeminiValid == true
                                            ? Icons.check_circle_rounded
                                            : Icons.verified_rounded,
                                        color: _isGeminiValid == true
                                            ? Colors.green
                                            : const Color(0xFF6D5DF6),
                                      ),
                                label: Text(
                                  _isVerifyingGemini
                                      ? "กำลังตรวจสอบ..."
                                      : _isGeminiValid == true
                                          ? "Token ใช้งานได้"
                                          : "ตรวจสอบ Gemini Token",
                                  style: GoogleFonts.prompt(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),
          
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF6D5DF6),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: isLoading ? null : _saveProfile,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        "Save Changes",
                                        style: GoogleFonts.prompt(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
      
          const Positioned(
            top: 116,
            left: 0,
            right: 0,
            child: Center(
              child: _ProfileAvatar(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopGradient extends StatelessWidget {
  const _TopGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6D5DF6),
            Color(0xFF9B5DE5),
            Color(0xFFFF6CAB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(38),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback? onBack;

  const _Header({this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onBack ?? () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Text(
            "Edit Profile",
            style: GoogleFonts.prompt(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends ConsumerStatefulWidget {
  const _ProfileAvatar({super.key});

  @override
  ConsumerState<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<_ProfileAvatar> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
    });

    await _uploadImage(File(picked.path));
  }

  Future<void> _uploadImage(File file) async {
    try {
      final url = await uploadToSupabase(file);

      final profile = await ref.read(userProfileDetailProvider.future);

      final success = await ProfileService().updateProfile(
        fullName: profile.fullname,
        imageUrl: url,
      );

      if (!success) {
        throw Exception('Update profile image failed');
      }

      ref.invalidate(userProfileProvider);
      ref.invalidate(userProfileDetailProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<String> uploadToSupabase(File file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'profile_images/$fileName';

    final bytes = await file.readAsBytes();

    await Supabase.instance.client.storage
        .from('profiles')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return Supabase.instance.client.storage
        .from('profiles')
        .getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: profileAsync.when(
            loading: () => const CircleAvatar(
              radius: 58,
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => const CircleAvatar(
              radius: 58,
              // backgroundImage: AssetImage("assets/images/profiles/profile_test.jpg"),
              child: Icon(
                Icons.person_rounded,
                size: 48,
                color: Colors.grey,
              ),
            ),
            data: (profile) {
              final imageUrl = profile.profileImage;
              ImageProvider? avatarImage;

              if (_imageFile != null) {
                avatarImage = FileImage(_imageFile!);
              } else if (imageUrl != null && imageUrl.isNotEmpty) {
                avatarImage = NetworkImage(imageUrl);
              }

              return CircleAvatar(
                radius: 58,
                backgroundColor: const Color(0xFFF1F1F5),
                backgroundImage: avatarImage,
                onBackgroundImageError: avatarImage is NetworkImage
                  ? (_, __) {
                      debugPrint('Profile image load failed');
                    }
                  : null,
                child: avatarImage == null
                  ? const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: Colors.grey,
                    )
                  : null,
              );
            }
          )
        ),
        Positioned(
          right: 2,
          bottom: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _pickImage,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF6D5DF6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}