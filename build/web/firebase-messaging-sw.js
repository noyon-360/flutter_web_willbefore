importScripts(
  "https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js",
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js",
);

firebase.initializeApp({
  apiKey: "AIzaSyBC9KLA-BmMGGrAh_sEKVajNUAMuOaGokg",
  appId: "1:466892546022:web:7db86b825af5071fe40027",
  messagingSenderId: "466892546022",
  projectId: "smilestreats",
  authDomain: "smilestreats.firebaseapp.com",
  storageBucket: "smilestreats.firebasestorage.app",
  measurementId: "G-BTZ5026F3T",
});

const messaging = firebase.messaging();

// Optional: handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log(
    "[firebase-messaging-sw.js] Received background message ",
    payload,
  );
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/favicon.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
