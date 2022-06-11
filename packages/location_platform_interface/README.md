# location_platform_interface

A common platform interface for the `location` plugin.

This interface allows platform-specific implementations of the `location` plugin, as well as the plugin itself, to ensure they are supporting the same interface.

# Usage

To implement a new platform-specific implementation of `location`, extend `LocationPlatform` with an implementation that performs the platform-specific behavior.
