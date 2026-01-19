import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SlipTrackLogo extends StatelessWidget {
  final double size;

  const SlipTrackLogo({
    super.key,
    this.size = 96,
  });

  static const Color _primary = Color(0xFF16A34A);   // เขียว
  static const Color _secondary = Color(0xFF0D9488); // เทียล;

  @override
  Widget build(BuildContext context) {
    final double circleSize = size;
    final double cardWidth = size * 0.78;
    final double cardHeight = size * 0.58;

    return SizedBox(
      width: circleSize,
      height: circleSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // วงกลมพื้นหลังแบบ gradient
          Container(
            width: circleSize,
            height: circleSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_primary, _secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: Offset(0, 10),
                  color: Colors.black26,
                ),
              ],
            ),
          ),

          // ใบสลิปด้านหลัง (ซ้อน/เอียง)
          Transform.translate(
            offset: Offset(size * -0.08, size * 0.06),
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ใบสลิปด้านหน้า
          Transform.translate(
            offset: Offset(size * 0.06, size * -0.02),
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                width: cardWidth,
                height: cardHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.12,
                  vertical: size * 0.10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                      color: Colors.black.withOpacity(0.12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // icon เงินบนสลิป
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.payments_outlined,
                        size: size * 0.28,
                        color: _primary,
                      ),
                    ),
                    // เส้นๆ จำลองรายการในสลิป
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLine(size, 0.65, _secondary.withOpacity(0.95)),
                        const SizedBox(height: 4),
                        _buildLine(size, 0.52, Colors.grey.shade300),
                        const SizedBox(height: 3),
                        _buildLine(size, 0.46, Colors.grey.shade300),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ตัวอักษร "ST" ด้านหน้า (optional)
          Positioned(
            bottom: size * 0.02,
            left: 0,
            right: 0,
            child: Text(
              "ST",
              textAlign: TextAlign.center,
              style: GoogleFonts.prompt(
                fontSize: size * 0.24,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.white.withOpacity(0.9),
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                    color: Colors.black.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(double size, double widthFactor, Color color) {
    return Container(
      width: size * widthFactor,
      height: size * 0.06,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
