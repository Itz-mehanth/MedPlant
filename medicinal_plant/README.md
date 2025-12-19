# Medicinal Plant Application 🌿

A comprehensive Flutter application designed to help users identify, learn about, and trade medicinal plants. This app combines AI-powered identification with a vibrant community social feed and a dedicated marketplace for herbal products.

## 🚀 Key Features

*   **🌱 AI Plant Identification**: Instantly identify medicinal plants using your device's camera.
*   **🏪 Marketplace**: A dedicated platform for users to buy and sell medicinal plants and herbal products.
    *   Secure product listing and management.
    *   Shopping cart and order tracking.
    *   Seller mode for users to manage their store.
*   **🌍 Social Feed**: Connect with a community of plant enthusiasts.
    *   Share photos and videos of your plants.
    *   Like, comment, and save posts.
*   **💬 Real-time Chat**: distinct messaging system to connect buyers with sellers and users with experts.
*   **🔔 Notifications**: Stay updated with real-time notifications for interactions, orders, and community activity.
*   **🗺️ Maps Integration**: Locate medicinal plants or sellers near you.

## 🛠️ Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/) (Dart)
*   **Backend**: [Firebase](https://firebase.google.com/)
    *   Authentication (Google Sign-In, Email/Password)
    *   Cloud Firestore (Database)
*   **State Management**: [Riverpod](https://riverpod.dev/)
*   **Media Storage**: Cloudinary & Firebase Storage
*   **Notifications**: OneSignal
*   **Maps**: flutter_map

## 📦 Dependencies

Major packages used in this project:

*   `firebase_core`, `firebase_auth`, `cloud_firestore`
*   `flutter_riverpod`
*   `flutter_map`
*   `image_picker`, `camera`
*   `google_sign_in`
*   `onesignal_flutter`
*   `cloudinary_service` (Custom implementation)

## 📱 Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/medicinal-plant-app.git
    cd medicinal_plant
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration:**
    *   Create a project in the [Firebase Console](https://console.firebase.google.com/).
    *   Add your Android/iOS apps to the Firebase project.
    *   Download `google-services.json` (for Android) and put it in `android/app/`.
    *   Download `GoogleService-Info.plist` (for iOS) and put it in `ios/Runner/`.

4.  **Environment Variables:**
    *   Create a `.env` file (if applicable) or configure your API keys for Cloudinary and OneSignal in `lib/utils/constants.dart` or relevant config files.

5.  **Run the App:**
    ```bash
    flutter run
    ```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Built with 💚 using Flutter
