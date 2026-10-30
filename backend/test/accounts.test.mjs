import {before,after,beforeEach,test} from 'node:test';
import assert from 'node:assert/strict';
import {services} from '../firebase.mjs';
import {baseProfile} from '../domain.mjs';
import {createAccountServer} from '../server.mjs';
let db,auth,server,base,sent=[];
const password='Testing.1234';
before(async()=>{
 if(!process.env.FIREBASE_AUTH_EMULATOR_HOST||!process.env.FIRESTORE_EMULATOR_HOST)throw Error('Run account tests with both Firebase emulators.');
 ({db,auth}=services());server=createAccountServer({db,auth,projectId:'demo-qlsv',sendSetup:async email=>{sent.push(email);}});
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));base=`http://127.0.0.1:${server.address().port}`;
});
after(async()=>{if(server)await new Promise(resolve=>server.close(resolve));if(db)await db.terminate();});
beforeEach(async()=>{
 const list=await auth.listUsers();if(list.users.length)await auth.deleteUsers(list.users.map(u=>u.uid));
 const collections=await db.listCollections();for(const c of collections){await db.recursiveDelete(c);}
 sent=[];
 for(const [uid,role,extra] of [['admin','admin',{}],['lecturer1','lecturer',{}],['lecturer2','lecturer',{}],['student1','student',{studentId:'SV1'}]]){
  await auth.createUser({uid,email:`${uid}@example.test`,password,emailVerified:true});
  await db.doc(`users/${uid}`).set(baseProfile(`${uid}@example.test`,uid,role,extra));
 }
 await db.doc('classes/A').set({name:'A',major:'CNTT',cohort:'K17',lecturerId:'lecturer1'});
 await db.doc('classes/B').set({name:'B',major:'CNTT',cohort:'K17',lecturerId:'lecturer2'});
 for(const [id,classId]of [['SV1','A'],['SV2','A'],['SV3','A'],['OTHER','B']])await db.doc(`students/${id}`).set({name:id,major:'CNTT',age:21,classId,email:'',...(id==='SV1'?{accountUid:'student1'}:{})});
});
async function token(uid){const response=await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-key`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:`${uid}@example.test`,password,returnSecureToken:true})});const data=await response.json();assert.ok(data.idToken,JSON.stringify(data));return data.idToken;}
async function post(path,body,uid){const t=uid?await token(uid):null;const r=await fetch(base+path,{method:'POST',headers:{'Content-Type':'application/json',...(t?{Authorization:`Bearer ${t}`}:{})},body:JSON.stringify(body)});const data=await r.json();return {...data,status:r.status};}
test('Unauthenticated users and students cannot provision accounts',async()=>{
 assert.equal((await post('/students/provision',{studentId:'SV2',email:'s2@example.test'})).status,401);
 assert.equal((await post('/students/provision',{studentId:'SV2',email:'s2@example.test'},'student1')).status,403);
});
test('Lecturer can provision own class only, with fixed student role and email setup',async()=>{
 assert.equal((await post('/students/provision',{studentId:'OTHER',email:'outside@example.test'},'lecturer1')).status,403);
 const result=await post('/students/provision',{studentId:'SV2',email:'s2@example.test',role:'admin'},'lecturer1');assert.equal(result.status,200);assert.equal(result.invitationSent,true);
 const profile=(await db.doc(`users/${result.uid}`).get()).data();assert.equal(profile.role,'student');assert.equal(profile.studentId,'SV2');assert.equal(profile.status,'active');assert.equal(profile.password,undefined);
 assert.equal((await db.doc('students/SV2').get()).data().accountUid,result.uid);assert.deepEqual(sent,['s2@example.test']);
});
test('Concurrent and repeated provisioning never creates duplicate identities',async()=>{
 const t=await token('lecturer1');const request=()=>fetch(base+'/students/provision',{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${t}`},body:JSON.stringify({studentId:'SV3',email:'s3@example.test'})});
 const responses=await Promise.all([request(),request()]);assert.ok(responses.some(r=>r.status===200));assert.ok(responses.every(r=>[200,409].includes(r.status)));
 const all=await auth.listUsers();assert.equal(all.users.filter(u=>u.email==='s3@example.test').length,1);
 const again=await post('/students/provision',{studentId:'SV3',email:'s3@example.test'},'lecturer1');assert.equal(again.status,200);assert.equal(again.alreadyExisted,true);
 assert.equal((await post('/students/provision',{studentId:'SV3',email:'new@example.test'},'lecturer1')).status,409);
});
test('Public lecturer registration is pending and cannot select admin role',async()=>{
 const body={email:'candidate@example.test',displayName:'Ứng viên',lecturerCode:'GV99',password};
 assert.equal((await post('/register-lecturer',{...body,role:'admin'})).status,400);
 const result=await post('/register-lecturer',body);assert.equal(result.status,201);
 const p=(await db.doc(`users/${result.uid}`).get()).data();assert.equal(p.role,'lecturer');assert.equal(p.status,'pending');assert.equal(p.password,undefined);
});
test('Only admin approves verified lecturers and assigns them to classes',async()=>{
 const candidate=await auth.createUser({email:'pending@example.test',password});await db.doc(`users/${candidate.uid}`).set(baseProfile(candidate.email,'Chờ duyệt','lecturer',{status:'pending',lecturerCode:'GV99'}));
 assert.equal((await post(`/lecturers/${candidate.uid}/decision`,{decision:'approve'},'lecturer1')).status,403);
 assert.equal((await post(`/lecturers/${candidate.uid}/decision`,{decision:'approve'},'admin')).status,409);
 await auth.updateUser(candidate.uid,{emailVerified:true});assert.equal((await post(`/lecturers/${candidate.uid}/decision`,{decision:'approve'},'admin')).status,200);
 assert.equal((await db.doc(`users/${candidate.uid}`).get()).data().status,'active');
 assert.equal((await post('/classes/A/lecturer',{lecturerId:candidate.uid},'lecturer1')).status,403);
 assert.equal((await post('/classes/A/lecturer',{lecturerId:candidate.uid},'admin')).status,200);
 assert.equal((await db.doc('classes/A').get()).data().lecturerId,candidate.uid);
});
test('Admin locks other accounts but cannot lock self or turn a student into lecturer',async()=>{
 assert.equal((await post('/users/admin/status',{status:'suspended'},'admin')).status,400);
 assert.equal((await post('/lecturers/student1/decision',{decision:'approve'},'admin')).status,409);
 assert.equal((await post('/users/lecturer1/status',{status:'suspended'},'admin')).status,200);
 assert.equal((await post('/students/provision',{studentId:'SV2',email:'s2@example.test'},'lecturer1')).status,403);
});
