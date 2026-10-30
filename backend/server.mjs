import {createServer} from 'node:http';
import {randomBytes,randomUUID,createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {services,sendPasswordSetup} from './firebase.mjs';
import {ApiError,text,email,code,baseProfile,requireAdmin,requireActive,canManageStudent} from './domain.mjs';

export function createAccountServer({db,auth,projectId,sendSetup = (value)=>sendPasswordSetup(value,projectId)}) {
  const rate=new Map();
  async function actor(req) {
    const header=req.headers.authorization || '';
    if(!header.startsWith('Bearer '))throw new ApiError(401,'Vui lòng đăng nhập.');
    let token;try{token=await auth.verifyIdToken(header.slice(7),true);}catch{throw new ApiError(401,'Phiên đăng nhập không hợp lệ.');}
    const snap=await db.doc(`users/${token.uid}`).get();
    const profile={...(snap.data()||{}),uid:token.uid};requireActive(profile);
    if(profile.role==='lecturer'&&!token.email_verified)throw new ApiError(403,'Giảng viên cần xác minh email.');
    return profile;
  }
  async function freshActor(tx,uid){const d=await tx.get(db.doc(`users/${uid}`));const p={...(d.data()||{}),uid};requireActive(p);return p;}
  async function checkStudent(tx,p,student) {
    if(!student)throw new ApiError(404,'Sinh viên không tồn tại.');
    const room=student.classId ? (await tx.get(db.doc(`classes/${student.classId}`))).data() : null;
    if(!canManageStudent(p,room))throw new ApiError(403,'Sinh viên không thuộc lớp được phân công.');
  }
  async function provision(p,b) {
    if(!['admin','lecturer'].includes(p.role))throw new ApiError(403,'Sinh viên không được cấp tài khoản.');
    const studentId=code(b.studentId,'Mã sinh viên'), loginEmail=email(b.email);
    const uid='student-'+createHash('sha256').update(studentId).digest('hex').slice(0,40);
    const ref=db.doc(`students/${studentId}`), operation=db.doc(`accountOperations/${studentId}`), token=randomUUID();
    const existing=await db.runTransaction(async tx=>{
      const caller=await freshActor(tx,p.uid), student=(await tx.get(ref)).data();
      await checkStudent(tx,caller,student);
      const op=(await tx.get(operation)).data();
      if(student.accountUid)return {uid:student.accountUid};
      if(op?.status==='needs-repair')throw new ApiError(409,'Yêu cầu cấp tài khoản cần Admin kiểm tra.');
      if(op?.status==='processing')throw new ApiError(409,'Đang cấp tài khoản cho sinh viên này. Vui lòng thử lại sau.');
      tx.set(operation,{status:'processing',token,uid,email:loginEmail,requestedBy:p.uid,startedAt:Date.now()});return null;
    });
    if(existing){const user=await auth.getUser(existing.uid);if(user.email?.toLowerCase()!==loginEmail)throw new ApiError(409,'Sinh viên đã liên kết với email đăng nhập khác.');let sent=true;try{await sendSetup(loginEmail);}catch{sent=false;}return {uid:user.uid,email:loginEmail,invitationSent:sent,alreadyExisted:true};}
    let created=false,committed=false;
    try {
      try {await auth.createUser({uid,email:loginEmail,password:randomBytes(32).toString('base64url')});created=true;}
      catch(e){if(e.code!=='auth/uid-already-exists')throw e;const u=await auth.getUser(uid);if(u.email?.toLowerCase()!==loginEmail)throw new ApiError(409,'Tài khoản cấp trước chưa được xử lý. Liên hệ Admin.');}
      await db.runTransaction(async tx=>{
        const caller=await freshActor(tx,p.uid), student=(await tx.get(ref)).data();await checkStudent(tx,caller,student);
        const op=(await tx.get(operation)).data(), profileRef=db.doc(`users/${uid}`), current=(await tx.get(profileRef)).data();
        if(op?.token!==token||op.status!=='processing')throw new ApiError(409,'Yêu cầu cấp tài khoản đã thay đổi.');
        if(student.accountUid&&student.accountUid!==uid)throw new ApiError(409,'Sinh viên đã được cấp tài khoản khác.');
        if(current&&(current.role!=='student'||current.studentId!==studentId))throw new ApiError(409,'Liên kết tài khoản không hợp lệ.');
        tx.set(profileRef,baseProfile(loginEmail,student.name,'student',{studentId}),{merge:true});
        tx.update(ref,{accountUid:uid});tx.update(operation,{status:'completed',completedAt:Date.now()});
      });
      committed=true;let sent=true;try{await sendSetup(loginEmail);}catch{sent=false;}
      return {uid,email:loginEmail,invitationSent:sent,alreadyExisted:false};
    } catch(e) {
      if(!committed){let cleaned=true;if(created){try{await auth.deleteUser(uid);}catch{cleaned=false;}}
        await db.runTransaction(async tx=>{const op=(await tx.get(operation)).data();if(op?.token===token)tx.update(operation,{status:cleaned?'failed':'needs-repair',failedAt:Date.now()});}).catch(()=>{});
      }
      throw e;
    }
  }
  return createServer(async(req,res)=>{
    res.setHeader('Content-Type','application/json; charset=utf-8');res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');
    const origin=req.headers.origin;const allowed=(process.env.ALLOWED_ORIGINS||'').split(',').filter(Boolean);
    if(origin&&!allowed.includes(origin)){res.writeHead(403);res.end(JSON.stringify({error:'Origin không được phép.'}));return;}
    if(origin){res.setHeader('Access-Control-Allow-Origin',origin);res.setHeader('Vary','Origin');res.setHeader('Access-Control-Allow-Headers','Authorization,Content-Type');res.setHeader('Access-Control-Allow-Methods','POST,OPTIONS');}
    if(req.method==='OPTIONS'){res.writeHead(204);res.end();return;}
    if(req.method==='GET'&&req.url==='/health'){res.end(JSON.stringify({ok:true,projectId}));return;}
    try {
      if(req.method!=='POST')throw new ApiError(405,'Phương thức không hỗ trợ.');
      const chunks=[];let size=0;for await(const chunk of req){size+=chunk.length;if(size>8192)throw new ApiError(413,'Yêu cầu quá lớn.');chunks.push(chunk);}
      const raw=Buffer.concat(chunks).toString('utf8');
      let b;try{b=JSON.parse(raw||'{}');}catch{throw new ApiError(400,'JSON không hợp lệ.');}
      const path=new URL(req.url,'http://localhost').pathname;
      if(path==='/register-lecturer'){
        const key=req.socket.remoteAddress||'local',now=Date.now(),limit=rate.get(key);
        if(limit&&now-limit.since<3600000&&limit.count>=10)throw new ApiError(429,'Đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.');
        rate.set(key,{since:limit&&now-limit.since<3600000?limit.since:now,count:limit&&now-limit.since<3600000?limit.count+1:1});
        if(rate.size>10000){for(const [k,v]of rate)if(now-v.since>3600000)rate.delete(k);}
        const loginEmail=email(b.email),name=text(b.displayName,'Họ tên'),lecturerCode=code(b.lecturerCode,'Mã giảng viên');
        if(typeof b.password!=='string'||b.password.length<8||b.password.length>128)throw new ApiError(400,'Mật khẩu cần 8–128 ký tự.');
        if(b.role!==undefined&&b.role!=='lecturer')throw new ApiError(400,'Không thể tự chọn vai trò.');
        const user=await auth.createUser({email:loginEmail,displayName:name,password:b.password});
        try{await db.doc(`users/${user.uid}`).create(baseProfile(loginEmail,name,'lecturer',{status:'pending',lecturerCode}));}
        catch(e){await auth.deleteUser(user.uid).catch(()=>{});throw e;}
        res.writeHead(201);res.end(JSON.stringify({uid:user.uid,email:loginEmail,status:'pending'}));return;
      }
      const p=await actor(req);let result={ok:true};
      let match;
      if(path==='/students/provision') result=await provision(p,b);
      else if((match=path.match(/^\/lecturers\/([^/]+)\/decision$/))){
        requireAdmin(p);const uid=text(decodeURIComponent(match[1]),'UID',128);if(uid.includes('/'))throw new ApiError(400,'UID không hợp lệ.');
        if(!['approve','reject'].includes(b.decision))throw new ApiError(400,'Quyết định không hợp lệ.');
        if(b.decision==='approve'&&!(await auth.getUser(uid)).emailVerified)throw new ApiError(409,'Giảng viên chưa xác minh email.');
        await db.runTransaction(async tx=>{requireAdmin(await freshActor(tx,p.uid));const ref=db.doc(`users/${uid}`),target=(await tx.get(ref)).data();
          if(target?.role!=='lecturer'||target.status!=='pending')throw new ApiError(409,'Hồ sơ không còn ở trạng thái chờ duyệt.');
          tx.update(ref,{status:b.decision==='approve'?'active':'rejected',reviewedBy:p.uid,reviewedAt:Date.now()});});
      } else if((match=path.match(/^\/classes\/([^/]+)\/lecturer$/))){
        requireAdmin(p);const classId=code(decodeURIComponent(match[1]),'Mã lớp'),uid=text(b.lecturerId,'Giảng viên',128);if(uid.includes('/'))throw new ApiError(400,'UID không hợp lệ.');
        await db.runTransaction(async tx=>{requireAdmin(await freshActor(tx,p.uid));const ref=db.doc(`classes/${classId}`),room=await tx.get(ref),teacher=(await tx.get(db.doc(`users/${uid}`))).data();
          if(!room.exists)throw new ApiError(404,'Lớp không tồn tại.');if(teacher?.role!=='lecturer'||teacher.status!=='active')throw new ApiError(409,'Giảng viên chưa được duyệt hoặc đã bị khóa.');
          tx.update(ref,{lecturerId:uid,lecturerName:teacher.displayName});});
      } else if((match=path.match(/^\/users\/([^/]+)\/status$/))){
        requireAdmin(p);const uid=text(decodeURIComponent(match[1]),'UID',128);if(uid.includes('/')||uid===p.uid)throw new ApiError(400,'Không thể khóa chính mình.');
        if(!['active','suspended'].includes(b.status))throw new ApiError(400,'Trạng thái không hợp lệ.');
        await db.runTransaction(async tx=>{requireAdmin(await freshActor(tx,p.uid));const ref=db.doc(`users/${uid}`),target=(await tx.get(ref)).data();if(!target||target.role==='admin'||['pending','rejected'].includes(target.status))throw new ApiError(409,'Tài khoản không thể thay trạng thái theo thao tác này.');tx.update(ref,{status:b.status});});
        if(b.status==='suspended')await auth.revokeRefreshTokens(uid);
      } else throw new ApiError(404,'Không tìm thấy chức năng.');
      res.end(JSON.stringify(result));
    } catch(e) {
      const duplicate=['auth/email-already-exists','auth/uid-already-exists'].includes(e.code);
      const status=e.status || (duplicate?409:500);
      res.writeHead(status);res.end(JSON.stringify({error:e.status?e.message:duplicate?'Email đã được sử dụng.':'Không thực hiện được yêu cầu. Vui lòng thử lại hoặc liên hệ Admin.'}));
      if(status>=500)console.error('Account operation failed',e.code||e.name);
    }
  });
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
  const dependencies=services();const port=Number(process.env.PORT||8787),host=process.env.HOST||'127.0.0.1';
  createAccountServer(dependencies).listen(port,host,()=>console.log(`Account API listening on ${host}:${port} (${dependencies.projectId})`));
}
