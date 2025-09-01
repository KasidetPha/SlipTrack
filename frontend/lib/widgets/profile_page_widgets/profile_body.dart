import 'package:flutter/material.dart';
import 'package:frontend/pages/profile_page/edit_profile_page.dart';
import 'package:frontend/widgets/profile_page_widgets/budget_setting.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Accout Setting", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 20)),
          SizedBox(height: 24,),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (ctx) => EditProfilePage()
              ));
              print("Edit Profile clicked");
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.edit, color: Colors.orange)
                  ),
                  const SizedBox(width: 12,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Edit Profile", style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500),),
                        Text("Update your personal information", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5)),)
                      ],
                    )
                  ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey,)
                ],
              ),
            ),
          ),
          SizedBox(height: 12,),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (ctx) => BudgetSetting()
              ));
              print("budget setting clicked");
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2)
                  )
                ]
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: const Icon(Icons.account_balance_wallet, color: Colors.green,),
                  ),
                  SizedBox(width: 12,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Budget Settings", style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500),),
                        Text("Set monthly spending limits", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16,)
                ],
              ),
            ),
          ),
          SizedBox(height: 24,),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade600,
                padding: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                )
              ),
              onPressed: () {print("Sign out clicked");},
              child: Text("Sign Out", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold),),
            ),
          )
        ],
      ),
    );
  }
}