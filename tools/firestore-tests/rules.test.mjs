import { before, after, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';

let env;
const student = { name: 'Sinh viên mẫu', major: 'CNTT', age: 21, classId: 'CNTT01', email: '' };
const grade = { studentId: 'SV1', subjectId: 'M1', semester: '2026-1', score: 8.5 };
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-qlsv', firestore: {
    rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
  }});
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/manager'), { email: 'manager@example.com', displayName: 'Quản lý', role: 'manager' });
    await setDoc(doc(db, 'classes/CNTT01'), {name: 'CNTT 01', major: 'CNTT', cohort: 'K17'});
    await setDoc(doc(db, 'students/SV1'), student);
    await setDoc(doc(db, 'subjects/M1'), {name: 'Di động', credits: 3});
  });
});
const manager = () => env.authenticatedContext('manager').firestore();
test('Unauthenticated users cannot read or write student data', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'students/SV1')));
  await assertFails(setDoc(doc(db, 'students/SV2'), student));
});
test('Signing in alone does not grant manager access or allow self-promotion', async () => {
  const db = env.authenticatedContext('outsider').firestore();
  await assertFails(getDoc(doc(db, 'students/SV1')));
  await assertFails(setDoc(doc(db, 'users/outsider'), {email: 'o@example.com', displayName: 'O', role: 'manager'}));
});
test('Manager can read and write valid data in all academic collections', async () => {
  const db = manager();
  await assertSucceeds(getDoc(doc(db, 'students/SV1')));
  await assertSucceeds(setDoc(doc(db, 'students/SV2'), student));
  await assertSucceeds(setDoc(doc(db, 'classes/CNTT02'), {name: 'CNTT 02', major: 'CNTT', cohort: 'K17'}));
  await assertSucceeds(setDoc(doc(db, 'subjects/M2'), {name: 'CSDL', credits: 3}));
  await assertSucceeds(setDoc(doc(db, 'grades/SV1~M1~2026-1'), grade));
});
test('Reject malformed documents, invalid scores and broken references', async () => {
  const db = manager();
  await assertFails(setDoc(doc(db, 'students/SV2'), {...student, classId: 'MISSING'}));
  await assertFails(setDoc(doc(db, 'students/SV2'), {...student, age: -1}));
  await assertFails(setDoc(doc(db, 'students/SV2'), {...student, name: '   '}));
  await assertFails(setDoc(doc(db, 'students/SV2'), {...student, secret: 'unexpected'}));
  await assertFails(setDoc(doc(db, 'subjects/M2'), {name: 'CSDL', credits: 1.5}));
  await assertFails(setDoc(doc(db, 'grades/SV1~M1~2026-1'), {...grade, score: 11}));
  await assertFails(setDoc(doc(db, 'grades/SV2~M1~2026-1'), {...grade, studentId: 'SV2'}));
  await assertFails(setDoc(doc(db, 'grades/wrong-id'), grade));
});
test('Managers may change their name but not permissions or other profiles', async () => {
  const db = manager();
  await assertSucceeds(updateDoc(doc(db, 'users/manager'), {displayName: 'Tên mới'}));
  await assertFails(updateDoc(doc(db, 'users/manager'), {role: 'admin'}));
  await assertFails(updateDoc(doc(db, 'users/manager'), {email: 'other@example.com'}));
  await assertFails(setDoc(doc(db, 'users/other'), {displayName: 'Other', email: 'o@example.com', role: 'manager'}));
});
test('Deletion is closed until the related-data workflow is implemented', async () => {
  await assertFails(deleteDoc(doc(manager(), 'students/SV1')));
});
