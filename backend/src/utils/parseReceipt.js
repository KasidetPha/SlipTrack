// backend/src/utils/parseReceipt.js
const thaiDigitMap = { "๐":"0","๑":"1","๒":"2","๓":"3","๔":"4","๕":"5","๖":"6","๗":"7","๘":"8","๙":"9" };
const thaiMonthMap = { "ม.ค.":"01","ก.พ.":"02","มี.ค.":"03","เม.ย.":"04","พ.ค.":"05","มิ.ย.":"06","ก.ค.":"07","ส.ค.":"08","ก.ย.":"09","ต.ค.":"10","พ.ย.":"11","ธ.ค.":"12" };
const priceLike = /(?:(?:\d{1,3}(?:,\d{3})+)|\d+)(?:\.\d{1,2})?/;

const toArabicDigits = s => s.replace(/[๐-๙]/g, d => thaiDigitMap[d] || d);
const normalizeText = t => toArabicDigits(t).replace(/\r/g,"").replace(/[ \t]+/g," ").replace(/\u200B/g,"").trim();

const extractMerchant = (lines) => {
  for (let i=0;i<Math.min(lines.length,6);i++){
    const L = lines[i].trim();
    if (!L) continue;
    if (/ใบกำกับภาษี|TAX\s*INVOICE|RECEIPT|ใบเสร็จ/i.test(L)) continue;
    if (/[A-Za-zก-ฮ]/.test(L)) return L;
  }
  return null;
};

const extractDate = (all) => {
  const s = all;
  const th = /(\d{1,2})\s*(ม\.ค\.|ก\.พ\.|มี\.ค\.|เม\.ย\.|พ\.ค\.|มิ\.ย\.|ก\.ค\.|ส\.ค\.|ก\.ย\.|ต\.ค\.|พ\.ย\.|ธ\.ค\.)\s*(\d{2,4})/i.exec(s);
  if (th){ const d=th[1].padStart(2,"0"), m=thaiMonthMap[th[2]], y0=parseInt(th[3],10); let y=y0>2400?y0-543:(y0<100?2000+y0:y0); return `${y}-${m}-${d}`; }
  const dmy=/(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})/.exec(s);
  if (dmy){ const d=dmy[1].padStart(2,"0"), m=dmy[2].padStart(2,"0"); let y=parseInt(dmy[3],10); y=y>2400?y-543:(y<100?2000+y:y); return `${y}-${m}-${d}`;}
  const iso=/(\d{4})-(\d{2})-(\d{2})/.exec(s); if (iso) return iso[0];
  return null;
};

const extractTotals = (all) => {
  const s = all, num = m => parseFloat(m.replace(/[^0-9.]/g,"")) || null;
  const findAfter = (re) => {
    const mm = new RegExp(`${re.source}[^0-9]*(\\d+[\\.,]\\d{2}|\\d+)`,"i").exec(s);
    return mm ? num(mm[1]) : null;
  };
  const totalInc=/ยอดรวมสุทธิ|Total\\s*Due|Grand\\s*Total|Total\\s*\\(Incl\\.?\\s*VAT\\)|ยอดชำระ/i;
  const totalEx=/Subtotal|ยอดก่อนภาษี|ราคาสุทธิไม่รวมภาษี/i;
  const vat=/VAT|ภาษีมูลค่าเพิ่ม|แวต/i;
  return { subtotal: findAfter(totalEx), vat: findAfter(vat), total: findAfter(totalInc) };
};

const extractPayment = (all) => {
  if (/CASH|เงินสด/i.test(all)) return "CASH";
  if (/เครดิต|Credit\s*Card|VISA|MASTERCARD|AMEX/i.test(all)) return "CARD";
  if (/QR|PromptPay|พร้อมเพย์/i.test(all)) return "QR/PROMPTPAY";
  return null;
};

const median = (arr) => {
  if (!arr.length) return null;
  const a = arr.slice().sort((x,y)=>x-y);
  const m = Math.floor(a.length/2);
  return a.length%2 ? a[m] : (a[m-1]+a[m])/2;
};

