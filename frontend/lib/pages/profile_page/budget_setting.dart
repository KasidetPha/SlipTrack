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

  bool isBudgetWaringOn = false;
  bool isOverspendingAlertOn = false;


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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
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
                        child: InkWell(
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
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 0),
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            spreadRadius: 1
                          )
                        ]
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 24,),
                                    const Icon(Icons.local_dining, size: 24,),
                                    const SizedBox(width: 12,),
                                    Text("Food & Dining", style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500),),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text("฿500.00", style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.4)),),
                                    SizedBox(width: 24,)
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 10,),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.grey,
                                inactiveTrackColor: Colors.blue.withOpacity(0.3),
                                thumbColor: Colors.blue,
                                overlayColor: Colors.blue.withOpacity(0.2),
                                valueIndicatorColor: Colors.white,
                                valueIndicatorTextStyle: const TextStyle(
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24,),
                    Text("Alert Settings", style: GoogleFonts.prompt(fontWeight: FontWeight.w500, fontSize: 20),),
                    SizedBox(height: 24,),
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration:  BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 0),
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            spreadRadius: 1
                          )
                        ]
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Budget Warnings",style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500),),
                                Text("Alert When 80% of budget is reached", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.6)),)
                              ],
                            ),
                            IconButton(
                              icon: Icon(isBudgetWaringOn ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, size:40, color: isBudgetWaringOn ? Colors.green : Colors.grey),
                              onPressed: () {
                                setState(() {
                                  isBudgetWaringOn = !isBudgetWaringOn;
                                });
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12,),
                                        Container(
                      height: 100,
                      width: double.infinity,
                      decoration:  BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 0),
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            spreadRadius: 1
                          )
                        ]
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Overspending Alerts",style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500),),
                                Text("Alert when budget limit is exceded", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.6)),)
                              ],
                            ),
                            IconButton(
                              icon: Icon(isOverspendingAlertOn ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, size:40, color: isOverspendingAlertOn ? Colors.green : Colors.grey),
                              onPressed: () {
                                setState(() {
                                  isOverspendingAlertOn = !isOverspendingAlertOn;
                                });
                              },
                            )
                          ],
                        ),
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