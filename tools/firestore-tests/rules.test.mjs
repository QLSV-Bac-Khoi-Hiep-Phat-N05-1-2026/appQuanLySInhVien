import {before,after,beforeEach,test} from 'node:test';
import {readFileSync} from 'node:fs';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {doc,getDoc,setDoc,updateDoc,deleteDoc,collection,query,where,getDocs} from 'firebase/firestore';
import {baseProfile} from '../../backend/domain.mjs';
let env;
const student={name:'Sinh viên mẫu',major:'CNTT',age:21,classId:'A',email:'',accountUid:'student1'};
const grade={studentId:'SV1',subjectId:'M1',semester:'2026-1',score:8.5};
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-qlsv',firestore:{rules:readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8')}});});
after(async()=>{await env?.cleanup();});
beforeEach(async()=>{await env.clearFirestore();await env.withSecurityRulesDisabled(async c=>{
 const db=c.firestore();
 for(const [uid,data] of [
 ['admin',baseProfile('admin@example.test','Admin','admin')],
 ['lecturer1',baseProfile('l1@example.test','GV1','lecturer')],
 ['lecturer2',baseProfile('l2@example.test','GV2','lecturer')],
 ['pending',baseProfile('pending@example.test','Chờ duyệt','lecturer',{status:'pending'})],
 ['suspended',baseProfile('locked@example.test','Đã khóa','lecturer',{status:'suspended'})],
 ['student1',baseProfile('s1@example.test','SV1','student',{studentId:'SV1'})],
 ['student2',baseProfile('s2@example.test','SV2','student',{studentId:'SV2'})],
 ])await setDoc(doc(db,`users/${uid}`),data);
 await setDoc(doc(db,'classes/A'),{name:'Lớp A',major:'CNTT',cohort:'K17',lecturerId:'lecturer1',lecturerName:'GV1'});
 await setDoc(doc(db,'classes/B'),{name:'Lớp B',major:'CNTT',cohort:'K17',lecturerId:'lecturer2',lecturerName:'GV2'});
 await setDoc(doc(db,'students/SV1'),student);
 await setDoc(doc(db,'students/SV2'),{...student,name:'SV khác',classId:'B',accountUid:'student2'});
 await setDoc(doc(db,'subjects/M1'),{name:'Di động',credits:3});
 await setDoc(doc(db,'grades/SV1~M1~2026-1'),grade);
 await setDoc(doc(db,'grades/SV2~M1~2026-1'),{...grade,studentId:'SV2'});
 });});
