const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

async function sendOTP(email, otp) {
  await transporter.sendMail({
    from: `"TrapIT" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'Your TrapIT OTP Code',
    html: `
      <h2>TrapIT Verification Code</h2>
      <p>Your OTP code is:</p>
      <h1>${otp}</h1>
      <p>This code will expire in 5 minutes.</p>
    `,
  });
}

module.exports = { sendOTP };
