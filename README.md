# CgFetcher
A simple demon for fetching CG from Webkiosk (TIET) when CG is released and their server hangs.
- Its is bash, so By default it will only run on Linux or macOS for windows,this repo has a bat file.

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
nohup ./webkiosk.sh --roll-number <your_roll_number> --password <your_password> &
```
