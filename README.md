
 📱 Flutter Offline-Capable Form App with Notifications

A Flutter mobile application that allows users to submit form data, even offline. It syncs with Firebase Firestore when online and uses Firebase Cloud Messaging (FCM) to receive push notifications, triggered via a Flask backend.



 🚀 Features

- 📝 Form submission and review
- 🔄 Offline support using Hive local storage
- ☁️ Syncs with Firestore when connectivity is restored
- 🔔 Push notifications using FCM and Flask
- 🔐 Firebase Authentication
- 📃 Separate screens for:
  - User form
  - Submission list
  - Review screen
- ✅ Auto-sync on app startup and connectivity changes
- 🧠 Prevents duplicate Firestore entries during sync



 📦 Tech Stack

| Layer        | Technology                   |
|--------------|------------------------------|
| Frontend     | Flutter (Dart)               |
| Backend API  | Flask                        |
| Realtime DB  | Firebase Firestore           |
| Auth         | Firebase Authentication      |
| Offline DB   | Hive (NoSQL local DB)        |
| Notifications| Firebase Cloud Messaging     |



 🛠 Setup Instructions

 1. Flutter Setup

bash
flutter pub get
flutter run
`

Ensure you have:

* Firebase configured via `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
* Internet permission in `AndroidManifest.xml`

 2. Flask Backend (For Notifications)

bash
cd flask_backend
pip install -r requirements.txt
python app.py


Configure your FCM server key and endpoint in the Flask server.



 🔧 Configuration

* Add your `google-services.json` in `android/app/`
* Set up Firebase Authentication (Email/Password)
* Firestore Rules Example:

js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/entries/{entryId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /reviews/{reviewId} {
      allow read, write: if request.auth != null && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
  }
}




 📷 UI Screenshots

> Example:

![Screenshot 2025-06-26 145832](https://github.com/user-attachments/assets/41ee127a-8d49-4f0f-9a4e-e0be47a5444f)
![Screenshot 2025-06-26 145822](https://github.com/user-attachments/assets/9f7b028c-5a9b-4d14-9328-ee0a31508c2a)
![Screenshot 2025-06-26 145242](https://github.com/user-attachments/assets/d56e1a00-1d31-4c2c-8e08-246bc7398fc5)
![Screenshot 2025-06-26 145129](https://github.com/user-attachments/assets/1cef7850-7934-465d-b084-c2d8ec763838)
![Screenshot 2025-06-26 145111](https://github.com/user-attachments/assets/f0968ec6-70fe-4070-a945-ca9dd9b6b35b)
![Screenshot 2025-06-26 145057](https://github.com/user-attachments/assets/65d9dc55-b78d-4ce7-ba3c-fe33afb84728)






 📂 Folder Structure


lib/

├── main.dart                        # App entry point and route configuration

├── firebase_options.dart            # Firebase config (generated via FlutterFire CLI)

├── login_page.dart                  # User login screen with Firebase Auth

├── edit_profile.dart                # User profile edit screen

├── my_submissions.dart              # Displays user’s submitted forms

├── review_screen.dart               # Admin review list screen

├── review_details.dart              # Detailed view of individual reviews

├── user_info.dart                   # Hive model for offline caching

├── user_info.g.dart                 # Generated Hive adapter (do not edit)






 🧠 Known Limitations

* Notifications require active internet and FCM setup
* If app is force-closed before sync, unsynced data may remain
* Duplicate prevention logic relies on proper Hive sync state tracking



 ✍️ Author

Akash Bhilwande
GitHub: [@Akashbhilwande](https://github.com/Akashbhilwande)



