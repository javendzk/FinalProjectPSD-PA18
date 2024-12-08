# 🌦️ Final Project Digital System Design - IoT Remote Weather Station & Centralized Control Center

Welcome to the **IoT Remote Weather Station & Centralized Control Center** project repository! This project focuses on developing an IoT-based weather monitoring system integrated with a centralized control center. It leverages VHDL and FSM concepts to process and report real-time environmental data such as temperature, humidity, and light intensity.

## 🌍 Project Background
Indonesia, as a disaster-prone country located on the Pacific Ring of Fire, recorded 1,300 disasters as of September 2024. To address this challenge, a more advanced and responsive system is needed, such as the development of IoT-based Weather Stations integrated with a control center. This technology enables real-time weather monitoring with high accuracy using sensors for temperature, humidity, and light intensity. The data transmitted directly to the control center can be used to detect weather patterns, predict disasters, and provide early warnings to reduce the impact of disasters.

Through historical data collection and continuous monitoring, this system can improve disaster prediction accuracy and support more effective mitigation efforts. The implementation of IoT technology and a centralized control system is expected to build a strong disaster management ecosystem, reducing risks, economic losses, and saving more lives in the future.

## 🚀 Project Overview

The **IoT Remote Weather Station** reads data from sensors and sends it to the centralized control center for analysis. The system includes:
1. **Weather Station**: Reads sensor data and processes it using FSM.
2. **Station Controllers**: Manage sensor data and forward reports.
3. **Central Control Center**: Decodes incoming reports, processes data, and logs observations in CSV format.

## 🧩 Key Modules and Features
### 🔹 Weather Station
- Reads data from temperature, humidity, and light sensors.
- Implements **FSM** to manage different operational states:
  - **Idle**: Waiting for instructions.
  - **Read Instructions**: Fetch operation codes.
  - **Encode**: Encode sensor data.
  - **Generate Report**: Create a 64-bit packet report.

### 🔹 Station Controllers
- Reads sensor data (CSV format) and sends it to the weather station.
- Calculates **moisture** data based on mass and volume.
- Ensures synchronization of data flow.

### 🔹 Centralized Control Center
- Decodes and validates 64-bit packet reports.
- Logs reports in a CSV file.
- Provides **operation instructions** to station controllers.

## ⚙️ System Implementation

### 🔹 Instruction Set (Opcodes)
| **Opcode** | **Description**                  |
|------------|----------------------------------|
| 000001     | Idle                             |
| 000010     | Run All Sensors                  |
| 000011     | Run Without Temperature          |
| 000100     | Run Without Light                |
| 000101     | Run Without Moisture             |
| 000110     | Run Temperature Only             |
| 000111     | Run Light Only                   |
| 001000     | Run Moisture Only                |

### 🔹 Packet Report Structure (64-bits)
| Bits       | Description                |
|------------|----------------------------|
| 63-62      | Source Station ID          |
| 61-60      | System Status              |
| 59-54      | Operation Code             |
| 53-48      | Timestamp                  |
| 47-32      | Temperature Data (16-bits)  |
| 31-16      | Light Intensity Data (16-bits)|
| 15-0       | Moisture Data (16-bits)     |

## 📝 Project Schematic
![picture 2](https://i.imgur.com/hTyMF5m.png)   
![picture 1](https://i.imgur.com/7L0qq1I.png)  


## 👨‍💻 Group Members
#### 🔹 **Javana Muhammad Dzaki** - 2306161826
#### 🔹 **Benedict Aurelius** - 2306209095
#### 🔹 **Syahmi Hamdani** - 2306220532
#### 🔹 **Muhamad Rey Kafaka Fadlan** - 2306250573

##
### 📚 References
#### 🔹 [VHDL CSV File Reader](https://github.com/ricardo-jasinski/vhdl-csv-file-reader)
#### 🔹 [Bencana Alam di Indonesia](https://databoks.katadata.co.id/demografi/statistik/66d7d7a492e96/ada-1300-bencana-alam-di-ri-sampai-september-2024-ini-rinciannya)
#### 🔹 [Digital System Design (Digilab)](https://learn.digilabdte.com/books/digital-system-design)
#### 🔹 [VHDL Structural Modeling Style](https://surf-vhdl.com/vhdl-syntax-web-course-surf-vhdl/vhdl-structural-modeling-style/)
#### 🔹 [Design of Encoding and Decoding](https://ieeexplore.ieee.org/document/9443744)
#### 🔹 [Implementing a FSM in VHDL](https://www.allaboutcircuits.com/technical-articles/implementing-a-finite-state-machine-in-vhdl/ )