const extractItemsFromBBoxes = (ocrLines) => {
  const items = [], tailXs = [], cleaned = [];
  const priceLikeRe = priceLike;

  for (const L of ocrLines) {
    const text = normalizeText(L.text || "");
    if (!text) continue;
    cleaned.push({ ...L, text });

    const words = (L.words || []).map(w => ({ text: normalizeText(w.text||""), bbox: w.bbox }));
    const numWords = words.filter(w => priceLikeRe.test(w.text));
    if (numWords.length) {
      const last = numWords.reduce((a,b)=> (a.bbox.x1>b.bbox.x1? a:b));
      tailXs.push(last.bbox.x1);
    }
  }
  const rightColX = tailXs.length ? median(tailXs) : null;

  for (const L of cleaned) {
    const t = L.text;
    if (/Total|Subtotal|VAT|ยอดรวม|ยอดสุทธิ|ยอดชำระ|ภาษี|เงินทอน|Change/i.test(t)) continue;

    const wds = (L.words || []).map(w => ({ text: normalizeText(w.text||""), bbox: w.bbox }));
    const numeric = wds.filter(w => priceLikeRe.test(w.text));
    let endPrice = null, endX = null;
    if (numeric.length) {
      const last = numeric.reduce((a,b)=> (a.bbox.x1>b.bbox.x1? a:b));
      endPrice = parseFloat(last.text.replace(/,/g,""));
      endX = last.bbox.x1;
    }
    const seemsRightAligned = rightColX ? endX && Math.abs(endX - rightColX) < 40 : !!endPrice;

    const m1 = new RegExp(`^(.*?)[\\s:]+(\\d+)\\s*[xX*×]\\s*(${priceLikeRe.source})(?:[\\s=]+(${priceLikeRe.source}))?$`).exec(t);
    if (m1 && seemsRightAligned) {
      const name = m1[1].trim();
      const qty = parseInt(m1[2], 10);
      const unitPrice = parseFloat(m1[3].replace(/,/g,""));
      const lineTotal = m1[4] ? parseFloat(m1[4].replace(/,/g,"")) : (qty * unitPrice);
      if (name) items.push({ name, qty, unitPrice: unitPrice || null, lineTotal: lineTotal || null });
      continue;
    }

    const m2 = new RegExp(`^(.*?)[\\s:]+(${priceLikeRe.source})$`).exec(t);
    if (m2 && seemsRightAligned) {
      const name = m2[1].trim();
      const price = parseFloat(m2[2].replace(/,/g,""));
      if (name && !/หมายเหตุ|โทร|Tax|เลขประจำตัว|เลขที่/i.test(name)) {
        items.push({ name, qty: 1, unitPrice: price, lineTotal: price });
      }
    }
  }
  return items;
};

function parseReceiptText(ocrObj) {
  const full = normalizeText(ocrObj.text || "");
  const plainLines = full.split("\n").map(x=>x.trim()).filter(Boolean);

  const merchant = extractMerchant(plainLines);
  const date = extractDate(full);
  const totals = extractTotals(full);
  const paymentMethod = extractPayment(full);
  const items = extractItemsFromBBoxes(ocrObj.lines || []);

  let subtotal = totals.subtotal;
  if (!subtotal && items.length) {
    subtotal = items.reduce((a,b)=> a + (b.lineTotal ?? b.unitPrice ?? 0), 0);
    subtotal = Math.round(subtotal*100)/100;
  }
  let total = totals.total;
  if (!total && subtotal != null) {
    const vat = totals.vat || 0;
    total = Math.round((subtotal + vat)*100)/100;
  }

  return {
    merchant: merchant || null,
    date: date || null,
    currency: "THB",
    paymentMethod,
    items,
    summary: { subtotal: subtotal ?? null, vat: totals.vat ?? null, total: total ?? null }
  };
}

// wrapper: ให้ controller เรียก parseReceipt(text) ได้เลย
function parseReceipt(text, ocrLines = []) {
  return parseReceiptText({ text, lines: ocrLines });
}
module.exports = parseReceipt;
// ถ้าจะใช้แบบ advance: module.exports.parseReceiptText = parseReceiptText;
