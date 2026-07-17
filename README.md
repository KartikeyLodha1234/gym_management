# 🏋️ Kartikey Gym Management System

A professional, full-featured Gym Management Application developed using **Flutter** and **SQLite**. This app provides a comprehensive solution for managing gym operations, including member registration, staff management, attendance verification (with photo/location), payment tracking, and equipment maintenance.

**Designed & Developed by Kartikey**  
*© 2026 Kartikey Gym | All Rights Reserved*

---

## 🚀 Key Features

### 🧑‍💼 Admin & Staff Management
*   **Role-Based Access**: Specialized dashboards for Admin, Manager, Trainer, and Receptionist.
*   **Member Management**: Add, edit, and track members with profile photos and membership plans.
*   **Staff Control**: Manage staff roles, contact details, and secure login credentials.

### 📅 Advanced Attendance System
*   **Dual-Verification**: Check-in/out requires a live camera photo and GPS location to prevent fraud.
*   **Member & Staff Tracking**: Separate logs for members and gym staff.
*   **Attendance History**: View monthly summaries and detailed daily logs.

### 💰 Finance & Payments
*   **Payment Tracking**: Record subtotal, tax (GST), and discounts.
*   **Defaulter Reports**: Filter and identify members with pending payments.
*   **Export Options**: Generate professional PDF and Excel reports for all transactions.

### 🔧 Maintenance & Inventory
*   **Equipment Log**: Track service history for Treadmills, Bikes, and other machines.
*   **Maintenance Requests**: Staff can report faulty equipment with real-time status updates (Pending/Completed).
*   **Repair History**: Log technician names and repair costs.

---

## 🛠️ Installation Guide (How to Run)

Follow these steps to set up the project on your local machine:

### 1. Prerequisites
*   Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.1.0 or higher).
*   Install [Android Studio](https://developer.android.com/studio) or VS Code.
*   Set up an Android Emulator or connect a physical device.

### 2. Project Setup
1.  **Download and Extract** the ZIP file to your desired folder.
2.  Open the folder in **Android Studio** or VS Code.
3.  Open the **Terminal** in your IDE and run:
    ```bash
    flutter pub get
    ```
    *This will download all necessary packages (intl, sqflite, geolocator, etc.).*

### 3. Permissions Setup
Ensure the following permissions are handled on your device:
*   **Camera**: Required for attendance verification photos.
*   **Location**: Required for gym vicinity verification.
*   **Storage**: Required for saving exported PDF/Excel files.

### 4. Running the App
Run the following command in the terminal or click the **Run** button in your IDE:
```bash
flutter run
```

---

## 🔐 Default Admin Credentials
*   **Username**: `adminkartikey`
*   **Password**: `Kartikey@1805`

---

## 📜 License & Copyright
Copyright © 2026 **Kartikey**. All rights reserved.  
This application is a proprietary product. Unauthorized copying, modification, or distribution of this software is strictly prohibited.
