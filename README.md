# FinalProjectPSD-PA18 - IOT Weather Station & Center

## Background

Dalam pengembangan sistem modern berbasis perangkat keras, kebutuhan akan monitoring dan pengendalian lingkungan telah menjadi salah satu aspek penting. Salah satu implementasi dalam bidang ini adalah Weather Station, sebuah sistem stasiun cuaca yang dirancang menggunakan VHDL. Sistem ini berfungsi untuk mengumpulkan data lingkungan dari berbagai sensor dan mengirimkannya dalam format ke Control Center.

Weather Station ini mengendalikan Finite State Machine atau FSM dengan beberapa state, yaitu: Idle, Encode, Report, dan Read_Inst. Setiap state dirancang untuk menjalankan fungsi seperti menerima instruksi, membaca data pada sensor mengolah data menjadi paket yang terkode, dan mengirimkan laporan ke Control Center.

Sistem ini dapat mengaktifkan tiga jenis sensor, yaitu sensor suhu, sensor intensitas cahaya, dan kelembapan. Masing-masing sensor mengirimkan data 16-bit ke Weather Station untuk diproses. Data ini kemudia dikemas dalam format 64-bit yang berisi berbagai komponen seperti status, opcode, dan informasi waktu.

Keunggulan dari Weather Station adalah kemampuannya untuk menjalankan instruksi secara real-time, beradaptasi dengan perubahan instruksi yang masuk, dan menghasilkan laporan berkala berdasarkan data lingkungan yang terpantau.

## How it works

Pertama-tama weathe station akan melakuakn instantiate 3 buah komponen, yaitu: `sensor_temprature`, `sensor_daylight`, dan `sensor_moisture`. Untuk port dari semua sensor sama, yaitu 1 out untuk mengirim 16-bit data ke `Weather_Station` dan akan melakukan port mapping dengan ketiga komponen tersebut.

Saat Idle, Weather_Station akan mengirim packet 1 kali setelah di idle kan ke report, dengan membuat semua packet yang 64-bit itu menjadi 0 semua kecuali source `Weather_Station`, `stasus`, `opcode`, dan clock cycle saat ia di idle kan. Pada bagian ini, menunggu instruksi run dari Control Center.

Selama idle, ia akan menunggu adanya input instruksi di port instruction IN. Jika ada, makan ia akan masuk ke state Read_Inst dan membaca instruction nya berdasarkanopcode pada packets encoding. Bisa menggunakan function atau sebagainya jika instruction nya adalah 000010 ~ 001000, maka akan masuk ke state decode.

Untuk state decode, ia akan membuat laporan 64-bit yang terdiri dari komponen-komponen di  penjelasan packet encoding, dan juga mengikuti instruction untuk mengecek bacaan sensor yang tidak dianggap. setelah pembuatan packet 64-bit ini sudah selesai, maka masuk ke state report.

di state report, mengirim 64-bit data tersebut ke port packet_report. Setelah berhasil, maka akan mulai membaca sensor -> decode -> report -> read -> decode -> report sampai ada intruksi bari di port instruction.

Jika ada instruksi baru atau perubahan pada port instruction, maka akan abort apapun yang sedang dilakukan dan masuk ke Read_Inst, membaca intruksi, mengartikan instruksi, dan seterusnya.

## How it use

#### Sensor data packet: 16-bit length

AA B C DDDDDDDDDDD
- A:  2-bit

|    | 0  | 1  |
|----|----|----|
| 0 | No Type | Temperature |
| 1 | Light | Moisture |

- B: 2-bit

|    | 0  | 1  |
|----|----|----|
| 0 | No Status | Running |
| 1 | Stopped |  |

- C:

1 bit sebagai penanda sign apakah D bernilai positif atau negatif


- D: 11-bit data yang dibaca sensor. Rangenya 2408 ~ 2408 (Karena ada sign)

#### instruction 8-bit length
AA BBBBBB

- A: selector weather station.
    - 00 = No station,
    - 01 = Station 1
    - 10 = Station 2
    - 11 = Station 3

- B: 5-bit berisi instruksi untuk weather station,
    - 000000 = No instruction
        Tidak ada apa-apa
    - 000001 = Go Idle
        Memberikan report idle ke `packet_report`, menyebabkan semua bit packet yang 64-bit menjadi 0, **Kecuali** source weather station, status, opcode, dan clock cycle saat di idle kan. Menunggu instruksi run dari control center.
    - 000010 = Run
        Melakukan report seperti biasa.
    - 000011 = Run but stop Temperature
        Mengabaikan data dari sensor temperature. Akan tetapi komponen sensornya dibiarkan berjalan saja sehingga di packet report bagian data temperature 16-bit, AA nya berstatus Stopped, dan C dan D nya full 0.
    - 000100 = Run but stop Daylight
        Sensor daylight dihentikan sementara, tetapi tetap tetap berjalan pada background.
    - 000101 = Run but stop Moisture
        Sensor moisture dihentikan sementara, namun tetap aktif di background.
    - 000110 = Run Temperature Only
        Hanya sensor temperature yang berjalan. Sedangkan lainnya dihentikan sepenuhnya.
    - 000111 = Run Daylight Only
        Hanya sensor daylight yang berjalan. Sedangkan yang lainnya dihentikan sepenuhnya.
    - 001000 = Run Moisture Only
        Hanya sensor moisture yang berjalan. Sedangkan yang lainnya dihentikan sepenuhnya.

## Testing

### Wave:



### FSM:



### ...

## Authors
