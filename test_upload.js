const fs = require('fs');

async function run() {
  try {
    const email = 'test_upload_' + Date.now() + '@example.com';
    const password = 'Password1!';
    
    let res = await fetch('https://capstone-project-mobile.vercel.app/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ firstName: 'Test', lastName: 'User', email, password, role: 'alumni' })
    });
    let data = await res.json();
    let token = data.accessToken;
    if (!token) {
      res = await fetch('https://capstone-project-mobile.vercel.app/auth/login', {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password })
      });
      data = await res.json();
      token = data.accessToken;
    }

    const imgData = await (await fetch('https://www.w3.org/Graphics/JPEG/exif-orientation.jpg')).arrayBuffer();
    const imgBuffer = Buffer.from(imgData);

    const boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
    let payload = '--' + boundary + '\r\n';
    payload += 'Content-Disposition: form-data; name="paymentType"\r\n\r\nreceipt\r\n';
    payload += '--' + boundary + '\r\n';
    payload += 'Content-Disposition: form-data; name="docName"\r\n\r\ntor\r\n';
    payload += '--' + boundary + '\r\n';
    payload += 'Content-Disposition: form-data; name="purpose"\r\n\r\ntest\r\n';
    payload += '--' + boundary + '\r\n';
    payload += 'Content-Disposition: form-data; name="receipt"; filename="test.jpg"\r\n';
    payload += 'Content-Type: image/jpeg\r\n\r\n';
    
    const footer = '\r\n--' + boundary + '--\r\n';
    const finalPayload = Buffer.concat([Buffer.from(payload, 'utf8'), imgBuffer, Buffer.from(footer, 'utf8')]);
    
    res = await fetch('https://capstone-project-mobile.vercel.app/payments/receipt', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'multipart/form-data; boundary=' + boundary,
        'Content-Length': finalPayload.length
      },
      body: finalPayload
    });
    console.log('Upload status:', res.status, await res.text());
  } catch (e) {
    console.error(e);
  }
}
run();
