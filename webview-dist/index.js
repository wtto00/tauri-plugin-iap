function e(e,t,n,r){return new(n||(n=Promise))((function(u,i){function o(e){try{c(r.next(e))}catch(e){i(e)}}function a(e){try{c(r.throw(e))}catch(e){i(e)}}function c(e){var t;e.done?u(e.value):(t=e.value,t instanceof n?t:new n((function(e){e(t)}))).then(o,a)}c((r=r.apply(e,t||[])).next())}))}function t(e,t){var n,r,u,i,o={label:0,sent:function(){if(1&u[0])throw u[1];return u[1]},trys:[],ops:[]};return i={next:a(0),throw:a(1),return:a(2)},"function"==typeof Symbol&&(i[Symbol.iterator]=function(){return this}),i;function a(a){return function(c){return function(a){if(n)throw new TypeError("Generator is already executing.");for(;i&&(i=0,a[0]&&(o=0)),o;)try{if(n=1,r&&(u=2&a[0]?r.return:a[0]?r.throw||((u=r.return)&&u.call(r),0):r.next)&&!(u=u.call(r,a[1])).done)return u;switch(r=0,u&&(a=[2&a[0],u.value]),a[0]){case 0:case 1:u=a;break;case 4:return o.label++,{value:a[1],done:!1};case 5:o.label++,r=a[1],a=[0];continue;case 7:a=o.ops.pop(),o.trys.pop();continue;default:if(!(u=o.trys,(u=u.length>0&&u[u.length-1])||6!==a[0]&&2!==a[0])){o=0;continue}if(3===a[0]&&(!u||a[1]>u[0]&&a[1]<u[3])){o.label=a[1];break}if(6===a[0]&&o.label<u[1]){o.label=u[1],u=a;break}if(u&&o.label<u[2]){o.label=u[2],o.ops.push(a);break}u[2]&&o.ops.pop(),o.trys.pop();continue}a=t.call(e,o)}catch(e){a=[6,e],r=0}finally{n=u=0}if(5&a[0])throw a[1];return{value:a[0]?a[1]:void 0,done:!0}}([a,c])}}}function n(e,t=!1){const n=window.crypto.getRandomValues(new Uint32Array(1))[0],r=`_${n}`;return Object.defineProperty(window,r,{value:n=>(t&&Reflect.deleteProperty(window,r),null==e?void 0:e(n)),writable:!1,configurable:!0}),n}async function r(e,t={}){return new Promise(((r,u)=>{const i=n((e=>{r(e),Reflect.deleteProperty(window,`_${o}`)}),!0),o=n((e=>{u(e),Reflect.deleteProperty(window,`_${i}`)}),!0);window.__TAURI_IPC__({cmd:e,callback:i,error:o,...t})}))}async function u(e){return r("tauri",e)}async function i(e,t,r){return u({__tauriModule:"Event",message:{cmd:"listen",event:e,windowLabel:t,handler:n(r)}}).then((t=>async()=>async function(e,t){return u({__tauriModule:"Event",message:{cmd:"unlisten",event:e,eventId:t}})}(e,t)))}var o,a,c;async function s(e,t){return i(e,null,t)}function l(){return e(this,void 0,void 0,(function(){return t(this,(function(e){switch(e.label){case 0:return[4,r("plugin:iap|can_make_payments")];case 1:return[2,e.sent()]}}))}))}function d(n){return e(this,void 0,void 0,(function(){return t(this,(function(e){switch(e.label){case 0:return[4,r("plugin:iap|query_products",{identifiers:n})];case 1:return[2,e.sent()]}}))}))}function f(n){return e(this,void 0,void 0,(function(){return t(this,(function(e){switch(e.label){case 0:return[4,r("plugin:iap|restore_purchases")];case 1:return e.sent(),[2]}}))}))}function p(n){return e(this,void 0,void 0,(function(){return t(this,(function(e){switch(e.label){case 0:return[4,s("plugin:iap_products-updated",n)];case 1:return[2,e.sent()]}}))}))}function _(n){return e(this,void 0,void 0,(function(){return t(this,(function(e){switch(e.label){case 0:return[4,s("plugin:iap_exception",n)];case 1:return[2,e.sent()]}}))}))}"function"==typeof SuppressedError&&SuppressedError,function(e){e.WINDOW_RESIZED="tauri://resize",e.WINDOW_MOVED="tauri://move",e.WINDOW_CLOSE_REQUESTED="tauri://close-requested",e.WINDOW_CREATED="tauri://window-created",e.WINDOW_DESTROYED="tauri://destroyed",e.WINDOW_FOCUS="tauri://focus",e.WINDOW_BLUR="tauri://blur",e.WINDOW_SCALE_FACTOR_CHANGED="tauri://scale-change",e.WINDOW_THEME_CHANGED="tauri://theme-changed",e.WINDOW_FILE_DROP="tauri://file-drop",e.WINDOW_FILE_DROP_HOVER="tauri://file-drop-hover",e.WINDOW_FILE_DROP_CANCELLED="tauri://file-drop-cancelled",e.MENU="tauri://menu",e.CHECK_UPDATE="tauri://update",e.UPDATE_AVAILABLE="tauri://update-available",e.INSTALL_UPDATE="tauri://update-install",e.STATUS_UPDATE="tauri://update-status",e.DOWNLOAD_PROGRESS="tauri://update-download-progress"}(o||(o={})),function(e){e.PAY_AS_YOU_GO="PayAsYouGo",e.UP_FRONT="UpFront",e.FREE_TRIAL="FreeTrial"}(a||(a={})),function(e){e.QueryProducts="QueryProducts"}(c||(c={}));export{c as ExceptionType,a as PaymentMode,l as canMakePayments,_ as listenException,p as listenProductsUpdated,f as restorePurchases,d as startQueryProducts};
