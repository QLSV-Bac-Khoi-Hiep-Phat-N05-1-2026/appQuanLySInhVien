export class ApiError extends Error { constructor(status,message){super(message);this.status=status;} }
export function text(value, label, max=150) { if(typeof value!=='string'||!value.trim()||value.trim().length>max)throw new ApiError(400,`${label} không hợp lệ.`); return value.trim(); }
export function email(value){const v=text(value,'Email',254).toLowerCase();if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v))throw new ApiError(400,'Email không hợp lệ.');return v;}
export function code(value,label='Mã'){const v=text(value,label,80);if(!/^[A-Za-z0-9_-]{1,80}$/.test(v))throw new ApiError(400,`${label} không hợp lệ.`);return v;}
export function baseProfile(email,displayName,role,extra={}){return {email,displayName,role,status:'active',studentId:null,lecturerCode:'',phone:'',contactEmail:'',address:'',...extra};}
export function requireAdmin(profile){if(profile?.role!=='admin'||profile.status!=='active')throw new ApiError(403,'Chỉ Admin được thực hiện thao tác này.');}
export function requireActive(profile){if(!profile||profile.status!=='active'||!['admin','lecturer','student'].includes(profile.role))throw new ApiError(403,'Tài khoản chưa được cấp quyền hoặc đã bị khóa.');}
export function canManageStudent(profile,room){return profile.role==='admin'||(profile.role==='lecturer'&&room?.lecturerId===profile.uid);}
