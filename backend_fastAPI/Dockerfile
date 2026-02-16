# backend_fastAPI/Dockerfile

# ใช้ Python เวอร์ชันเดียวกับที่คุณเขียน (แนะนำ 3.10 หรือ 3.11)
FROM python:3.10-slim

# ตั้งค่า Working Directory ใน Container
WORKDIR /app

# (สำคัญ) ลง dependencies สำหรับ OCR และ System
# ถ้าคุณใช้ library จัดการภาพ (เช่น opencv) บรรทัดนี้จำเป็นมากบน Linux
# RUN apt-get update && apt-get install -y \
#     libgl1-mesa-glx \
#     libglib2.0-0 \
#     && rm -rf /var/lib/apt/lists/*

# Copy ไฟล์ requirements.txt เข้าไปก่อน (เพื่อ cache layer)
COPY requirements.txt .

# Install Python Libraries
RUN pip install --no-cache-dir -r requirements.txt

# Copy โค้ดทั้งหมดในโฟลเดอร์ปัจจุบันเข้าไป
COPY . .

# คำสั่งรัน Server (ปรับ command ตามที่คุณใช้จริง เช่น uvicorn)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]