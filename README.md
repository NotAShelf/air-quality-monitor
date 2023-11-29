# Raspberry Pi Air Quality Monitor

A simple air quality monitoring service for the Raspberry Pi.

## Installation

There are multiple ways to install this program. The main highlight of this fork is Nix & NixOS support, which would be the recommended way.
If you depend on Docker for running this program, refer to the original repository.

### With Nix

If you are on non-NixOS, but still have Nix installed on your system; you can install the package with

```bash
nix profile install github:notashelf/air-quality-monitor
```

After which you can use the installed package inside `screen` or with a Systemd service.

### On NixOS

This flake provides a NixOS module for automatically configuring the systemd service as well as the redis database for you.
A sample configuration would be as follows:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pi-air-monitor.url = "github:notashelf/air-quality-monitor";
  };

  outputs = { self, nixpkgs, ... } @ inputs:  {
    nixosConfigurations."<yourHostname>" = nixpkgs.lib.nixosSystem {
      # ...
      services.pi-air-quality-monitor = {
        enable = true;
        openFirewall = true; # if you want your service to only serve locally, disable this - defaults to true

        settings = {
          port = 8081; # serve web application on port 8081
          user = "pi-aqm";
          group = "pi-aqm";
          serialPort = "/dev/ttyUSB0"; # this is the serial port that corresponds to your sensor device

          redis.createLocally = true;
        };
      };
      # ...
    };
  };
}
```

The above configuration will set up a systemd service and configure necessary environment variables for you without any additional input.
Plug in your sensor, and observe.

For a more hands-on approach, you may also choose to add `pi-air-monitor` package exposed by this flake to your systemPackages and
use it manually, or write your own systemd service.

## Example Data

Some example data you can get from the sensor includes the following:

```json
{
  "device_id": 13358,
  "pm10": 10.8,
  "pm2.5": 4.8,
  "timestamp": "2021-06-16 22:12:13.887717"
}
```

The sensor reads two particulate matter (PM) values.

PM10 is a measure of particles less than 10 micrometers, whereas PM 2.5 is a measurement of finer particles, less than 2.5 micrometers.

Different particles are from different sources, and can be hazardous to different parts of the respiratory system.

## Useful references

- [SDS011 datasheet](https://cdn-reichelt.de/documents/datenblatt/X200/SDS011-DATASHEET.pdf)
- [Air Quality Index meaning](https://www.airnow.gov/aqi/aqi-basics/)
