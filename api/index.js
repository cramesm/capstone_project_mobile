// Vercel serverless entry point – dynamically imports the Express app
let handler;

module.exports = async function (req, res) {
  if (!handler) {
    try {
      const mod = await import('../backend/src/server.js');
      handler = mod.default || mod.handler;
    } catch (err) {
      console.error('Failed to import backend server:', err);
      res.status(500).json({ success: false, message: err.message });
      return;
    }
  }
  return handler(req, res);
};
