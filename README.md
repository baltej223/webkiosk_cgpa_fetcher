# CgFetcher
A simple termnial app for fetching CG from Webkiosk (TIET) when CG is released and their server hangs.
- Bash version for Linux and macOS and .bat file for windows, is in this repo only.

## Usage: 
./webkiosk_cgpa_fetcher.sh --roll-number <num> --password <pass> [-s <seconds>]

Options:
  -r, --roll-number   Your Enrollment Number (e.g., 1024123456)
  -p, --password      Your WebKiosk password
  -s, --sleep         Sleep interval in seconds (default: 150)

## Example: 
```
./webkiosk_cgpa_fetcher.sh --roll-number 1024123456 --password pass -s 100
```
- It will fetch you cgpa, and will save it in a HTML file.

For running it as a demon: 
```bash
# For Linux
nohup ./webkiosk.sh --roll-number <your_roll_number> --password <your_password> &

# For windows
start /min cmd /c "C:\Path\To\Your\cgpa_checker.bat --roll-number YOUR_ROLL_NUMBER --password YOUR_PASSWORD"
```
