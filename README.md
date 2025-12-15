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
    git clone https://github.com/Itz-mehanth/MedPlant.git
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

<h2 align="center">App Screenshots</h2>

<table align="center">
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/cd4631d5-cca6-4afb-98d3-712d25e68cff" width="100%" alt="Screen 1"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/3780395d-b020-4140-9890-6efbb631a5f9" width="100%" alt="Screen 2"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/92954cdc-ef81-4d50-a636-0e433d0d95bc" width="100%" alt="Screen 3"></td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/ae572ea2-503e-4d74-bd2a-f09833114c9e" width="100%" alt="Screen 4"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/1627e2e3-6ba7-48b4-a12c-0db54f7606a7" width="100%" alt="Screen 5"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/41dfdeae-8b80-4ced-8bb8-f9e1ec18a760" width="100%" alt="Screen 6"></td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/01db1523-4c1d-46e2-94f7-6dc326e62103" width="100%" alt="Screen 7"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/daf3a6bd-aaa5-4501-952b-471dbbd918d5" width="100%" alt="Screen 8"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/3bce78e9-2498-4462-8372-7f92dea68680" width="100%" alt="Screen 9"></td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/31eae125-a038-4613-9ad4-ee5a9346cd9b" width="100%" alt="Screen 10"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/5a9bfbe5-6854-4e11-9ce1-3841ce30c8f1" width="100%" alt="Screen 11"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/b4a49c55-4917-4c19-8542-60c2a8198eb4" width="100%" alt="Screen 12"></td>
  </tr>
</table>

Built with 💚 using Flutter
