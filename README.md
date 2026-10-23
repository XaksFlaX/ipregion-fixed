# ipregion-fixed

**English** | [Русский](README.ru.md)

A bash script for determining your IP geolocation using various GeoIP services and popular websites.  
This is a fork of [Davoyan/ipregion](https://github.com/Davoyan/ipregion) (itself a fork of the [original script](https://github.com/vernette/ipregion/))
that fixes proxy leaks and unattended package installs, adds availability checks for ChatGPT, Claude, Netflix and Disney+,
and runs the checks in parallel. Details below.

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

Output example (screenshot of Davoyan's version; this fork prints the same table with a few more rows):

![image](https://i.imgur.com/Bn1o644.png)

## What is new in this fork

### Availability checks

| Row | Values | How it is decided |
|---|---|---|
| ChatGPT Access | `Yes` / `No` | `api.openai.com` answers `403 unsupported_country_region_territory` where ChatGPT is not offered |
| Claude Access | `Yes` / `No` | without a key the Anthropic API answers `401` in supported regions and `403 Request not allowed` elsewhere |
| Netflix Catalog | `Full` / `Originals only` | two licensed titles are opened; if both are missing while a control title opens, Netflix shows only its own titles (region or proxy detection) |
| Disney+ | country / `No` | Disney+ device registration reports whether the location is supported and which country it sees; `No` also when Disney refuses this IP with "Forbidden location" (seen for hosting IPs even in countries where Disney+ works) |

Gemini is not checked: Google returns the same page in supported and unsupported countries, so there is no reliable signal.

### A reason instead of `N/A`

When a check gets no answer, the row shows why:

- `Blocked` — the service answered HTTP 403 (for Reddit: its "blocked by network security" page, typical for datacenter IPs);
- `RateLimited` — HTTP 429, too many requests from this IP;
- `Timeout` — no answer in time;
- `N/A` — anything else (network error, changed API).

### Faster

Checks run 6 at a time (`-P N` to change, `-P 1` for one by one). On our servers a full run went from 20–46 s down to 10–17 s
with exactly the same results.

The version is printed in the header and in JSON (`script_version`).

### CDN rows are back in the table

`YouTube CDN` and `Netflix CDN` were checked on every run but hidden. Now they are printed after the GeoIP services.
They show the country of the video node that serves this IP (useful to see how far the server is from it),
so they are not counted in the legend.

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
- **Reddit shows `Blocked`** instead of an empty value when Reddit answers with its block page. From residential IPs it shows the country.
- **ipapi.co is excluded:** it answers `429 RateLimited` to datacenter IPs.
- The legend counts only country codes, so `Yes`, `No`, `Blocked` and similar values never appear as "countries".
- The temporary files are removed in every mode; dead code is gone.
- [ShellCheck](https://www.shellcheck.net/) runs on every push (GitHub Actions).

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

# Check services one by one instead of 6 at a time
./ipregion.sh --parallel 1

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
  -P, --parallel N     Check N services at a time (default: 6, 1 = one by one)
      --no-update-check  Do not check GitHub for a newer version of this script

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
  ipregion.sh -P 1                  # Check services one by one
```

## Versions and caching

The first line of the output shows the version, e.g. `ipregion-fixed 2026.10.23.1`. Every change of `ipregion.sh` bumps
`SCRIPT_VERSION` (`YYYY.MM.DD.N`), and GitHub Actions fails the build if it was not bumped.

GitHub caches files under `raw.githubusercontent.com/.../main/...` for up to 5 minutes, so right after an update
the `main` link may still serve the previous version. A link to a specific commit is never stale.

While the services are checked, the script reads the latest version from GitHub (the first 2 KB of `ipregion.sh` on `main`).
If it is newer, the output ends with "A newer version is available" and the command to run it; JSON gets `latest_version`.
If GitHub is unreachable nothing is printed. `--no-update-check` turns this off.

## License

MIT, see [LICENSE](LICENSE). Copyright of the original script: Nikita Skryabin (vernette).
