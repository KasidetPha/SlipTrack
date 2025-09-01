import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BudgetSetting extends StatefulWidget {

  final VoidCallback? onBack;


  const BudgetSetting({super.key, this.onBack});

  @override
  State<BudgetSetting> createState() => _BudgetSettingState();
}

class _BudgetSettingState extends State<BudgetSetting> {
  double _currentValue = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 22, 163, 75),
                      Color.fromARGB(255, 13, 148, 134)
                    ]
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30)
                  )
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: widget.onBack ?? () => Navigator.pop(context),
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24,)
                          ),
                        ),
                      ),
                      Text("Budget Setting", style: GoogleFonts.prompt(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1, decoration: TextDecoration.none))
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Monthly Buget Limits", style: GoogleFonts.prompt(fontWeight: FontWeight.w500, fontSize: 20)),
                    SizedBox(height: 24,),
                    Container(
                      // alignment: Alignment.center,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0, 0),
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            spreadRadius: 1
                          )
                        ]
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_dining, size: 24,),
                                    SizedBox(width: 12,),
                                    Text("Food & Dining", style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500),),
                                  ],
                                ),
                                Text("฿500.00", style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.4)),)
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.grey,
                                inactiveTrackColor: Colors.blue.withOpacity(0.3),
                                thumbColor: Colors.blue,
                                overlayColor: Colors.blue.withOpacity(0.2),
                                valueIndicatorColor: Colors.white,
                                // valueIndicatorStrokeColor: Colors.black
                                valueIndicatorTextStyle: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300
                                )
                              ),
                              child: Slider(
                                value: _currentValue,
                                min: 0,
                                max: 5000,
                                divisions: 100,
                                label: "฿${_currentValue.toInt()}",
                                onChanged: (value) {
                                  setState(() {
                                    _currentValue = value;
                                  });
                                },
                              ),
                            )
                          ],
                        )
                      ),
                    )
                  ]
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}