const db=(uid,verified=true)=>env.authenticatedContext(uid,{email_verified:verified}).firestore();
test('Guest and users without roles cannot read academic data or promote themselves',async()=>{
 await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'students/SV1')));
 await assertFails(setDoc(doc(db('outsider'),'users/outsider'),baseProfile('o@example.test','O','admin')));
 await assertFails(getDoc(doc(db('outsider'),'subjects/M1')));
});
test('Pending, suspended and unverified lecturers have no academic access',async()=>{
 for(const uid of ['pending','suspended']){await assertSucceeds(getDoc(doc(db(uid),`users/${uid}`)));await assertFails(getDoc(doc(db(uid),'students/SV1')));}
 await assertFails(getDoc(doc(db('lecturer1',false),'classes/A')));
});
test('Admin can read all academic data and manage subject catalogue',async()=>{
 await assertSucceeds(getDocs(collection(db('admin'),'students')));
 await assertSucceeds(getDocs(collection(db('admin'),'users')));
 await assertSucceeds(setDoc(doc(db('admin'),'subjects/M2'),{name:'Môn mới',credits:4}));
});
test('Lecturer queries are restricted to assigned classes',async()=>{
 const d=db('lecturer1');await assertSucceeds(getDocs(query(collection(d,'classes'),where('lecturerId','==','lecturer1'))));
 await assertSucceeds(getDocs(query(collection(d,'students'),where('classId','==','A'))));
 await assertFails(getDocs(collection(d,'students')));await assertFails(getDoc(doc(d,'students/SV2')));
 await assertFails(getDoc(doc(d,'classes/B')));
});
test('Lecturer can add/update students in own class but cannot move into another class or forge binding',async()=>{
 const d=db('lecturer1');await assertSucceeds(setDoc(doc(d,'students/SV3'),{...student,accountUid:null}));
 await assertFails(setDoc(doc(d,'students/SV4'),{...student,classId:'B',accountUid:null}));
 await assertFails(updateDoc(doc(d,'students/SV1'),{classId:'B'}));
 await assertFails(updateDoc(doc(d,'students/SV1'),{accountUid:'forged'}));
});
test('Student reads only their own record and grades, and their current class',async()=>{
 const d=db('student1');await assertSucceeds(getDoc(doc(d,'students/SV1')));await assertSucceeds(getDoc(doc(d,'classes/A')));
 await assertSucceeds(getDocs(query(collection(d,'grades'),where('studentId','==','SV1'))));
 await assertFails(getDoc(doc(d,'students/SV2')));await assertFails(getDoc(doc(d,'classes/B')));
 await assertFails(getDoc(doc(d,'grades/SV2~M1~2026-1')));await assertFails(getDocs(collection(d,'grades')));
});
test('Student may edit contact fields but never official identity, role, binding or grades',async()=>{
 const d=db('student1');await assertSucceeds(updateDoc(doc(d,'users/student1'),{phone:'0912345678',contactEmail:'personal@example.test',address:'Hà Nội'}));
 for(const patch of [{role:'admin'},{status:'pending'},{studentId:'SV2'},{email:'other@example.test'},{displayName:'Giả mạo'}])await assertFails(updateDoc(doc(d,'users/student1'),patch));
 await assertFails(updateDoc(doc(d,'users/student2'),{phone:'0912345678'}));
 await assertFails(updateDoc(doc(d,'students/SV1'),{classId:'B'}));
 await assertFails(updateDoc(doc(d,'grades/SV1~M1~2026-1'),{score:10}));
});
test('Contact input is validated at server',async()=>{
 const d=db('student1');await assertFails(updateDoc(doc(d,'users/student1'),{phone:'abc'}));
 await assertFails(updateDoc(doc(d,'users/student1'),{contactEmail:'bad'}));
 await assertFails(updateDoc(doc(d,'users/student1'),{address:'x'.repeat(301)}));
});
test('Only backend can approve users and assign lecturers, including for an Admin client',async()=>{
 await assertFails(updateDoc(doc(db('admin'),'users/pending'),{status:'active'}));
 await assertFails(updateDoc(doc(db('lecturer1'),'classes/A'),{lecturerId:'lecturer2'}));
 await assertFails(updateDoc(doc(db('admin'),'classes/A'),{lecturerId:'lecturer2'}));
 await assertFails(setDoc(doc(db('admin'),'classes/C'),{name:'C',major:'CNTT',cohort:'K17',lecturerId:'lecturer1'}));
 await assertSucceeds(setDoc(doc(db('admin'),'classes/C'),{name:'C',major:'CNTT',cohort:'K17'}));
});
test('Grade writes enforce own class, references, score and semester',async()=>{
 const d=db('lecturer1');await assertSucceeds(updateDoc(doc(d,'grades/SV1~M1~2026-1'),{score:9}));
 await assertFails(updateDoc(doc(d,'grades/SV2~M1~2026-1'),{score:9}));
 for(const score of [-1,11])await assertFails(updateDoc(doc(d,'grades/SV1~M1~2026-1'),{score}));
 for(const semester of ['2026-3','ABC','26-1'])await assertFails(setDoc(doc(d,`grades/SV1~M1~${semester}`),{...grade,semester}));
 await assertFails(setDoc(doc(d,'grades/SV1~NO~2026-1'),{...grade,subjectId:'NO'}));
});
test('Lecturers cannot change subject catalogue or read other lecturers profiles',async()=>{
 await assertSucceeds(getDoc(doc(db('lecturer1'),'subjects/M1')));
 await assertFails(setDoc(doc(db('lecturer1'),'subjects/M2'),{name:'Không được',credits:3}));
 await assertFails(getDoc(doc(db('lecturer1'),'users/lecturer2')));
});
test('Student and class deletion remain closed',async()=>{
 await assertFails(deleteDoc(doc(db('admin'),'students/SV1')));await assertFails(deleteDoc(doc(db('lecturer1'),'classes/A')));
});
