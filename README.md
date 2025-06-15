# CgFetcher
A simple termnial app for fetching CG from Webkiosk (TIET) when CG is released and their server hangs.
- Bash version for Linux and macOS and .bat file for windows, is in this repo only.
- It will fetch your CGPA after some specified time, and it will create a html file which will have your CGPA which you can check for checking CGPA release. 

## Usage: 
./webkiosk_cgpa_fetcher.sh --roll-number <num> --password <pass> [-s <seconds>]

Options:
  -r, --roll-number   Your Enrollment Number (e.g., 1024123456)
  -p, --password      Your WebKiosk password
  -s, --sleep         Sleep interval in seconds (default: 150)

### For linux or linux
```
git clone git@github.com:baltej223/cg_from_webkiosk.git
cd cg_from_webkiosk
chmod a+x ./webkiosk_cgpa_fetcher.sh
./webkiosk_cgpa_fetcher.sh --roll-number <num> --password <pass> [-s <seconds>]
```
### For Windows
```
git clone https://github.com/baltej223/cg_from_webkiosk.git
cd cg_from_webkiosk
./webkiosk_cgpa_fetch.bat --roll-number <num> --password <pass> [-s <seconds>]
```

## Example: 
```
./webkiosk_cgpa_fetcher.sh --roll-number 1024123456 --password pass -s 100
```
- It will fetch you cgpa after every 100 seconds, and will save it in a HTML file.

For running it as a demon: 
```bash
# For Linux
nohup ./webkiosk.sh --roll-number <your_roll_number> --password <your_password> &

# For windows
start /min cmd /c "C:\Path\To\Your\cgpa_checker.bat --roll-number YOUR_ROLL_NUMBER --password YOUR_PASSWORD"
```
