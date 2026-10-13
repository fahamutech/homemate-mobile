/*
 * Push notifications for the PWA (Firebase Cloud Messaging).
 *
 * firebase_messaging registers this file by its fixed name, at the site root.
 * It only receives pushes — it caches nothing, so it does not change how the
 * app updates (lib/core/app_update).
 *
 * While the app is open the push goes to the page, which shows its own banner.
 * In the background the SDK draws the notification from the push itself, and
 * a click opens the `fcm_options.link` the backend set: the app's
 * #/open-notification route, which lands on the screen the notice is about.
 *
 * The config is the web app's public Firebase config (lib/firebase_options.dart);
 * none of it is secret. The SDK version is the one firebase_core_web loads.
 */
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBRDzH_Thf8724QqJU6zp5HYPNljfJrJOU',
  appId: '1:776652031067:web:f4747e9116c4dead87ab7e',
  messagingSenderId: '776652031067',
  projectId: 'homematetz',
  authDomain: 'homematetz.firebaseapp.com',
  storageBucket: 'homematetz.firebasestorage.app',
});

firebase.messaging();
