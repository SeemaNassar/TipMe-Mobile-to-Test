// Import and configure the Firebase SDK
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyCIOCINZO8P2GVm07kIhrqJjZhsSM5GhgU",
  authDomain: "tipme-13a0c.firebaseapp.com",
  projectId: "tipme-13a0c",
  storageBucket: "tipme-13a0c.firebasestorage.app",
  messagingSenderId: "90241543608",
  appId: "1:90241543608:web:bcf4b40f1580d94f98b34d"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
