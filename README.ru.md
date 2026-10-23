# ipregion-fixed

[English](README.md) | **Русский**

Bash-скрипт, который показывает, в какой стране ваш IP-адрес «видят» разные GeoIP-базы и популярные сервисы.
Удобно для проверки VPN и VPS: сразу видно, откроются ли YouTube Premium, ChatGPT, Claude, Gemini, Netflix и другие.

Это форк [Davoyan/ipregion](https://github.com/Davoyan/ipregion), который, в свою очередь, форк [оригинального скрипта](https://github.com/vernette/ipregion/).
Здесь исправлены утечки мимо прокси и установка пакетов без спроса, добавлены проверки доступности ChatGPT, Claude, Gemini,
Copilot, Grok и Netflix, возвращена проверка Disney+ из оригинала. Скрипт показывает, считается ли IP хостингом или VPN и какой
DNS-резолвер используется, а в конце печатает короткий итог. Проверки идут параллельно. Подробности ниже.

## Запуск

Прямо с GitHub:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/XaksFlaX/ipregion-fixed/main/ipregion.sh)
```

Надёжнее: скачать конкретный коммит, посмотреть его и запустить от обычного пользователя:
```bash
curl -fsSL https://raw.githubusercontent.com/XaksFlaX/ipregion-fixed/<коммит>/ipregion.sh -o ipregion.sh
less ipregion.sh
bash ipregion.sh
```

### Пример вывода

VPS в Молдове, версия 2026.10.23.9 (IP-адреса, ASN и имя сервера скрыты):

![Пример вывода ipregion-fixed](docs/example-output.png)

Как читать:

- **Блоки** — Google and YouTube, AI assistants, Video, Music, Social, Other, затем GeoIP-базы, CDN и репутация IP.
- **Колонки** — одна и та же проверка по IPv4 и по IPv6. `N/A` в колонке IPv6 обычно значит, что у сервиса нет IPv6.
- **Коды стран** — где, по мнению сервиса, находится IP. Здесь мнения разошлись: примерно половина видит Молдову (`MD`), половина — Румынию (`RO`).
- **YouTube Premium / Music `No`** — Google видит Молдову, а там они не предоставляются.
- **ChatGPT / Claude / Gemini / Copilot Access `Yes`** — все четыре работают с этого IP.
- **Netflix Catalog `Originals only`** — Netflix показывает здесь только свои сериалы.
- **Disney+ `No`** — Disney отказывает этому IP («Forbidden location»).
- **Reddit `Blocked`** — Reddit блокирует этот IP (обычно так с IP хостеров); Guest Access `No` — не открывается даже сайт.
- **Второй блок** — GeoIP-базы; **YouTube/Netflix CDN** — страна узла, с которого отдаётся видео.
- **[Блок сети](#репутация-ip-и-dns)** — все три источника видят адрес хостера, а proxycheck ещё и считает его VPN;
  DNS-резолвер — Google в Германии (проверяется один раз, поэтому в колонке IPv6 — `same as IPv4`).
- **Legend** — доля сервисов, которые видят каждую страну; считаются только коды стран.
- **[Итог](#итог)** — что работает и что нет, по каждому протоколу. Здесь видны два вида отказов: YouTube Premium и Music —
  из-за страны (Google видит Молдову), Netflix, Disney+ и Reddit — из-за того, что адрес хостерский и помечен как VPN.
  По IPv6 Reddit и Prime Video — `Not checked`: у них нет IPv6.

## Что нового в этом форке

### Проверки доступности

| Строка | Значения | Как определяется |
|---|---|---|
| ChatGPT Access | `Yes` / `No` | `api.openai.com` отвечает `403 unsupported_country_region_territory` там, где ChatGPT не работает |
| Claude Access | `Yes` / `No` | API Anthropic без ключа отвечает `401` в поддерживаемых странах и `403 Request not allowed` в остальных |
| Netflix Catalog | `Full` / `Originals only` | открываются два лицензионных тайтла; если обоих нет, а контрольный открывается, Netflix показывает только свои сериалы (так бывает в некоторых странах и для IP, которые он считает прокси) |
| Disney+ | страна / `No` | регистрация устройства Disney+ сообщает, поддерживается ли регион и какую страну видит сервис; `No` и тогда, когда Disney отказывает этому IP с ошибкой «Forbidden location» (так бывает с IP хостеров даже в странах, где Disney+ работает) |

| Gemini Access | `Yes` / `No` | страна, которую видит Google, ищется в официальном [списке регионов, где доступен Gemini API](https://ai.google.dev/gemini-api/docs/available-regions) (скачивается при каждом запуске) |
| Copilot Access | `Yes` / `No` | `copilot.microsoft.com` стоит за Cloudflare, который отвечает `error code: 1009` («доступ из страны запрещён») там, где Copilot не работает |
| Grok Access | `Yes` / `No` | API xAI без ключа отвечает `401` там, где Grok работает, и `403` «This service is not available in your region.» в остальных странах |

Disney+ и Gemini взяты из [оригинального скрипта](https://github.com/vernette/ipregion/) (в форке Davoyan обе проверки убрали):
Disney+ — с тем же запросом, Gemini — с той же идеей (список регионов Google, сравнение названий по словам), но без скачивания
словаря названий CLDR. Ещё из оригинала: две GeoIP-базы (ip2location.io, ifconfig.co), `Cloudflare CDN`
(дата-центр Cloudflare, который обслуживает этот IP, например `DE (FRA)`) и `Microsoft (account)` (страна, которую
видит login.live.com; строка Bing использует его только как запасной источник). Perplexity не проверяется: его API отвечает одинаково из России и из Нидерландов, а сайт закрыт
защитой от ботов, так что признака региона нет.

### Репутация IP и DNS

Большинство отказов (Reddit, Disney+, Netflix только со своими сериалами) связаны не со страной, а с тем, что IP принадлежит
хостеру или считается VPN. После строк CDN идёт блок, который показывает, как видят IP:

| Строка | Значения | Источник |
|---|---|---|
| Network (ipinfo) | `Hosting` / `ISP` / `Business` / `Education`, а при пометке ещё `VPN`, `Proxy`, `Tor`, `Relay`, например `Hosting, VPN` | ipinfo.io: тот же ответ бесплатного виджета, что и для строки ipinfo.io, запрашивается один раз на протокол и по этому же протоколу (для IPv6 — `v6.ipinfo.io`): без ограничений ipinfo отвечает только про адрес, с которого пришёл запрос, а на поиск чужих адресов есть небольшая суточная квота |
| Hosting (ip-api) | `Yes` / `No` | ip-api.com |
| VPN/Proxy (proxycheck) | `No` / `VPN` / `Proxy` / … | proxycheck.io (бесплатно: 100 запросов в сутки с одного IP) |
| DNS resolver | страна и провайдер, например `DE Google` | edns.ip-api.com: какой резолвер запросил случайное имя. Собственный DoH скрипта здесь не используется, поэтому это системный резолвер (или резолвер прокси при `-p`). Проверяется один раз: в колонке IPv6 — `same as IPv4` (у edns.ip-api.com нет IPv6, поэтому с `-6` будет `N/A`) |

### Итог

После легенды скрипт печатает короткий вывод по каждому протоколу:

```text
Summary (IPv4)
Works           Google Search, YouTube Premium, ChatGPT, Claude, Gemini, Copilot, Grok, Netflix, Disney+, Spotify
Not available   Reddit
IP flagged as   Hosting (ipinfo), Hosting (ip-api), VPN (proxycheck)
```

`Works` — работает, `Not available` — не работает, `Not checked` — сервис не дал ответа (N/A, Timeout, RateLimited),
`IP flagged as` — кем и как помечен IP.

### Причина вместо `N/A`

Если проверка не получила ответа, в строке написано почему:

- `Blocked` — сервис ответил HTTP 403 (у Reddit это его страница «blocked by network security», обычная для IP дата-центров);
- `RateLimited` — HTTP 429, с этого IP слишком много запросов;
- `Timeout` — ответа не дождались;
- `N/A` — всё остальное (сетевая ошибка, сервис поменял API).

### Быстрее

Проверки идут по 6 одновременно (`-P N` — изменить, `-P 1` — по одной, как раньше). На наших серверах полный прогон
занимает 12–19 секунд вместо 22–47 по одному, результаты при этом те же.

Версия скрипта печатается в шапке вывода и в JSON (`script_version`).

### CDN снова в таблице

`YouTube CDN` и `Netflix CDN` проверялись при каждом запуске, но не выводились. Теперь они идут после GeoIP-баз.
Это страна узла, с которого этому IP отдают видео (видно, далеко ли сервер от него), поэтому в легенде они не учитываются.

## Что исправлено

По сравнению с [Davoyan/ipregion@a85abbf](https://github.com/Davoyan/ipregion/blob/a85abbf739e07b1162bee066d756be1e4b9bfcc0/ipregion.sh):

- **Прокси больше не протекает.** Все запросы идут через одну функцию, поэтому `-p` и `-i` действуют везде
  (раньше мимо них ходили проверка DoH, Spotify Signup, Bing, Steam, PlayStation, Amazon Prime, Google Play и restcountries.com).
  Прокси подключается как `socks5h://`, то есть DNS тоже идёт через него; при заданном прокси DoH не используется.
