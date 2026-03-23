import io
from PIL import Image, ImageOps

import io
from PIL import Image

def optimize_image_for_gemini(image_bytes: bytes, max_size: int = 1500, quality: int = 85) -> bytes:
    """
    ย่อขนาดและบีบอัดรูปภาพให้เหมาะกับการส่งให้ Gemini อ่าน (ลดเวลา Processing)
    """
    # โหลดรูปจาก Bytes
    img = Image.open(io.BytesIO(image_bytes))
    
    # แปลงเป็นโหมด RGB (เผื่อรูปต้นฉบับมาเป็น PNG แบบโปร่งใส หรือ RGBA)
    if img.mode != 'RGB':
        img = img.convert('RGB')
        
    # คำนวณสัดส่วนเพื่อย่อขนาด ถ้าด้านใดด้านหนึ่งยาวเกิน max_size
    width, height = img.size
    if width > max_size or height > max_size:
        if width > height:
            new_width = max_size
            new_height = int((max_size / width) * height)
        else:
            new_height = max_size
            new_width = int((max_size / height) * width)
            
        # ใช้ LANCZOS เพื่อรักษาความคมชัดของตัวหนังสือตอนย่อรูป
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # บีบอัดและเซฟลง BytesIO
    output_buffer = io.BytesIO()
    img.save(output_buffer, format="JPEG", quality=quality, optimize=True)
    
    return output_buffer.getvalue(), img.width, img.height

def preprocess_receipt_image(image_bytes: bytes, max_size=1536):
    """
    ปรับ Flow ใหม่: เลิกซูม เลิกทำขาวดำ
    แค่จัดการภาพไม่ให้ใหญ่เกินไปและถูกทิศทางเพื่อให้ AI อ่านไวขึ้น
    """
    image = Image.open(io.BytesIO(image_bytes))
    
    # 1. แก้ปัญหาภาพกลับหัว/หมุน จาก EXIF ของกล้องมือถือ
    image = ImageOps.exif_transpose(image)
    
    # 2. ถ้ารูปใหญ่เกินไป ให้ย่อรูปลงมา (Aspect Ratio คงเดิม)
    if max(image.size) > max_size:
        image.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
        
    # 3. แปลงกลับเป็น bytes เพื่อส่งคืน
    output_io = io.BytesIO()
    image.save(output_io, format="JPEG", quality=85)
    processed_bytes = output_io.getvalue()
    
    return processed_bytes, image.width, image.height