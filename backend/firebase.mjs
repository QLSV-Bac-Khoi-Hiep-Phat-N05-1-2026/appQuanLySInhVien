import {initializeApp, getApps, applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
import {Firestore} from '@google-cloud/firestore';
import {GoogleAuth} from 'google-auth-library';
import {createRequire} from 'node:module';
import {readFileSync} from 'node:fs';
const require = createRequire(import.meta.url);
export function services() {
  const emulator = Boolean(process.env.FIREBASE_AUTH_EMULATOR_HOST || process.env.FIRESTORE_EMULATOR_HOST);
  const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT_ID;
  if (!projectId) throw Error('Set FIREBASE_PROJECT_ID (demo-qlsv for emulator).');
  if (emulator && (!projectId.startsWith('demo-') || !process.env.FIREBASE_AUTH_EMULATOR_HOST || !process.env.FIRESTORE_EMULATOR_HOST)) throw Error('Use both emulators and a demo- project.');
  let credential;
  let localGoogleAuth;
  if (emulator) credential = applicationDefault();
  else if (process.env.USE_FIREBASE_CLI_CREDENTIALS === 'true') {
    if ((process.env.HOST || '127.0.0.1') !== '127.0.0.1') throw Error('Local CLI credentials require loopback binding.');
    const cli = require('../tools/firestore-tests/node_modules/firebase-tools/lib/auth.js');
    const account = cli.getProjectDefaultAccount(process.cwd()) || cli.getGlobalDefaultAccount();
    if (!account?.tokens?.refresh_token) throw Error('Run firebase login locally, or configure ADC.');
    const cliApi = require('../tools/firestore-tests/node_modules/firebase-tools/lib/api.js');
    localGoogleAuth = new GoogleAuth({credentials:{type:'authorized_user',client_id:cliApi.clientId(),client_secret:cliApi.clientSecret(),refresh_token:account.tokens.refresh_token},scopes:['https://www.googleapis.com/auth/cloud-platform']});
    credential = {getAccessToken: async()=>{
      const t=await cli.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
      return {access_token:t.access_token,expires_in: Math.max(60, Math.floor(((t.expires_at || Date.now()+3600000)-Date.now())/1000))};
    }};
  } else credential=applicationDefault();
  const app=getApps()[0] || initializeApp({projectId,credential});
  const db=localGoogleAuth ? new Firestore({projectId,auth:localGoogleAuth}) : getFirestore(app);
  return {db,auth:getAuth(app),projectId,emulator};
}
export function publicApiKey() {
  if (process.env.FIREBASE_WEB_API_KEY) return process.env.FIREBASE_WEB_API_KEY;
  try { return JSON.parse(readFileSync(new URL('../android/app/google-services.json',import.meta.url),'utf8')).client[0].api_key[0].current_key; }
  catch { throw Error('Set FIREBASE_WEB_API_KEY.'); }
}
export async function sendPasswordSetup(email, projectId) {
  const host=process.env.FIREBASE_AUTH_EMULATOR_HOST;
  let key = process.env.FIREBASE_WEB_API_KEY;
  if (!host && !key) {
    const token = await getApps()[0].options.credential.getAccessToken();
    const configResponse = await fetch(`https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`, {headers:{Authorization: 'Bearer '+token.access_token}});
    if (!configResponse.ok) throw Error('Không đọc được cấu hình email Firebase.');
    key = (await configResponse.json()).client?.apiKey;
    if (!key) throw Error('Thiếu Firebase browser API key cho email đặt mật khẩu.');
  }
  const url=host ? `http://${host}/identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=fake-key` : `https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${key}`;
  const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({requestType:'PASSWORD_RESET',email, ...(host?{targetProjectId:projectId}:{})})});
  if(!response.ok) throw Error('Không gửi được email đặt mật khẩu.');
}
