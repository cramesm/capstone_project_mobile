export default async function handler(req, res) {
  try {
    const server = await import('../src/server.js');
    return server.default(req, res);
  } catch (error) {
    console.error("DEBUG ERROR:", error);
    res.status(500).json({
      error: error.message,
      stack: error.stack,
      name: error.name
    });
  }
}
