# Desain-Chip-UART-Relay-Bidirectional-dengan-Dual-Hardware-Watchdog-untuk-Sistem-Komunikasi-UAV


Desain tata letak sirkuit terpadu (ASIC) yang mengintegrasikan **relay UART dua arah** dan **dual hardware watchdog** untuk menjamin keandalan jalur komunikasi serial antara komputer misi (Jetson), RasPi, dan Flight Controller (FC) pada wahana udara nirawak (UAV). Desain diimplementasikan dari RTL hingga GDSII menggunakan alur OpenLane dengan PDK SkyWater Sky130.

Repositori ini merupakan bagian dari tugas akhir (skripsi) dan basis pengajuan **Desain Tata Letak Sirkuit Terpadu (DTLST)** ke DJKI.

---

## Ikhtisar

Sistem terdiri atas dua subsistem utama yang berbagi satu clock 125 MHz:

1. **UART Relay Bidirectional** — meneruskan data serial dua arah antara RasPi dan Jetson pada baud rate 115200 bps (RasPi → Jetson dan Jetson → RasPi).
2. **Dual Hardware Watchdog** — memantau sinyal *heartbeat* dari FC dan Jetson, lalu menghasilkan sinyal reset proteksi (`reset_n_fc`) ketika terdeteksi kegagalan berupa kondisi *stuck-high*, *stuck-low*, atau *bad-rising-edge*.

Fungsionalitas relay telah diverifikasi sebelumnya pada perangkat keras FPGA (PYNQ-Z2 / Zynq-7020) dengan hasil 0% packet loss, dan desain RTL yang sama dibawa ke alur ASIC pada repositori ini.

---

## Spesifikasi Desain

| Parameter | Nilai |
|---|---|
| Teknologi | SkyWater Sky130 (CMOS 130 nm) |
| Pustaka sel standar | sky130_fd_sc_hd (high density) |
| Ukuran die | 167,9 µm × 165,92 µm |
| Luas core | 27.857,97 µm² |
| Frekuensi target | 125 MHz (periode 8 ns) |
| Jalur kritis | 4,68 ns (frekuensi maksimum teoretis ±213 MHz) |
| Konsumsi daya (typical) | 5,34 mW |
| Lapisan metal aktif | met1–met4 |
| Jumlah sel standar | 1.285 |
| Jumlah flip-flop | 269 |
| Panjang kabel total | 24.648 µm |
| Jumlah via | 9.515 |

### Hasil Verifikasi Signoff

| Pemeriksaan | Hasil |
|---|---|
| DRC (Design Rule Check) | Bersih — 0 pelanggaran |
| LVS (Layout vs Schematic) | 0 error |
| Setup / Hold timing | Tidak ada pelanggaran |
| XOR (Magic vs KLayout GDS) | Identik — tidak ada perbedaan |
| Antenna & ERC | Terlaksana |
| Status alur | Flow completed |

---

## Antarmuka (Pinout)

| Pin | Arah | Deskripsi |
|---|---|---|
| `clk` | input | Clock 125 MHz |
| `rxd_raspi` | input | Data dari RasPi TX |
| `txd_jetson` | output | Data ke Jetson RX |
| `rxd_jetson` | input | Data dari Jetson TX |
| `txd_raspi` | output | Data ke RasPi RX |
| `heartbeat_fc` | input | Heartbeat dari FC |
| `heartbeat_jetson` | input | Heartbeat dari Jetson |
| `reset_n_fc` | output | Sinyal reset proteksi ke FC |
| `initialize` | input | Tombol clear error |

---

## Struktur Repositori

```
dtlst_layout/
├── src/                    # Sumber RTL (Verilog)
│   ├── sistem_lengkap.v    # Top module
│   ├── dual_watchdog.v     # Subsistem watchdog
│   ├── uart_rx.v
│   ├── uart_tx.v
│   ├── uart_rx_jetson.v
│   └── uart_tx_raspi.v
├── config.tcl              # Konfigurasi OpenLane
├── results/                # Hasil alur (GDSII, DEF, LEF, netlist, dll.)
│   └── final/gds/sistem_lengkap.gds
└── reports/                # Laporan signoff (DRC, LVS, STA, daya, metrik)
```

---

## Reproduksi Alur RTL-to-GDSII

Desain dibangun menggunakan [OpenLane](https://github.com/The-OpenROAD-Project/OpenLane) dengan PDK Sky130.

```bash
# 1. Salin folder desain ke direktori designs OpenLane
cp -r dtlst_layout designs/dtlst_design

# 2. Jalankan alur
cd OpenLane
make mount
./flow.tcl -design dtlst_design
```

Konfigurasi utama (`config.tcl`):

```tcl
set ::env(DESIGN_NAME) {sistem_lengkap}
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "8.0"
set ::env(DESIGN_IS_CORE) {1}
```

GDSII final dapat dibuka dengan [KLayout](https://www.klayout.de/) menggunakan technology file Sky130 (`sky130A.lyt`).

---

## Lisensi

Hak cipta atas desain tata letak ini dimiliki oleh penulis. Penggunaan kembali memerlukan izin.

*(Sesuaikan bagian lisensi dengan ketentuan kepemilikan IP institusi Anda.)*
