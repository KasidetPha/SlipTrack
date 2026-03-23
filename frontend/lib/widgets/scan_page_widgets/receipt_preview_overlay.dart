import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/widgets/scan_page_widgets/scan_body.dart';

class ReceiptPreviewOverlay extends StatelessWidget {
  final File imageFile;
  final List<ReceiptScanResult> items;
  final double originalWidth;
  final double originalHeight;
  
  const ReceiptPreviewOverlay({
      super.key,
      required this.imageFile,
      required this.items,
      required this.originalWidth,
      required this.originalHeight,
    });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 5.0,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 1. หาพื้นที่สูงสุดที่มีให้ (เช่น กว้าง 360, สูง 200 ในหน้า Modal)
            double maxWidth = constraints.maxWidth;
            double maxHeight = constraints.maxHeight;

            // 2. คำนวณหา "ขนาดรูปภาพที่จะถูกวาดจริง" ภายในกรอบนั้น (อิงจาก BoxFit.contain)
            double imageRatio = originalWidth / originalHeight;
            double renderWidth, renderHeight;

            if (maxWidth / maxHeight > imageRatio) {
              renderHeight = maxHeight;
              renderWidth = maxHeight * imageRatio;
            } else {
              renderWidth = maxWidth;
              renderHeight = maxWidth / imageRatio;
            }

            // 3. คำนวณ Scale ของพิกัดให้สัมพันธ์กับรูปที่ถูกบีบ/ขยายลงในกรอบ
            double scaleX = renderWidth / originalWidth;
            double scaleY = renderHeight / originalHeight;

            return SizedBox(
              width: renderWidth,
              height: renderHeight,
              child: Stack(
                children: [
                  // แสดงรูปให้พอดีกับขนาดที่คำนวณได้
                  Image.file(
                    imageFile,
                    width: renderWidth,
                    height: renderHeight,
                    fit: BoxFit.fill, // ใช้ fill เพราะเราคุมขนาดด้วย SizedBox แล้ว
                  ),
                  // วาด Bounding Box
                  ...items.where((it) => it.boundingBox != null).map((it) {
                    final box = it.boundingBox!;
                    const double paddingX = 8.0; // ขยายออกด้านข้าง
                    const double paddingY = 4.0; // ขยายออกด้านบน-ล่าง

                    // 2. คำนวณพิกัดใหม่ให้ครอบคลุมพื้นที่กว้างขึ้น
                    double left = (box.x * scaleX) - (paddingX / 2);
                    double top = (box.y * scaleY) - (paddingY / 2);
                    double width = (box.w * scaleX) + paddingX;
                    double height = (box.h * scaleY) + paddingY;

                    return Positioned(
                      left: left,
                      top: top,
                      width: width,
                      height: height,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.8),
                            width: 1.5, // ปรับเส้นให้เล็กลงในหน้าพรีวิวเล็ก
                          ),
                          color: Colors.red.withOpacity(0.1),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}