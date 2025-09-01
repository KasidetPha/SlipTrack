import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfilePage extends StatelessWidget {

  final VoidCallback? onBack;

  const EditProfilePage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 39, 98, 235),
                      Color.fromARGB(255, 143, 52, 234)
                    ]
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30)
                  )
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: onBack ?? () => Navigator.pop(context),
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24,)
                          )
                        )
                      ),
                      Text("Edit Profile", style: GoogleFonts.prompt(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1, decoration: TextDecoration.none)),
                    ]
                  ),
                ),
              ),
              SizedBox(height: 50,),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    backgroundImage: AssetImage('assets/images/icons/icon_user.png'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: ใส่ฟังก์ชันแก้ไขรูป
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          // shape: BoxShape.circle,
                          border: Border.all(color: Colors.black.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.create_outlined,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ฟอร์ม
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    Text(
                      "Full Name",
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: GoogleFonts.prompt(),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.5)),
                        ),
                      ),
                    ),
                
                    const SizedBox(height: 24),
                
                    // Email
                    Text(
                      "Email",
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.prompt(),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                
                    const SizedBox(height: 24),
                
                    // Phone Number
                    Text(
                      "Phone Number",
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.prompt(),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.5)),
                        ),
                      ),
                    ),

                    SizedBox(height: 24,),

                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 39, 98, 235),
                        minimumSize: Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(12)
                        )
                      ),
                      onPressed: () {}, child: Text("Save Changes", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16),)
                    )

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
