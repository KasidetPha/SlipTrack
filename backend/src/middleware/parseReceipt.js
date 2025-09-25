/**
 * ฟังก์ชันนี้จะพยายามดึงสินค้า + ยอดรวม จาก text OCR
 * (จริง ๆ regex ต้องปรับตาม format ใบเสร็จร้านต่าง ๆ)
 */
function parseReceipt(text) {
  const lines = text.split('\n').map(l => l.trim()).filter(l => l);

  const items = [];
  let total = 0;

  lines.forEach(line => {
    // สมมติว่า format = ชื่อสินค้า จำนวน x ราคา รวม
    // เช่น "น้ำดื่ม 2 10.00 20.00"
    const match = line.match(/^(.+?)\s+(\d+)\s+([\d.]+)\s+([\d.]+)$/);
    if (match) {
      items.push({
        name: match[1],
        qty: parseInt(match[2]),
        unitPrice: parseFloat(match[3]),
        lineTotal: parseFloat(match[4])
      });
      total += parseFloat(match[4]);
    }

    // หาคำว่า TOTAL หรือ ยอดรวม
    if (/TOTAL|ยอดรวม/i.test(line)) {
      const num = line.match(/([\d.]+)/);
      if (num) total = parseFloat(num[1]);
    }
  });

  return {
    merchant: 'Unknown',
    date: new Date().toISOString().split('T')[0],
    currency: 'THB',
    paymentMethod: 'CASH',
    items,
    summary: {
      subtotal: total,
      vat: +(total * 0.07).toFixed(2),
      total: +(total * 1.07).toFixed(2)
    }
  };
}

module.exports = parseReceipt;
