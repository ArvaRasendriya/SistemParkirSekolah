import { VercelRequest, VercelResponse } from '@vercel/node';
import { createWorker } from 'tesseract.js';
import formidable from 'formidable';
import fs from 'fs';

export const config = {
  api: {
    bodyParser: false, // pakai formidable
  },
};

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Parse file upload pakai formidable
    const form = formidable({ multiples: false });
    const [fields, files]: any = await new Promise((resolve, reject) => {
      form.parse(req, (err, fields, files) => {
        if (err) reject(err);
        else resolve([fields, files]);
      });
    });

    const file = files.file?.[0] || files.file; // handle array / single
    if (!file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // OCR dengan tesseract
    const worker = await createWorker('eng'); // bisa tambahin 'ind' kalau install traineddata Indonesia
    const image = fs.readFileSync(file.filepath);
    const { data } = await worker.recognize(image);

    await worker.terminate();

    const text = data.text || '';
    const detected = _isSimText(text);

    return res.status(200).json({
      success: true,
      detected,
      text,
    });
  } catch (err: any) {
    console.error('OCR error', err);
    return res.status(500).json({ error: err.message || 'OCR failed' });
  }
}

// fungsi cek apakah teks mirip SIM
function _isSimText(text: string): boolean {
  const lower = text.toLowerCase();
  const hasSimPhrase =
    lower.includes('surat izin mengemudi') ||
    lower.includes('sim') ||
    lower.includes('surat izin');
  const hasRep = lower.includes('indonesia');
  const nikRegex = /\b\d{16}\b/;
  const hasNik = nikRegex.test(lower);
  return (hasSimPhrase && hasRep) || hasNik;
}