- **Никакой установки пакетов без спроса.** Без терминала (`ssh host 'bash -s'`, cron) старый скрипт пропускал вопрос
  «установить?» и выполнял `apt install -y` от root. Теперь он останавливается и выводит команду для ручной установки.
  В терминале сначала показывает точную команду установки и спрашивает (по умолчанию — «нет»).
- **Установка аккуратнее:** без `NEEDRESTART_MODE=a` (службы не перезапускаются молча), `column` ставится из
  `bsdextrautils`/`bsdmainutils` вместо переустановки `util-linux`, а на Arch — `pacman -S --needed` вместо частичного обновления `-Syy`.
- **Внешний IP подтверждают два разных сервиса** (`ifconfig.me` был в списке дважды, второй заменён на `icanhazip.com`).
- **Исправлены проверки:** определение блокировки в Amazon Prime, запрос к 2ip.io, ipapi.is (API теперь отдаёт только название страны),
  коды рынков Bing вроде `XL` и `WW` (вместо них берётся страна из login.live.com), имена узлов YouTube CDN вида `tzfraa-cd`.
- **Reddit показывает `Blocked`** вместо пустого значения, когда отвечает страницей блокировки. С домашних IP показывает страну.
- **ipapi.co исключён:** IP дата-центров он отвечает `429 RateLimited`.
- В легенде считаются только коды стран, так что `Yes`, `No`, `Blocked` и подобные значения не попадают в «страны».
- Временные файлы удаляются в любом режиме, мёртвый код убран.
- При каждом пуше скрипт проверяется [ShellCheck](https://www.shellcheck.net/) (GitHub Actions).

## Что добавил форк Davoyan

По сравнению с оригиналом в [Davoyan/ipregion](https://github.com/Davoyan/ipregion):

- **Улучшено определение IPv6** — раньше в некоторых случаях работало ненадёжно.
- **Исправлены зависания** на некоторых сервисах.
- **Выровнена таблица вывода.**
- **Проверки YouTube и Google разделены** — иногда они показывают разные регионы.
- **Правильно определяется Google China (CN).**
- **Добавлены сервисы:** 2ip.io, YouTube Music, Bing и Amazon Prime.
- **ASN по базе MaxMind** — так же, как в [IPQuality](https://github.com/xykt/IPQuality/).
- **CDN убраны из группы по умолчанию** — при необходимости проверяются отдельно.
- **Понятный вывод:** названия стран вместо одних кодов и проценты по сервисам.
- **Исправлены мелкие ошибки**, например скрипт нельзя было прервать во время работы.

Список выше пересказывает README Davoyan. В этом форке строки CDN снова выводятся в общей таблице (см. выше).

## Возможности

- Проверка местоположения IP по нескольким публичным GeoIP-базам
- Результаты и от GeoIP-баз, и от популярных сервисов (YouTube, Netflix, Twitch и др.)
- IPv4 и IPv6 (можно проверять по отдельности)
- Работа через SOCKS5-прокси и через выбранный сетевой интерфейс
- Вывод в JSON для автоматизации
- Цветная таблица, которую легко читать

## Что нужно для работы

- bash
- curl
- jq
- `column`: из util-linux, а в Debian и Ubuntu — из bsdextrautils или bsdmainutils

Если чего-то не хватает, скрипт покажет точную команду установки и спросит, выполнить ли её.

## Коды стран

Скрипт выводит коды стран в формате ISO 3166-1 alpha-2 (например, RU, US, DE).
В обычном выводе рядом с кодом показываются **название страны** и **доля сервисов**, которые её видят.

Код можно проверить на сайте ISO: [https://www.iso.org/obp/ui/#search/code/](https://www.iso.org/obp/ui/#search/code/)

### Примеры

```bash
# Опции работают и при запуске прямо с GitHub
bash <(curl -fsSL https://raw.githubusercontent.com/XaksFlaX/ipregion-fixed/main/ipregion.sh) --group primary

# Справка
bash ipregion.sh --help

# Все проверки с настройками по умолчанию
bash ipregion.sh

# Только GeoIP-базы
bash ipregion.sh --group primary

# Только CDN
bash ipregion.sh --group cdn

# Только репутация IP (хостинг/VPN) и DNS-резолвер
bash ipregion.sh --group network

# Только популярные сервисы
bash ipregion.sh --group custom

# Только IPv4
bash ipregion.sh --ipv4

# Только IPv6
bash ipregion.sh --ipv6

# Через SOCKS5-прокси
bash ipregion.sh --proxy 127.0.0.1:1080

# Через конкретный сетевой интерфейс
bash ipregion.sh --interface eth1

# Время ожидания ответа, секунд
bash ipregion.sh --timeout 20

# Проверять сервисы по одному, а не по 6 сразу
bash ipregion.sh --parallel 1

# Результат в JSON
bash ipregion.sh --json

# Подробный журнал
bash ipregion.sh --verbose
```

Все опции из справки (`-h, --help`) можно сочетать.

## Опции

```
Usage: ipregion.sh [OPTIONS]

Options:
  -h, --help           Справка
  -v, --verbose        Подробный журнал
  -j, --json           Вывод в JSON
  -g, --group GROUP    Только одна группа: 'primary', 'custom', 'cdn', 'network' или 'all' (по умолчанию all)
  -t, --timeout SEC    Время ожидания ответа в секундах (по умолчанию 6)
  -4, --ipv4           Только IPv4
  -6, --ipv6           Только IPv6
  -p, --proxy ADDR     SOCKS5-прокси (host:port)
  -i, --interface IF   Сетевой интерфейс (например, eth1)
  -P, --parallel N     Сколько сервисов проверять одновременно (по умолчанию 6, 1 — по одному)
      --no-update-check  Не проверять на GitHub, вышла ли новая версия
```

## Версии и кэш

В первой строке вывода указана версия, например `ipregion-fixed 2026.10.23.1`. С каждым изменением `ipregion.sh`
поднимается `SCRIPT_VERSION` (`ГГГГ.ММ.ДД.N`), а GitHub Actions не пропускает изменение, если версию забыли поднять.

GitHub кэширует файлы по ссылкам `raw.githubusercontent.com/.../main/...` до 5 минут, поэтому сразу после обновления
ссылка на `main` может ещё отдавать прошлую версию. Ссылка на конкретный коммит всегда актуальна.

Пока идут проверки, скрипт узнаёт на GitHub номер последней версии (читает первые 2 КБ `ipregion.sh` из `main`).
Если она новее, в конце вывода появится «A newer version is available» и команда для запуска, а в JSON — поле `latest_version`.
Если GitHub недоступен, скрипт ничего не пишет. Отключить: `--no-update-check`.

## Лицензия

MIT, см. [LICENSE](LICENSE). Авторские права на исходный скрипт: Nikita Skryabin (vernette).
