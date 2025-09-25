// backend/src/utils/parseBankSlip.js
function normalizeText(raw) {
  const thaiToArabic = s => s.replace(/[๐-๙]/g, d => '๐๑๒๓๔๕๖๗๘๙'.indexOf(d));
  return thaiToArabic(raw || '')
    .replace(/\r/g,'')
    .replace(/[ \t]+/g,' ')
    .replace(/\n{2,}/g,'\n')
    .trim();
}
const rxTime = /(\d{1,2}:\d{2}(?::\d{2})?)/;
const rxDateISO = /(\d{4}[-/]\d{1,2}[-/]\d{1,2})/;
function toISODateFromThai(str){
  const mths = {'ม.ค.':'01','ก.พ.':'02','มี.ค.':'03','เม.ย.':'04','พ.ค.':'05','มิ.ย.':'06',
    'ก.ค.':'07','ส.ค.':'08','ก.ย.':'09','ต.ค.':'10','พ.ย.':'11','ธ.ค.':'12'};
  const m = /(\d{1,2})\s*(ม\.ค\.|ก\.พ\.|มี\.ค\.|เม\.ย\.|พ\.ค\.|มิ\.ย\.|ก\.ค\.|ส\.ค\.|ก\.ย\.|ต\.ค\.|พ\.ย\.|ธ\.ค\.)\s*(\d{2,4})/i.exec(str||'');
  if(!m) return null;
  let [_,d,th,y]=m; d=d.padStart(2,'0'); const mo=mths[th]; y=+y; if(y>2400) y-=543; if(y<100) y+=2000;
  return `${y}-${mo}-${d}`;
}
function commonExtract(text){
  const bank =
    /SCB|ไทยพาณิชย์/i.test(text) ? 'SCB' :
    /KASIKORNBANK|KBank|กสิกร/i.test(text) ? 'KBank' :
    /KRUNGTHAI|KTB|กรุงไทย/i.test(text) ? 'KTB' :
    /KRUNGSRI|BAY|กรุงศรี/i.test(text) ? 'Krungsri' :
    /BANGKOK\s*BANK|BBL|กรุงเทพ/i.test(text) ? 'BangkokBank' : 'Unknown';
  const amount = (text.match(/(?:ยอดเงิน|จำนวนเงิน|Amount|THB)\s*:?[\s฿]*([0-9.,]+)/i)||[])[1];
  const date = (text.match(rxDateISO)||[])[1] || toISODateFromThai(text);
  const time = (text.match(rxTime)||[])[1] || null;
  const ref  = (text.match(/Ref(?:\.|erence)?\s*[:\-]?\s*([A-Za-z0-9\-]+)/i)||[])[1]
            || (text.match(/เลขที่อ้างอิง\s*[:\-]?\s*([A-Za-z0-9\-]+)/i)||[])[1] || null;
  return {
    bank,
    amount: amount ? parseFloat(amount.replace(/,/g,'')) : null,
    date, time, reference: ref,
  };
}
module.exports = function parseBankSlip(raw){
  const text = normalizeText(raw);
  const base = commonExtract(text);
  return {
    type: 'BANK_TRANSFER',
    bank: base.bank,
    amount: base.amount,
    currency: 'THB',
    date: base.date,
    time: base.time,
    datetime: base.date && base.time ? `${base.date}T${base.time}` : null,
    reference: base.reference,
    from: { name: (text.match(/(?:ผู้โอน|From)\s*:?\s*(.+)/i)||[])[1] || null },
    to:   { name: (text.match(/(?:ผู้รับ(?:เงิน|โอน)?|To)\s*:?\s*(.+)/i)||[])[1] || null },
  };
};
