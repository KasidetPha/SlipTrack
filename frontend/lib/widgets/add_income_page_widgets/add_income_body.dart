import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';


class AddIncomeBody extends StatefulWidget {
  const AddIncomeBody({super.key});
  @override
  State<AddIncomeBody> createState() => _AddIncomeBodyState();
}

class _AddIncomeBodyState extends State<AddIncomeBody> {

  final  ImagePicker _picker = ImagePicker();
  final now = DateTime.now();
  final TextEditingController _controller = TextEditingController();
  final NumberFormat _formatter = NumberFormat('#,###');
  TextEditingController _dateController = TextEditingController();

  // ===== Category data =====
final List<_Category> _categories = const [
  _Category('Salary', Icons.payments_rounded, Color(0xFF64748B)), // เงินเดือน
  _Category('Wages', Icons.work_rounded, Color(0xFFF59E0B)), // ค่าจ้าง/รับจ๊อบ
  _Category('Gift', Icons.card_giftcard_rounded, Color(0xFF8B5CF6)), // มีคนให้
  _Category('Business Sales',Icons.storefront_rounded, Color(0xFF10B981)), // ค้าขาย
];

  int _selectedCategoryIndex = 0; // default เลือกช่องแรก

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24,24,24,96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Amount", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w700)),
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
          Text("Order Name", style: GoogleFonts.prompt(fontWeight: FontWeight.w700, fontSize: 20)),
          SizedBox(height: 12,),
          TextFormField(
            style: GoogleFonts.prompt(),
            // controller: _nameCtr,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(12),
              filled: true,
              fillColor: Colors.white,
              hintText: "Name",
              hintStyle: GoogleFonts.prompt(
                color: Colors.black.withOpacity(0.4),
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
          ),
          SizedBox(height: 12,),
          Text("Date", style: GoogleFonts.prompt(fontWeight: FontWeight.w700, fontSize: 20)),
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

          Text("Notes", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w700),),
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
          SizedBox(height: 12,),
          Text("Category", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w700),),
          SizedBox(height: 12,),
          // ===== Category Grid (แถวละ 4) =====
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (_, i) {
              final c = _categories[i];
              final selected = i == _selectedCategoryIndex;
              return _CategoryCard(
                name: c.name,
                icon: c.icon,
                color: c.color,
                selected: selected,
                onTap: () => setState(() => _selectedCategoryIndex = i),
              );
            },
          ),
          // Center(
          //   child: FilledButton(
          //     style: FilledButton.styleFrom(
          //       backgroundColor: Colors.green[600],
          //       minimumSize: Size(200, 56),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(50)
          //       )
          //     ),
          //     onPressed: () {print("Save active");},
          //     child: Text("Save", style: GoogleFonts.prompt(fontWeight: FontWeight.w700, fontSize: 16),),
          //   ),
          // ),
          SizedBox(height: 24,),
        ],
      ),
    );
  }
}


// ===== category UI helpers =====

class _Category {
  final String name;
  final IconData icon;
  final Color color;
  const _Category(this.name, this.icon, this.color);
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? color.withOpacity(0.12) : cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? color : cs.outlineVariant.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}