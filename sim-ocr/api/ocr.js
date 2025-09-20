const { createWorker } = require('tesseract.js');

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const { image } = req.body || {};
    if (!image) {
      res.status(400).json({ error: 'No image provided' });
      return;
    }

    const buffer = Buffer.from(image, 'base64');

    const worker = createWorker();
    await worker.load();
    await worker.loadLanguage('eng');
    await worker.initialize('eng');

    const { data: { text } } = await worker.recognize(buffer);

    await worker.terminate();

    const lower = (text || '').toLowerCase();
    const simDetected = /surat izin mengemudi|republik indonesia|(^|\W)sim(\W|$)/i.test(lower);

    res.json({ text, simDetected });
  } catch (err) {
    console.error('OCR error', err);
    res.status(500).json({ error: 'OCR failed', details: String(err) });
  }
};
