# CgFetcher

A lightweight terminal-based utility to automatically fetch your CGPA from Webkiosk (TIET) — especially useful when the server is overloaded during CGPA releases.

Supports:

* **Linux/macOS** via a Bash script
* **Windows** via a `.bat` file

---

## Features

* Periodically checks Webkiosk for your CGPA.
* Automatically saves the result to an HTML file for quick access.
* Customizable fetch interval.
* Works in the background (daemon mode).

---

## Usage

```bash
./webkiosk_cgpa_fetcher.sh --roll-number <ROLL> --password <PASSWORD> [-s <SECONDS>]
```

### Options

| Flag                  | Description                                       |
| --------------------- | ------------------------------------------------- |
| `-r`, `--roll-number` | Your Enrollment Number (e.g., `1024123456`)       |
| `-p`, `--password`    | Your Webkiosk password                            |
| `-s`, `--sleep`       | Interval in seconds between checks (default: 150) |

---

## Installation

### Linux/macOS
```bash
git clone git@github.com:baltej223/cg_from_webkiosk.git
cd cg_from_webkiosk
chmod +x ./webkiosk_cgpa_fetcher.sh
./webkiosk_cgpa_fetcher.sh --roll-number <ROLL> --password <PASSWORD> [-s <SECONDS>]
```

### Windows
```bat
git clone https://github.com/baltej223/cg_from_webkiosk.git
cd cg_from_webkiosk
webkiosk_cgpa_fetch.bat --roll-number <ROLL> --password <PASSWORD> [-s <SECONDS>]
```
---

## Example
```bash
./webkiosk_cgpa_fetcher.sh --roll-number 1024123456 --password mypass123 -s 100
```
This will check for your CGPA every 100 seconds and update the output HTML accordingly.
---

## Run in Background (Daemon Mode)

### Linux/macOS

```bash
nohup ./webkiosk_cgpa_fetcher.sh --roll-number <ROLL> --password <PASSWORD> &
```

### Windows

```bat
start /min cmd /c "C:\Path\To\cg_from_webkiosk\webkiosk_cgpa_fetch.bat --roll-number <ROLL> --password <PASSWORD>"
```

---
> Note: Ensure you have the necessary permissions and dependencies (like `curl`) installed.
---
