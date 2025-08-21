import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


class AddBody extends StatefulWidget {
  const AddBody({super.key});
  @override
  State<AddBody> createState() => _AddBodyState();
}

class _AddBodyState extends State<AddBody> {
  TextEditingController _dateController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  final now = DateTime.now();

  List<String> categories = [
    "Food & Drinks",
    "Transport",
    "Rent",
    "Utilities",
    "Debt / Credit",
    "Insurance",
    "Investment",
    "Clothing",
    "Health & Fitness",
    "Beauty & Care",
    "Travel & Leisure",
    "Entertainment",
    "Gifts & Donation",
    "Emergency",
    "Miscellaneous",
    "Others"
  ];

  String? selectedCategory;

  final TextEditingController _controller = TextEditingController();
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());

    _controller.addListener(() {
      String text = _controller.text;
      
      text = text.replaceAll(',', '').replaceAll('฿', '');

      if (text.isNotEmpty) {
        if (text.length > 8) text = text.substring(0,8);

        String formatted =  _formatter.format(int.parse(text));

        _controller.value = _controller.value.copyWith(
          text: '$formatted ฿',
          selection: TextSelection.collapsed(offset: formatted.length)
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Receipt Photo",
            style: GoogleFonts.prompt(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text("Amount", style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          TextFormField(
            style: GoogleFonts.prompt(
              fontSize: 50,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              filled: true,
              fillColor: Colors.white,
              hintText: "0.00",
              hintStyle: GoogleFonts.prompt(
                fontSize: 50,
                color: Colors.black.withOpacity(0.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 12,),
          Text("Category", style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),),
          SizedBox(height: 12,),
          DropdownButtonFormField<String>(
            isDense: true,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(12),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(12)
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(12)
              ),
            ),
          hint: Text(
            "Select a category",
            style: GoogleFonts.prompt(
              fontWeight: FontWeight.w500,
              color: Colors.black
          ),
              
            ),
            value: selectedCategory,
            items: categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category, style: GoogleFonts.prompt(fontWeight: FontWeight.w500),),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
          ),
          SizedBox(height: 12,),
          Text("Date", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 12,),
          TextFormField(
            style: TextStyle(
              fontWeight: FontWeight.w500
            ),
            controller: _dateController,
            readOnly: true,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(12),
              filled: true,
              fillColor: Colors.white,
              hintText: "Select a date",
              hintStyle: GoogleFonts.prompt(
                color: Colors.black,
                fontWeight: FontWeight.w500
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(12)
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(12)
              ),
              suffix: Icon(Icons.calendar_today),
            ),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );

              if (pickedDate != null) {
                String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
                setState(() {
                  _dateController.text = formattedDate;
                });
              }
            },
          )
        ],
      ),
    );
  }
}
