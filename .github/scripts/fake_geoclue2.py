#!/usr/bin/env python3
"""A minimal fake org.freedesktop.GeoClue2 D-Bus service for CI.

Implements just enough of the real GeoClue2 D-Bus protocol (as used by
packages/location/linux/location_plugin.cc) to drive the Linux e2e tests
without a real GeoClue2 daemon or GPS hardware:

  - org.freedesktop.GeoClue2.Manager.GetClient() -> client object path
  - org.freedesktop.GeoClue2.Client.{Start,Stop}()
  - org.freedesktop.DBus.Properties.{Get,Set,GetAll} on the client
    (DesktopId, RequestedAccuracyLevel)
  - org.freedesktop.GeoClue2.Client.LocationUpdated(old_path, new_path) signal
  - org.freedesktop.GeoClue2.Location.{Latitude,Longitude,Accuracy,Altitude,
    Speed,Heading} properties on the location object the signal points to

Must run on the SYSTEM bus (that's what real GeoClue2 uses, and what the
plugin connects to) -- see the e2e workflow for the D-Bus policy/ownership
setup this requires.

The mock coordinates are read from a JSON file (path given as argv[1]) that
the CI script can rewrite at any time; this process polls it and emits a
fresh LocationUpdated signal whenever the content changes, which is how the
listen_location_test.dart "second, distinct fix mid-test" assertion works.
"""

import json
import sys
import time

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

BUS_NAME = "org.freedesktop.GeoClue2"
MANAGER_PATH = "/org/freedesktop/GeoClue2/Manager"
MANAGER_IFACE = "org.freedesktop.GeoClue2.Manager"
CLIENT_IFACE = "org.freedesktop.GeoClue2.Client"
LOCATION_IFACE = "org.freedesktop.GeoClue2.Location"
CLIENT_PATH = "/org/freedesktop/GeoClue2/Client/0"

POLL_INTERVAL_SECONDS = 0.5


class Location(dbus.service.Object):
    def __init__(self, bus, path, lat, lon):
        super().__init__(bus, path)
        self._props = {
            "Latitude": dbus.Double(lat),
            "Longitude": dbus.Double(lon),
            "Accuracy": dbus.Double(5.0),
            "Altitude": dbus.Double(0.0),
            "Speed": dbus.Double(0.0),
            "Heading": dbus.Double(0.0),
        }

    @dbus.service.method(
        "org.freedesktop.DBus.Properties", in_signature="ss", out_signature="v"
    )
    def Get(self, interface, name):
        return self._props[name]

    @dbus.service.method(
        "org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}"
    )
    def GetAll(self, interface):
        return dbus.Dictionary(self._props, signature="sv")


class Client(dbus.service.Object):
    def __init__(self, bus, mock_file):
        super().__init__(bus, CLIENT_PATH)
        self._bus = bus
        self._mock_file = mock_file
        self._started = False
        self._location_index = 0
        self._current_location_path = None
        self._props = {
            "DesktopId": dbus.String(""),
            "RequestedAccuracyLevel": dbus.UInt32(8),
        }
        self._last_seen = None

    @dbus.service.method(CLIENT_IFACE)
    def Start(self):
        self._started = True
        self._maybe_publish(force=True)

    @dbus.service.method(CLIENT_IFACE)
    def Stop(self):
        self._started = False

    @dbus.service.method(
        "org.freedesktop.DBus.Properties", in_signature="ss", out_signature="v"
    )
    def Get(self, interface, name):
        return self._props[name]

    @dbus.service.method(
        "org.freedesktop.DBus.Properties", in_signature="ssv"
    )
    def Set(self, interface, name, value):
        self._props[name] = value

    @dbus.service.method(
        "org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}"
    )
    def GetAll(self, interface):
        return dbus.Dictionary(self._props, signature="sv")

    @dbus.service.signal(CLIENT_IFACE, signature="oo")
    def LocationUpdated(self, old_path, new_path):
        pass

    def poll(self):
        self._maybe_publish(force=False)
        return True  # keep the GLib timeout running

    def _maybe_publish(self, force):
        try:
            with open(self._mock_file) as f:
                mock = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return

        key = (mock.get("latitude"), mock.get("longitude"))
        if not self._started or (not force and key == self._last_seen):
            return
        self._last_seen = key

        self._location_index += 1
        new_path = f"{CLIENT_PATH}/Location/{self._location_index}"
        Location(self._bus, new_path, key[0], key[1])

        old_path = self._current_location_path or "/"
        self._current_location_path = new_path
        self.LocationUpdated(old_path, new_path)


class Manager(dbus.service.Object):
    def __init__(self, bus, client):
        super().__init__(bus, MANAGER_PATH)
        self._client = client

    @dbus.service.method(MANAGER_IFACE, out_signature="o")
    def GetClient(self):
        return CLIENT_PATH


def main():
    if len(sys.argv) != 2:
        print("usage: fake_geoclue2.py <mock-location-json-file>", file=sys.stderr)
        sys.exit(1)
    mock_file = sys.argv[1]

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    bus_name = dbus.service.BusName(BUS_NAME, bus)

    client = Client(bus, mock_file)
    Manager(bus, client)

    GLib.timeout_add(int(POLL_INTERVAL_SECONDS * 1000), client.poll)

    print("fake GeoClue2 ready", flush=True)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
