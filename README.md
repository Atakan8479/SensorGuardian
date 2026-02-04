# 🛡️ SensorGuardian  
**On-Device AI Intrusion Detection for Wireless Sensor Networks (iOS + CoreML + XAI)**

SensorGuardian is an **iOS-based real-time intrusion detection dashboard** powered by an on-device **machine learning model** and an **explainable AI (XAI) engine**. It analyzes streaming wireless sensor telemetry and detects malicious behavior without requiring a server connection.

This project demonstrates how **TinyML + Mobile ML + Explainability** can be combined for **cybersecurity in IoT / sensor networks**.

---

## ✨ Features

🔍 **Real-Time Intrusion Detection**
- Streams live sensor readings from a dataset  
- Predicts malicious activity per sensor in real time  
- Fully on-device inference using **CoreML**

🧠 **Machine Learning Model**
- Model: `SensorGuardian_fp16.mlmodel`  
- Detects abnormal network behavior patterns  
- Optimized for mobile inference (Float16)

📊 **Explainable AI (XAI)**
- Human-readable explanations for each prediction  
- Rule-based reasoning loaded from `explain_rules.json`  
- Helps users understand *why* a sensor is flagged  

📡 **Sensor Simulation Engine**
- Streams realistic telemetry from:
  - `SensorNetGuard_full.csv`  
- Simulates a live wireless sensor network  

📱 **iOS Dashboard UI**
- Live sensor list  
- Malicious probability indicator  
- Per-sensor state (NORMAL / MALICIOUS)  
- Scalable for thousands of sensors  

---

## 🏗️ Architecture

```
CSV Dataset  →  SensorReadingMapper  →  ModelAdapter (CoreML)
                                      →  XAI Engine (Rules)
                                      →  DashboardViewModel
                                      →  SwiftUI Dashboard
```

### Core Components

| Component | Role |
|----------|------|
| **SensorGuardianModelAdapter** | Preprocesses data and performs ML prediction |
| **ExplainabilityEngine** | Converts model outputs into human-readable explanations |
| **CSVLoader** | Loads and parses sensor dataset |
| **DashboardViewModel** | Controls simulation, streaming, and UI state |
| **SwiftUI Views** | Displays sensors and alerts |

---

## 🧠 Machine Learning Details

| Property | Value |
|---------|------|
| Framework | CoreML |
| Precision | Float16 |
| Input Features | 13 network + device metrics |
| Output | `maliciousProbabilityRaw` |
| Inference Mode | On-device |

### Input Features

The model expects the following features:

```
Bandwidth
Battery_Level
CPU_Usage
Data_Reception_Frequency
Data_Transmission_Frequency
Memory_Usage
Number_of_Neighbors
Packet_Duplication_Rate
Packet_Rate
Route_Reply_Frequency
Route_Request_Frequency
SNR
Signal_Strength
```

All features are automatically:
- Median-imputed  
- Clipped to safe bounds  
- Standardized using `preprocess_params.json`

---

## 🔎 Explainable AI (XAI)

SensorGuardian does not only detect attacks — it explains them.

The `ExplainabilityEngine` uses rule definitions from:

```
explain_rules.json
```

Each malicious prediction can generate explanations like:

> “High packet duplication rate combined with abnormal route requests suggests possible replay attack.”

---

## 📂 Project Structure

```
SensorGuardian/
│
├── Core/
│   ├── ML/
│   │   └── SensorGuardianModelAdapter.swift
│   ├── XAI/
│   │   └── ExplainabilityEngine.swift
│   └── Data/
│       └── CSVLoader.swift
│
├── Features/
│   └── Dashboard/
│       ├── DashboardViewModel.swift
│       └── Views/
│
├── Resources/
│   ├── SensorGuardian_fp16.mlmodel
│   ├── preprocess_params.json
│   ├── explain_rules.json
│   └── SensorNetGuard_full.csv
```

---

## ⚙️ Setup Instructions

### 1️⃣ Requirements
- macOS  
- Xcode 15+  
- iOS 17+ Simulator or Device  

### 2️⃣ Clone the Repository
```bash
git clone https://github.com/yourusername/SensorGuardian.git
cd SensorGuardian
```

### 3️⃣ Open Project
Open `SensorGuardian.xcodeproj` in Xcode

### 4️⃣ Verify Resources
Make sure these files are included in **Build Phases → Copy Bundle Resources**:

- `SensorGuardian_fp16.mlmodel`  
- `preprocess_params.json`  
- `explain_rules.json`  
- `SensorNetGuard_full.csv`  

### 5️⃣ Run
Select a simulator and press **Run ▶**

You should see:
- Sensors streaming  
- Real-time probability updates  
- Normal vs malicious state indicators  

---

## 📈 Use Cases

- IoT Network Security Monitoring  
- Mobile Edge AI Demonstrations  
- TinyML Research Projects  
- Explainable AI Applications  
- Academic ML + Cybersecurity Projects  

---

## 🧪 Future Improvements

- 🔄 Live BLE/WiFi sensor ingestion  
- ☁️ Federated Learning integration  
- 📊 Historical anomaly visualization  
- 🤖 On-device model updates  
- 🔐 Secure enclave inference  

---
