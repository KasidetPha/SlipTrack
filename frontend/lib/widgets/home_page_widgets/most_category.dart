import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MostCategory extends StatefulWidget {
  const MostCategory({super.key});

  @override
  State<MostCategory> createState() => _MostCategoryState();
}

class _MostCategoryState extends State<MostCategory> {
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) return;

    final response = await http.get(
      Uri.parse('http://localhost:3000/receipt_item/categories'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        categories = data.map((e) {
          return {
            "category_name": e["category_name"],
            "total_spent": double.tryParse(e['total_spent'].toString()) ?? 0.0
          };
        }).toList();
      });
    } else {
      print("Error fetching categories: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final topOne = categories.length > 0 ? categories[0] : null;
    final topTwo = categories.length > 1 ? categories[1] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (topOne != null)
            Expanded(
              child: Container(
                height: 140,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Image.asset("assets/images/icons/icon_food.png", width: 30, height: 30),
                    Text(
                      topOne['category_name'],
                      style: GoogleFonts.prompt(fontSize: 16, color: Colors.black),
                    ),
                    Text(
                      "${(topOne['total_spent'] ?? 0.0).toStringAsFixed(2)}.-",
                      style: GoogleFonts.prompt(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 16),
          if (topTwo != null)
            Expanded(
              child: Container(
                height: 140,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Image.asset("assets/images/icons/icon_transport.png", width: 30, height: 30),
                    Text(
                      topTwo['category_name'],
                      style: GoogleFonts.prompt(fontSize: 16, color: Colors.black),
                    ),
                    Text(
                      "${(topTwo['total_spent'] ?? 0.0).toStringAsFixed(2)}.-",
                      style: GoogleFonts.prompt(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
