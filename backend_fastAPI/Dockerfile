# backend_fastAPI/Dockerfile

# ใช้ Python เวอร์ชันเดียวกับที่คุณเขียน
FROM python:3.10-slim

# ตั้งค่า Working Directory ใน Container
WORKDIR /app

# (สำคัญ) ลง dependencies สำหรับ OCR และ System 
# ปลดคอมเมนต์ออกถ้าแอปต้องใช้ประมวลผลภาพหรือ OCR
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy ไฟล์ requirements.txt เข้าไปก่อน
COPY requirements.txt .

# Install Python Libraries
RUN pip install --no-cache-dir -r requirements.txt

# Copy โค้ดทั้งหมดเข้าไป
COPY . .

# คำสั่งรัน Server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]