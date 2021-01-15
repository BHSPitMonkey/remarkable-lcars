# reMarkable LCARS: A dynamic suspend screen for your reMarkable tablet

## Installation

Over an SSH session, checkout this repository on your device and run:

    make install

from this directory.

## Configuration

After installation, edit `/opt/etc/remarkable-lcars.conf` and add an API key
from your OpenWeather account, as well as your latitude/longitude coordinates
and preferred units.

## Usage

After installation, your `suspended.png` image will be replace automatically
every day (at the time specified in `remarkable-lcars.timer`).

You can also run it manually at any time:

```bash
systemctl start remarkable-lcars.service
```

Or, if you want to output the PNG to a custom destination:

```bash
remarkable-lcars [DESTINATION]
```

## License

TBD (All rights reserved)