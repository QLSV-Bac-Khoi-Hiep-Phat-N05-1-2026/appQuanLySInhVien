import {randomBytes} from 'node:crypto';
import {services,sendPasswordSetup} from './firebase.mjs';
import {email,baseProfile} from './domain.mjs';
const loginEmail=email(process.argv[2]);
const {db,auth,projectId}=services();
const existingAdmin=await db.collection('users').where('role','==','admin').limit(1).get();
let user;try{user=await auth.getUserByEmail(loginEmail);}catch(e){if(e.code!=='auth/user-not-found')throw e;}
if(!existingAdmin.empty&&existingAdmin.docs[0].id!==user?.uid)throw Error('An Admin already exists. Use its account to administer this project.');
if(user){const profile=(await db.doc(`users/${user.uid}`).get()).data();if(profile&&profile.role!=='admin')throw Error('Existing non-admin account: explicit migration is required.');}
else user=await auth.createUser({email:loginEmail,displayName:'Quản trị viên',password:randomBytes(32).toString('base64url')});
await db.doc(`users/${user.uid}`).set(baseProfile(loginEmail,user.displayName||'Quản trị viên','admin'));
let invitationSent=true;try{await sendPasswordSetup(loginEmail,projectId);}catch{invitationSent=false;}
console.log(JSON.stringify({uid:user.uid,email:loginEmail,role:'admin',invitationSent}));
