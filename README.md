# ipregion-fixed

A bash script for determining your IP geolocation using various GeoIP services and popular websites.  
This is a fork of [Davoyan/ipregion](https://github.com/Davoyan/ipregion) (itself a fork of the [original script](https://github.com/vernette/ipregion/))
that fixes proxy leaks, unattended package installs and several broken lookups. Details below.

## What is fixed

Compared to [Davoyan/ipregion@a85abbf](https://github.com/Davoyan/ipregion/blob/a85abbf739e07b1162bee066d756be1e4b9bfcc0/ipregion.sh):

- **SOCKS5 proxy no longer leaks.** Every request goes through one helper, so `-p` and `-i` apply everywhere
  (before, the DoH check, Spotify Signup, Bing, Steam, PlayStation, Amazon Prime, Google Play and restcountries.com bypassed them).
  The proxy is used as `socks5h://`, so DNS is resolved by the proxy as well; DoH is skipped when a proxy is set.
- **No unattended package installs.** Without a terminal (`ssh host 'bash -s'`, cron) the old script skipped the
  "install?" prompt and ran `apt install -y` as root. Now it stops and prints the command to run by hand.
  In a terminal it shows the exact install command first and asks (the default answer is no).
- **Safer installs:** no `NEEDRESTART_MODE=a` (services are not restarted silently), `column` comes from
  `bsdextrautils`/`bsdmainutils` instead of reinstalling `util-linux`, and `pacman -S --needed` instead of a partial `-Syy` upgrade.
- **External IP is confirmed by two different services** (`ifconfig.me` was listed twice; the second one is now `icanhazip.com`).
- **Fixed lookups:** Amazon Prime blocking detection, 2ip.io request, ipapi.is (the API now returns only the country name),
  Bing market codes such as `XL` and `WW` (falls back to login.live.com), YouTube CDN node names like `tzfraa-cd`.
- **ipapi.co is excluded:** it answers `429 RateLimited` to datacenter IPs.
- The temporary file is removed in `-j`/`-v` mode too.

Not fixed: the Reddit check is empty from datacenter IPs (Reddit answers with a block page).

## Usage
Run directly from GitHub:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/XaksFlaX/ipregion-fixed/main/ipregion.sh)
```
Safer: download a specific commit, check it, then run it as a regular user:
```bash
curl -fsSL https://raw.githubusercontent.com/XaksFlaX/ipregion-fixed/<commit>/ipregion.sh -o ipregion.sh
less ipregion.sh
bash ipregion.sh
```

Output example:

![image](https://i.imgur.com/Bn1o644.png)

## What Davoyan's fork added

Compared to the original script, [Davoyan/ipregion](https://github.com/Davoyan/ipregion) includes several improvements and fixes:

- **Improved IPv6 detection** — previously unreliable in some cases.  
- **Fixed freezes** on certain services.  
- **Adjusted output table alignment** for better readability.  
- **Separated YouTube and Google checks** — sometimes show different regions.  
- **Correct detection of Google China (CN) region**.  
- **Added support for additional services**: 2ip.io, Youtube Music, Bing, and Amazon Prime.  
- **ASN detection using MaxMind database** — same as [IPQuality](https://github.com/xykt/IPQuality/).  
- **CDN services removed from the default group** — can be checked separately if needed.  
- **Enhanced human-readable output** with country name decoding and percentage calculations.  
- **Country names + percentage stats**: alongside ISO codes, shows country names and percentage distribution across services
- **Fixed minor bugs**, e.g., inability to interrupt the script during execution.

## Main features

- Checks your IP geolocation using multiple public GeoIP APIs
- Results from both "primary" GeoIP services and popular web services (YouTube, Netflix, Twitch, etc.)
- Supports both IPv4 and IPv6 (can test separately)
- SOCKS5 proxy and custom network interface support
- JSON output for automation and integration
- Color-coded, easy-to-read table output

## Dependencies

- bash
- curl
- jq
- util-linux or bsdmainutils (for `column`)

## Country codes

The script outputs country codes in ISO 3166-1 alpha-2 format (e.g., RU, US, DE).  
In the **human-readable output**, the script also shows the **full country name** and **percentage distribution**.  

For manual lookup of codes, you can use the official ISO website: [https://www.iso.org/obp/ui/#search/code/](https://www.iso.org/obp/ui/#search/code/)

### Common use cases

```bash
# Show help message
./ipregion.sh --help

# Check all services with default settings
./ipregion.sh

# Check only GeoIP services
./ipregion.sh --group primary

# Check only CDN services
./ipregion.sh --group cdn

# Check only popular web services
./ipregion.sh --group custom

# Test only IPv4
./ipregion.sh --ipv4

# Test only IPv6
./ipregion.sh --ipv6

# Use SOCKS5 proxy
./ipregion.sh --proxy 127.0.0.1:1080

# Use a specific network interface
./ipregion.sh --interface eth1

# Set custom curl request timeout in seconds
./ipregion.sh --timeout 20

# Output result as JSON
./ipregion.sh --json

# Enable verbose logging
./ipregion.sh --verbose
```

All options available in the help message (`-h, --help`) can be used and combined.

## Options

```
Usage: ipregion.sh [OPTIONS]

IPRegion — determines your IP geolocation using various GeoIP services and popular websites

Options:
  -h, --help           Show this help message and exit
  -v, --verbose        Enable verbose logging
  -j, --json           Output results in JSON format
  -g, --group GROUP    Run only one group: 'primary', 'custom', 'cdn' or 'all' (default: all)
  -t, --timeout SEC    Set curl request timeout in seconds (default: 6)
  -4, --ipv4           Test only IPv4
  -6, --ipv6           Test only IPv6
  -p, --proxy ADDR     Use SOCKS5 proxy (format: host:port)
  -i, --interface IF   Use specified network interface (e.g. eth1)

Examples:
  ipregion.sh                       # Check all services with default settings
  ipregion.sh -g primary            # Check only GeoIP services
  ipregion.sh -g custom             # Check only popular websites
  ipregion.sh -g cdn                # Check only CDN
  ipregion.sh -4                    # Test only IPv4
  ipregion.sh -6                    # Test only IPv6
  ipregion.sh -p 127.0.0.1:1080     # Use SOCKS5 proxy
  ipregion.sh -i eth1               # Use network interface eth1
  ipregion.sh -j                    # Output result as JSON
  ipregion.sh -v                    # Enable verbose logging
```
