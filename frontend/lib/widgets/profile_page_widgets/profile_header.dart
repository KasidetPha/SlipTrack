import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:google_fonts/google_fonts.dart';


class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      height: 250,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255,147, 50, 233),
            Color.fromARGB(144, 218, 39, 121)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: profileAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: Colors.white)
        ),
        error: (error, stack) {
          debugPrint("PROFILE HEADER ERROR: $error");
          debugPrintStack(stackTrace: stack);

          return Center(
            child: Text(
              "โหลดข้อมูลไม่สำเร็จ",
              style: GoogleFonts.prompt(color: Colors.white),
            ),
          );
        },
        data: (profile) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white.withOpacity(0.25),
              backgroundImage: profile.profileImage != null &&
                      profile.profileImage!.isNotEmpty
                  ? NetworkImage(profile.profileImage!)
                  : null,
              child: profile.profileImage == null || profile.profileImage!.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              profile.displayName,
              style: GoogleFonts.prompt(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email,
              style: GoogleFonts.prompt(
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        )
      )
    );
  }
}