import cv2
import numpy as np
import tempfile

def deskew_image(image):
    """สำหรับแก้ภาพเอียง (Deskewing)"""
    img_copy = image.copy()
    
    # แปลงเป็นขาวดำแบบกลับสี (ข้อความสีขาว พื้นหลังสีดำ) เพื่อหาพิกัด
    _, thresh = cv2.threshold(img_copy, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    
    # หาพิกัด (x, y) ของจุดที่เป็นข้อความทั้งหมด
    coords = np.column_stack(np.where(thresh > 0))
    
    # หาค่ากรอบสี่เหลี่ยมที่ครอบข้อความทั้งหมด (จะได้องศาความเอียง)
    angle = cv2.minAreaRect(coords)[-1]
    
    # ปรับองศาให้อยู่ในระนาบ
    if angle < -45:
        angle = -(90 + angle)
    else:
        angle = -angle
        
    # ถ้าเอียงน้อยกว่า 0.5 องศา ถือว่าตรง
    if abs(angle) < 0.5:
        return image
    
    # คำนวณจุดกึ่งกลางและหมุนภาพ
    (h, w) = image.shape[:2]
    center = (w // 2, h // 2)
    M = cv2.getRotationMatrix2D(center, angle, 1.0)
    
    # หมุนภาพแล้วเติมขอบด้วยสีขาว
    rotated = cv2.warpAffine(image, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.Border_REPLICATE)
    return rotated

def preprocess_receipt_image(image_bytes: bytes) -> str:
    """รับไฟล์รูปดิบมาทำความสะอาดแล้วคืนค่าเป็น Path ของไฟล์ชั่วคราว"""
    
    # โหลดภาพจาก Memory (Bytes) โดยตรงไม่ต้องเซฟลงดิสก์ก่อน
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if img is None:
        raise ValueError("ไม่สามารถอ่านไฟล์รูปได้")
    
    # แปลงเป็นสีเทา
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    deskewed = deskew_image(gray)
    
    # ดึงความชัด ช่วยให้หมึกจางๆ บนสลิป โผล่ขึ้นมา
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    enhanced = clahe.apply(deskewed)
    
    # เบลอเล็กน้อย เพื่อลบเม็ดสีรบกวน
    blurred = cv2.GaussianBlur(enhanced, (5, 5), 0)
    
    # แยกข้อความกับพื้นหลัง (Adaptive Thresholding)
    # block_size =31, c=15 เป็นค่าที่เหมาะกับสลิปที่มีเงา
    binary = cv2.adaptiveThreshold(
        blurred, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        31, 15
    )
    
    # บันทึกไฟล์ชั่วคราว .png เพราะว่าเก็บละเอียด text ดีกว่า .jpg
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".png")
    cv2.imwrite(tmp.name, binary)
    
    cv2.imwrite("debug_output.png", binary)
    
    return tmp.name
    
    