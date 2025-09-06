import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/bottom_nav_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("http://localhost:3000/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailController.text,
        "password": passwordController.text,
      })
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data["token"];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Success"))
      );

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx) => BottomNavPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: ${response.body}"))
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[400],
      // appBar: AppBar(
      //   title: Text("Login", style: GoogleFonts.prompt(),),
      //   centerTitle: true,
      //   backgroundColor: Colors.blue[200],
      //   foregroundColor: Colors.white,
      //   toolbarHeight: 100,
      //   shape: const RoundedRectangleBorder(
      //     borderRadius: BorderRadiusGeometry.vertical(
      //       bottom: Radius.circular(30)
      //     )
      //   ),
      // ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage("assets/images/icons/icon_sliptrack.jpg"),
                backgroundColor: Colors.transparent
              ),
              const SizedBox(height: 24,),
              Text("Slip Track", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white, letterSpacing: 1),),
              const SizedBox(height: 6,),
              Text("Track your expenses with easy.", style: GoogleFonts.prompt(fontWeight: FontWeight.normal, fontSize: 18, color: Colors.white.withOpacity(0.5)),),
              Padding(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                          width: 1.5
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 4)
                          )
                        ]
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email", style: GoogleFonts.prompt(fontSize: 18, color: Colors.white),),
                            SizedBox(height: 12,),
                            TextFormField(
                              controller: emailController,
                              style: GoogleFonts.prompt(
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.3),
                                hint: Text("Enter your email", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.4)),),
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.4),),
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                  borderRadius: BorderRadius.circular(12)
                                )
                              ),
                            ),
                            SizedBox(height: 24,),
                            Text("Password", style: GoogleFonts.prompt(fontSize: 18, color: Colors.white),),
                            SizedBox(height: 12,),
                            TextFormField(
                              controller: passwordController,
                              style: GoogleFonts.prompt(
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.3),
                                hint: Text("Enter your Password", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.4)),),
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.5),),
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                  borderRadius: BorderRadius.circular(12)
                                )
                              ),
                            ),
                            SizedBox(height: 24,),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.brown,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                minimumSize: Size(double.infinity, 0),
                              ),
                              onPressed: login, 
                              child: Text("Sign In", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold))
                            ),
                            SizedBox(height: 12,),
                            Center(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black.withOpacity(0.4),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(0, 0)
                                ),
                                onPressed: () {},
                                child: Text("Forgot Password?", style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.normal))
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}