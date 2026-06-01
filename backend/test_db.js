import { MongoClient } from 'mongodb';
import dotenv from 'dotenv';
dotenv.config();

async function run() {
  const uri = process.env.MONGODB_URI;
  const client = new MongoClient(uri);
  try {
    await client.connect();
    // Check 'test' db
    const db = client.db('test');
    const students = db.collection('students');
    const alumni = db.collection('alumnis'); // Web backend usually uses plural for models

    const sUsers = await students.find({}, { projection: { email: 1, role: 1 } }).toArray();
    const aUsers = await alumni.find({}, { projection: { email: 1, role: 1 } }).toArray();
    
    // Also check 'verifitorweb' DB just in case
    const db2 = client.db('verifitorweb');
    const students2 = db2.collection('students');
    const sUsers2 = await students2.find({}, { projection: { email: 1 } }).toArray();

    console.log('test.students:', sUsers);
    console.log('test.alumnis:', aUsers);
    console.log('verifitorweb.students:', sUsers2);
  } finally {
    await client.close();
  }
}
run().catch(console.dir);
