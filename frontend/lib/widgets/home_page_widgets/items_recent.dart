import 'package:flutter/material.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ItemsRecent extends StatefulWidget {
  const ItemsRecent({super.key});

  @override
  State<ItemsRecent> createState() => _ItemsRecentState();
}

class _ItemsRecentState extends State<ItemsRecent> {
  late Future<List<ReceiptItem>> _futureItems;

  @override
  void initState() {
    super.initState();
    _futureItems = fetchReceiptItems();
  }

  Future<List<ReceiptItem>> fetchReceiptItems() async {
    final response = await http.get(Uri.parse('http://localhost:3000/receipt_item'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((item) => ReceiptItem.fromJson(item)).toList();
    } else {
      throw Exception("Can't fetch Receipt");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReceiptItem>>(
      future: fetchReceiptItems(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(),);
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"),);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Not found Item"),);
        }

        final items = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            children: items.map((item) => 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Container(
                  width: double.infinity,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row( 
                            children: [
                              Image.asset("assets/images/icons/icon_food.png", width: 25, height: 25,),
                              SizedBox(width: 15,),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${item.item_name}", style: GoogleFonts.prompt(fontWeight: FontWeight.bold),),
                                  Text("Today, 9:30 AM", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5)),)
                                ]
                              ),
                            ],
                          ),
                          Text("${item.total_price.toStringAsFixed(2)}.-", style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),)
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ).toList(),
          ),
        );
      }
    );
  }
}