import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditReceiptItemSheet extends StatefulWidget {
  final ReceiptItem item;
  const EditReceiptItemSheet({super.key, required this.item});

  @override
  State<EditReceiptItemSheet> createState() => _EditReceiptItemSheetState();
}

class _AppColors {
  static const primary = Color(0xFF5046E8);
  static const secondary = Color(0xFF5FC4FF);
  static const surface = Color(0xFFF6F7FB);
  static const text = Color(0xFF1E1E1E);
  static const subtleText = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
}

enum PriceMode {unit, total}

class _EditReceiptItemSheetState extends State<EditReceiptItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _unitPriceCtrl;
  late DateTime _date;
  late int _categoryId;

  PriceMode _priceMode = PriceMode.total;

  bool _saving = false;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  static const _categoryOptions = <Map<String, dynamic>>[
    {'id': 1, 'name': 'Others'},
    {'id': 2, 'name': 'Food'},
    {'id': 3, 'name': 'Shopping'},
    {'id': 4, 'name': 'Bills'},
    {'id': 5, 'name': 'Transportation'},
  ];

  static const _prefKeyPriceMode = 'edit_receipt_price_mode';

  Future<void> _loadPriceMode() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefKeyPriceMode);
    if ( s!= null) {
      final mode = (s == 'unit') ? PriceMode.unit : PriceMode.total;

      if (mounted) {
        setState(() {
          
          _priceMode = mode;

          if (_priceMode == PriceMode.unit) {
            _recalcFromUnit();
          } else {
            _recalcFromTotal();
          }
        });
      }
    }
  }

  Future<void> _savePriceMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKeyPriceMode,
      _priceMode == PriceMode.unit ? 'unit' : 'total'
    );
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.item_name);
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
    _priceCtrl = TextEditingController(text: widget.item.total_price.toStringAsFixed(2));
    _loadPriceMode();

    final q = widget.item.quantity;
    final unit = q > 0
      ? (widget.item.total_price / q)
      : widget.item.total_price;
    _unitPriceCtrl = TextEditingController(text: unit.toStringAsFixed(2));

    _date = widget.item.receiptDate;
    _categoryId = _categoryOptions.any((c) => c['id'] == widget.item.category_id)
      ? widget.item.category_id
      : _categoryOptions.first['id'] as int;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _unitPriceCtrl.dispose();
    super.dispose();
  }

  Future _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select date',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: _AppColors.primary),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _AppColors.primary),
            ),
          ),
          child: child!,
        );
      }
    );
    if (picked != null) setState(() => _date = picked);
  }

  int _qty() => int.tryParse(_qtyCtrl.text) ?? 1;
  double _unitPrice() => double.tryParse(_unitPriceCtrl.text) ?? 0.0;
  double _totalPrice() => double.tryParse(_priceCtrl.text) ?? 0.0;

  void _recalcFromTotal() {
    final q = _qty();
    final unit = q > 0 ? (_totalPrice() / q) : 0.0;
    _unitPriceCtrl.text = unit.toStringAsFixed(2);
  }

  void _recalcFromUnit() {
    final total = _unitPrice() * _qty();
    _priceCtrl.text = total.toStringAsFixed(2);
  }

  void _onQtyChange() {
    if (_priceMode == PriceMode.unit) {
      _recalcFromUnit();
    } else {
      _recalcFromTotal();
    }

    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final qty = _qty();

    final price = _priceMode == PriceMode.unit ? _unitPrice() * qty : _totalPrice();

    setState(() => _saving = true);
    try {
      await ReceiptService().updateReceiptItem(
        id: widget.item.item_id,
        itemName: name,
        quantity: qty,
        totalPrice: price,
        receiptDate: _date,
        categoryId: _categoryId
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'))
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _input({String? hint, String? prefix, Color? fillColor = Colors.white}) {
    return InputDecoration(
      // labelText: label,
      hintText: hint,
      prefixText: prefix,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _AppColors.primary, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _AppColors.danger),
      )
    );
  }

  Widget _section({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4)
          )
        ]
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // final cate = _categoryOptions.firstWhere((c) => c['id'] == _categoryId);
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 10, 
          bottom: MediaQuery.of(context).viewInsets.bottom + 16
        ),
        child: DefaultTextStyle(
          style: GoogleFonts.prompt(color: _AppColors.text, fontSize: 14), 
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(height: 5, width: 44,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.black12, borderRadius: BorderRadius.circular(12)
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Edit Transaction', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w700),)
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _saving ? null : () => Navigator.pop(context, false), 
                      icon: const Icon(Icons.close_rounded)
                    )
                  ],
                ),
                const SizedBox(height: 8,),
                
                _section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Item name", style: GoogleFonts.prompt(fontSize: 12, color: _AppColors.text),),
                      const SizedBox(height: 6,),
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: _input(hint: 'Item name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12,),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quantity', style: GoogleFonts.prompt(fontSize: 12, color: _AppColors.text),),
                                const SizedBox(height: 6,),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          final n = int.tryParse(_qtyCtrl.text) ?? 1;
                                          if (n > 1) _qtyCtrl.text = (n-1).toString();
                                          // setState(() {});
                                          _onQtyChange();
                                        },
                                        icon: const Icon(Icons.remove_rounded)
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _qtyCtrl,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isCollapsed: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          onChanged: (_) => _onQtyChange(),
                                          validator: (v) {
                                            final n = int.tryParse(v ?? '');
                                            if (n == null || n <= 0) return 'Quantity must be >= 1';
                                            return null;
                                          }
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          final n = int.tryParse(_qtyCtrl.text) ?? 1;
                                          _qtyCtrl.text = (n+1).toString();
                                          // setState(() {});
                                          _onQtyChange();
                                        },
                                        icon: Icon(Icons.add_rounded)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ),
                          const SizedBox(width: 12,),
                          
                          // mode
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Price Mode", style: TextStyle(fontSize: 12, color: _AppColors.text),),
                                const SizedBox(height: 6,),
                                SizedBox(
                                  width: double.infinity,
                                  // height: 44,
                                  child: SegmentedButton<PriceMode>(
                                    segments: const [
                                      ButtonSegment(value: PriceMode.unit, label: Center(child: Text('Unit\n(฿/item)', textAlign: TextAlign.center, maxLines: 2,)) ),
                                      ButtonSegment(value: PriceMode.total, label: Center(child: Text('Total\n(฿)', textAlign: TextAlign.center, maxLines: 2,)) )
                                    ], 
                                    selected: {_priceMode},
                                    showSelectedIcon: false,
                                    style: ButtonStyle(
                                      shape: MaterialStatePropertyAll(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadiusGeometry.circular(12)
                                        )
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      // fixedSize: const MaterialStatePropertyAll(Size(double.infinity, 44)),
                                      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 8))
                                    ),
                                    onSelectionChanged: (s) {
                                      setState(() {
                                        _priceMode = s.first;
                                  
                                        if (_priceMode == PriceMode.unit) {
                                          _recalcFromUnit();
                                        } else {
                                          _recalcFromTotal();
                                        }
                                      });
                                  
                                      _savePriceMode();
                                    },
                                  ),
                                )
                              ],
                            ),
                          )
                          

                        ],
                      ),
                      const SizedBox(height: 12,),
                      
                      if (_priceMode == PriceMode.unit) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Unit Price (฿)', style: GoogleFonts.prompt(fontSize: 12),),
                                  const SizedBox(height: 6,),
                                  TextFormField(
                                    controller: _unitPriceCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textInputAction: TextInputAction.next,
                                    decoration: _input(hint: 'เช่น 12.50', prefix: '฿'),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                                    ],
                                    onChanged: (_) => _recalcFromUnit(),
                                    validator: (v) {
                                      final n = double.tryParse(v ?? '');
                                      if (n == null || n < 0) return 'Price must be >= 0';
                                      return null;
                                    }
                                  ),
                                ],
                              )
                            ),
                            const SizedBox(width: 12,),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Price (฿)', style: GoogleFonts.prompt(fontSize: 12),),
                                  const SizedBox(height: 6,),
                                  TextFormField(
                                    readOnly: true,
                                    controller: _priceCtrl,
                                    decoration: _input(hint: 'เช่น 100.00', prefix: '฿', fillColor: Colors.grey[200]),
                                    // onChanged: (_) => _recalcFromTotal(),
                                    validator: null
                                  ),
                                ],
                              )
                            )
                          ],
                        )
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Unit Price (฿)', style: GoogleFonts.prompt(fontSize: 12),),
                                  const SizedBox(height: 6,),
                                  TextFormField(
                                    controller: _unitPriceCtrl,
                                    decoration: _input(hint: 'เช่น 12.50', prefix: '฿', fillColor: Colors.grey[200]),
                                    validator: null,
                                    // onChanged: (_) => _recalcFromUnit(),
                                  ),
                                ],
                              )
                            ),
                            const SizedBox(width: 12,),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Price (฿)', style: GoogleFonts.prompt(fontSize: 12),),
                                  const SizedBox(height: 6,),
                                  TextFormField(
                                    controller: _priceCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textInputAction: TextInputAction.done,
                                    decoration: _input(hint: 'เช่น 100.00', prefix: '฿',),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                                    ],
                                    validator: (v) {
                                      final n = double.tryParse(v ?? '');
                                      if (n == null || n < 0) return 'Price must be >= 0';
                                      return null;
                                    },
                                    onChanged: (_) => _recalcFromTotal(),
                                  ),
                                ],
                              )
                            )
                          ],
                        )
                      ],
                    ]
                  )
                ),

                const SizedBox(height: 12,),
                  
                _section(
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _AppColors.surface,
                              border: Border.all(color: _AppColors.border)
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 20, color: _AppColors.primary,),
                                const SizedBox(width: 8,),
                                Text(_dateFmt.format(_date),
                                  style: GoogleFonts.prompt(fontWeight: FontWeight.w600),)
                              ],
                            ),
                          ),
                        )
                      ),
                      const SizedBox(width: 12,),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _categoryId,
                          decoration: _input(),
                          items: _categoryOptions
                            .map((c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(c['name'] as String),
                            )).toList(), 
                          onChanged: (v) => setState(() => _categoryId = v ?? _categoryId)
                        )
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 16,),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context, false), 
                        child: const Text("Cancel"),
                      )
                    ),
                    const SizedBox(width: 12,),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                          ? const SizedBox(height: 16, width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2,),)
                          : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Saving...' : 'Save Changes')
                      )
                    )
                  ],
                )
              ],
            )
          ),
        )
      )
    );
  }
}