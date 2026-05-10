import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/widgets/filter_month_year.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/transaction_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _formatter = NumberFormat('#,##0');
  final _compactFormatter = NumberFormat.compact(); // สำหรับย่อตัวเลขในกราฟแท่ง

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // โทนสีหลัก
  final Color primaryColor = const Color(0xFFFB2966);
  final Color bgColor = const Color(0xFFF4F6F9); // ปรับพื้นหลังให้เป็นสีเทาอ่อนอมฟ้าดูสบายตา
  final Color cardColor = Colors.white;

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF94A3B8);
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse(hex, radix: 16) ?? 0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider((
      month: _selectedMonth,
      year: _selectedYear,
    )));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 8,
        shadowColor: const Color(0xFFFB2966).withOpacity(0.3), // เงาสีชมพูอ่อนๆ
        centerTitle: true,
        toolbarHeight: 75, // เพิ่มความสูงให้ดูโปร่งขึ้น
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFB2966), Color(0xFFFF527B)], // ไล่เฉดสีชมพู
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Dashboard',
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 22, color: Colors.white),
        ),
      ),
      body: dashboardAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
        error: (err, stack) => Center(
          child: Text(
            "เกิดข้อผิดพลาด\n$err",
            textAlign: TextAlign.center,
            style: GoogleFonts.prompt(color: Colors.red),
          ),
        ),
        data: (data) {
          final overview = data['overview'] ?? {
            'total_income': 0.0,
            'total_expense': 0.0,
          };

          final categories = (data['expense_by_category'] as List<dynamic>?) ?? [];
          final trends = (data['six_months_trend'] as List<dynamic>?) ?? [];

          return Column(
            children: [
              Container(
                color: bgColor,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                child: FilterMonthYear(
                  initialMonth: _selectedMonth,
                  initialYear: _selectedYear,
                  color: Colors.black,
                  onMonthYearChanged: (int newMonth, int newYear) {
                    setState(() {
                      _selectedMonth = newMonth;
                      _selectedYear = newYear;
                    });
                  },
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("ภาพรวมเดือนนี้"),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _buildSummaryCard(
                            "รายรับ",
                            overview['total_income'] ?? 0,
                            const Color(0xFF10B981),
                            Icons.south_west_rounded,
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard(
                            "รายจ่าย",
                            overview['total_expense'] ?? 0,
                            const Color(0xFFEF4444),
                            Icons.north_east_rounded,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle("รายจ่ายตามหมวดหมู่"),
                      const SizedBox(height: 16),
                      _buildExpensePieChart(
                        categories,
                        overview['total_expense'] ?? 0,
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle("แนวโน้ม 6 เดือนย้อนหลัง"),
                      const SizedBox(height: 16),
                      _buildTrendBarChart(trends),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title, 
      style: GoogleFonts.prompt(
        fontSize: 18, 
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E293B)
      )
    );
  }

  Widget _buildSummaryCard(String title, num amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08), 
              blurRadius: 24, 
              offset: const Offset(0, 8)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12), 
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title, 
                  style: GoogleFonts.prompt(
                    fontSize: 15, 
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500
                  )
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "฿${_formatter.format(amount)}", 
              style: GoogleFonts.prompt(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: const Color(0xFF1E293B)
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensePieChart(List<dynamic> categories, num totalExpense) {
    if (categories.isEmpty) {
      return _buildEmptyState("ยังไม่มีข้อมูลรายจ่ายเดือนนี้");
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 24, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Row(
        children: [
          // ส่วนกราฟโดนัท
          SizedBox(
            height: 150,
            width: 150,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 55, // ขยายรูตรงกลาง
                    startDegreeOffset: -90,
                    sections: categories.map((cat) {
                      return PieChartSectionData(
                        color: _parseColor(cat['color_hex']),
                        value: (cat['percentage'] as num).toDouble(),
                        title: '', 
                        radius: 20, // ลดความหนาของเส้นกราฟให้ดูโมเดิร์น
                      );
                    }).toList(),
                  ),
                ),
                // ใส่ยอดรวมไว้ตรงกลาง
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("รายจ่ายรวม", style: GoogleFonts.prompt(fontSize: 10, color: const Color(0xFF64748B))),
                      Text(
                        _compactFormatter.format(totalExpense), 
                        style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 32),
          // ส่วน Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 10, 
                        height: 10, 
                        decoration: BoxDecoration(
                          color: _parseColor(cat['color_hex']), 
                          shape: BoxShape.circle
                        )
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cat['category_name'], 
                          style: GoogleFonts.prompt(fontSize: 14, color: const Color(0xFF475569)), 
                          overflow: TextOverflow.ellipsis
                        )
                      ),
                      Text(
                        "${cat['percentage']}%", 
                        style: GoogleFonts.prompt(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrendBarChart(List<dynamic> trends) {
    if (trends.isEmpty) return _buildEmptyState("ยังไม่มีข้อมูลแนวโน้ม");

    double maxY = 0;
    for (var t in trends) {
      if ((t['income'] ?? 0) > maxY) maxY = (t['income'] as num).toDouble();
      if ((t['expense'] ?? 0) > maxY) maxY = (t['expense'] as num).toDouble();
    }
    // เผื่อพื้นที่ด้านบนกราฟให้ดูโปร่งขึ้น (คูณ 1.3 แทน 1.2)
    maxY = maxY > 0 ? maxY * 1.3 : 100;

    return Container(
      height: 320, // เพิ่มความสูงเล็กน้อยเพื่อวาง Legend
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 24, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ส่วน Legend อธิบายสี ---
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem("รายรับ", const Color(0xFF10B981)),
              const SizedBox(width: 16),
              _buildLegendItem("รายจ่าย", const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 24),
          
          // --- ส่วนกราฟ ---
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      // ซ่อน Tooltip ถ้าค่าเป็น 0
                      if (rod.toY == 0) return null;
                      
                      return BarTooltipItem(
                        '฿${_compactFormatter.format(rod.toY)}',
                        GoogleFonts.prompt(
                          color: Colors.white, 
                          fontWeight: FontWeight.w600, 
                          fontSize: 12
                        ),
                      );
                    },
                  )
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40, // ลดขนาดพื้นที่แกน Y ลงเล็กน้อย
                      interval: maxY / 6 > 0 ? maxY / 6 : 1, // บังคับให้โชว์ตัวเลขแค่ 4-5 สเกล
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == maxY) return const SizedBox(); // ซ่อนเลข 0 และเลขขอบบนสุดให้ดูคลีน
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            _compactFormatter.format(value), 
                            style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFF94A3B8)),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28, // ปรับลดพื้นที่แกน X ให้กระชับขึ้น
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < trends.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              trends[index]['month_label'] ?? '', 
                              style: GoogleFonts.prompt(
                                fontSize: 12, 
                                color: const Color(0xFF64748B), 
                                fontWeight: FontWeight.w500
                              )
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false), // ปิดเส้นขอบตารางทั้งหมด
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFFF1F5F9), // สีเทาจางมากๆ
                    strokeWidth: 1,
                    dashArray: [4, 4], // ระยะห่างเส้นประดูนุ่มนวลขึ้น
                  )
                ), 
                barGroups: List.generate(trends.length, (i) {
                  final t = trends[i];
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 6, // เพิ่มระยะห่างระหว่างแท่งเขียวแดงให้อ่านง่าย
                    barRods: [
                      BarChartRodData(
                        toY: (t['income'] as num?)?.toDouble() ?? 0.0, 
                        color: const Color(0xFF10B981), 
                        width: 14, // ทำให้แท่งอ้วนขึ้นเล็กน้อย
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)) // โค้งมนมากขึ้น
                      ),
                      BarChartRodData(
                        toY: (t['expense'] as num?)?.toDouble() ?? 0.0, 
                        color: const Color(0xFFEF4444), 
                        width: 14, 
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6))
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget ช่วยสำหรับสร้างป้ายกำกับสี (Legend)
  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.prompt(
            fontSize: 12,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(24)
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.prompt(color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}