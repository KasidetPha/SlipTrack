import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report"),
        centerTitle: true,
      ),
      // เปลี่ยนจาก Column เป็น ListView เพื่อให้ไถจอขึ้นลงได้
      body: ListView(
        children: [
          SizedBox(
            width: double.infinity,
            // ลบ height: double.infinity ออก ให้รูปแสดงตามสัดส่วนจริง
            child: Image.asset(
              "assets/images/dashboard1.png", 
              fit: BoxFit.fitWidth, // เปลี่ยนเป็น fitWidth เพื่อให้พอดีความกว้างจอ
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Image.asset(
              "assets/images/dashboard2.png", 
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}