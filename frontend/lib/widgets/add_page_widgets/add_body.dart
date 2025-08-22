// import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';


class AddBody extends StatefulWidget {
  const AddBody({super.key});
  @override
  State<AddBody> createState() => _AddBodyState();
}

class _AddBodyState extends State<AddBody> {

  final  ImagePicker _picker = ImagePicker();
  final now = DateTime.now();
  final TextEditingController _controller = TextEditingController();
  final NumberFormat _formatter = NumberFormat('#,###');
  TextEditingController _dateController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      print("Selected image path: ${image.path}");
    }
  }

  void _showPickOptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Take photo", style: GoogleFonts.prompt()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text("Camera", style: GoogleFonts.prompt(),),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text("Gallery", style: GoogleFonts.prompt(),),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              }
            )
          ],
        )
      )
    );
  }

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
  void dispose() {
    _controller.dispose();
    _dateController.dispose();
    super.dispose();
  }

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

          GestureDetector(
            onTap: _showPickOptionDialog,
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                radius: Radius.circular(12),
                strokeWidth: 3,
                dashPattern: [15,5],
                padding: EdgeInsets.all(0),
                color: Colors.grey,
                
              ),
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.1),
                  border: Border.all(color: Colors.grey.withOpacity(0.2),)
                ),
                child: Center(
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.black.withOpacity(0.8),),
                      Text("Tap to take photo", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w500), ),
                      Text("of your receipt", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w500), )
                    ],
                  ),
                ),
              ),
            )
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
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
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
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12)
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12)
              ),
            ),
          hint: Text(
            "Select a category",
            style: GoogleFonts.prompt(
              color: Colors.black.withOpacity(0.5)
          ),
              
            ),
            value: selectedCategory,
            items: categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category, style: GoogleFonts.prompt(),),
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
            style: GoogleFonts.prompt(),
            controller: _dateController,
            readOnly: true,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(12),
              filled: true,
              fillColor: Colors.white,
              hintText: "Select a date",
              hintStyle: GoogleFonts.prompt(
                color: Colors.black,
                
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12)
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12)
              ),
              suffix: Icon(Icons.calendar_today, ),
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
          ),

          SizedBox(height: 12,),

          Text("Notes", style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),),
          SizedBox(height: 12,),
          TextFormField(
            style: GoogleFonts.prompt(),
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12)
              ),
              hintText: "What did you spend money on?",
              hintStyle: GoogleFonts.prompt(color: Colors.black.withOpacity(0.4))
            ),
          ),
          SizedBox(height: 24,),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green[600],
              minimumSize: Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)
              )
            ),
            onPressed: () {print("Save active");},
            child: Text("Save Expense", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16),),
          ),
          SizedBox(height: 24,),
        ],
      ),
    );
  }
}
