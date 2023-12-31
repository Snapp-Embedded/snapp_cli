<p align="center">
    <a href="https://www.snappembedded.io/"><img src="https://img.shields.io/badge/made_by-snapp_embedded-blue" alt="Snapp Embedded"></a>
    <br>
    <a href="https://pub.dev/packages/snapp_cli"><img src="https://badgen.net/pub/flutter-platform/snapp_cli" alt="Platforms"></a>
    <br>
    <a href="https://pub.dev/packages/snapp_cli"><img src="https://img.shields.io/pub/v/snapp_cli?logo=dart&logoColor=white" alt="Pub Version"></a>
    <a href="https://pub.dev/packages/snapp_cli"><img src="https://badgen.net/pub/points/snapp_cli" alt="Pub points"></a>
    <a href="https://pub.dev/packages/snapp_cli"><img src="https://badgen.net/pub/likes/snapp_cli" alt="Pub Likes"></a>
    <a href="https://pub.dev/packages/snapp_cli"><img src="https://badgen.net/pub/popularity/snapp_cli" alt="Pub popularity"></a>
    <br>    
    <a href="https://github.com/Snapp-Embedded/snapp_cli/pulls"><img src="https://img.shields.io/github/issues-pr/Snapp-Embedded/snapp_cli" alt="Repo PRs"></a>
    <a href="https://github.com/Snapp-Embedded/snapp_cli/issues?q=is%3Aissue+is%3Aopen"><img src="https://img.shields.io/github/issues/Snapp-Embedded/snapp_cli" alt="Repo issues"></a>
    <a href="https://github.com/Snapp-Embedded/snapp_cli"><img src="https://img.shields.io/github/stars/Snapp-Embedded/snapp_cli?style=social" alt="Repo stars"></a>
    <a href="https://github.com/Snapp-Embedded/snapp_cli/graphs/contributors"><img src="https://badgen.net/github/contributors/Snapp-Embedded/snapp_cli" alt="Contributors"></a>
    <a href="https://github.com/Snapp-Embedded/snapp_cli/blob/main/LICENSE"><img src="https://badgen.net/github/license/Snapp-Embedded/snapp_cli" alt="License"></a>
    <br>       
    <a href="https://app.codecov.io/gh/Snapp-Embedded/snapp_cli"><img src="https://img.shields.io/codecov/c/github/Snapp-Embedded/snapp_cli?logo=codecov&logoColor=white" alt="Coverage Status"></a>
</p>



## snapp\_cli

`snapp_cli` is a Dart command-line tool designed to simplify the process of adding custom devices to the Flutter SDK. With this tool, you can configure and run your Flutter apps on non-standard or remote devices, such as a Raspberry Pi, while maintaining essential Flutter features like hot reload and hot restart.

## Features

**Custom Device Configuration:** `snapp_cli` allows you to add and manage custom devices for the Flutter SDK. You can specify various device settings, including device names, IP addresses, and port numbers, making it easy to configure custom devices to meet your specific needs.

**Remote Debugging:** With `snapp_cli`, you can remotely debug your Flutter apps on custom devices, such as a Raspberry Pi or other remote hardware. You can run your Flutter app on your custom device with features like hot reload, hot restart, and more, providing a seamless development experience.

**Configurable IP Address:** Easily change the IP address of remote devices in the configuration file if it changes on the device due to DHCP or other reasons. This flexibility ensures that you can adapt to changing network conditions and continue your development without interruption.

## Preconditions

Before using `snapp_cli`, please ensure that you meet the following preconditions:

-   **Secure SSH Connection:** You should have a secure SSH connection between your host machine and the remote device, established using SSH keys. Password-based SSH connections are not supported.
    - Check out this [guide](https://pimylifeup.com/raspberry-pi-ssh-keys/) for more information on setting up SSH keys.
-   **Flutter Linux Configuration:** Make sure that Flutter's Linux configuration is enabled on your host machine. You can enable it using the following command:

``` bash
flutter config --enable-linux-desktop
```

- **Flutter Custom Devices Configuration:** Ensure that Flutter's custom-devices configuration is also enabled on your host machine. You can enable it with the following command:

``` bash
flutter config --enable-custom-devices
```
- **Flutter Installation on Remote Device:** Flutter should be installed and configured on your remote device. If you are using a Raspberry Pi, you can use the `snapp_installer` to install Flutter on your device.

- **Know the Path to Flutter on Remote Device:** You should know the exact path to the Flutter installation on your remote device. You can find the path using the following command on the remote device:

``` bash
which flutter
```
Ensure that you've met these preconditions to use snapp_cli effectively with custom devices and remote debugging.

## Installation

Before using `snapp_cli`, ensure that you have Dart and Flutter installed. You can install the tool using the Dart package manager:

``` bash
dart pub global activate snapp_cli
```

Make sure that system cache bin directory is added to your system's PATH to use snapp_cli globally. follow this link for more information: [Running a script from your PATH](https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path "Running a script from your PATH")

## Commands

`snapp_cli` provides the following commands:

- **devices:** Manage custom devices in the Flutter SDK. with this command you can add, delete, list, and update custom devices. Following sub-commands are available for this command:
   - **add:** Add a custom device configuration.
      - Use the `add` command to add and configure a custom device for the Flutter SDK. You can specify the device name, IP address, and other information to customize your development environment.

   - **delete:** Delete a custom device configuration.
      - The `delete` command allows you to remove a previously configured custom device from your settings.

   - **list:** List configured custom devices.
      - The `list` command displays a list of all the custom devices that is available on the flutter SDK.

   - **update-ip:** Update the IP address of a custom device.
      - The `update-ip` command is used to modify the IP address of an existing custom device configuration. This is useful when the device's IP address changes, such as due to DHCP, and you need to update your settings. Example:
      ``` bash
      snapp_cli devices update-ip 
      ```


------------


Each command has specific options and usage, which you can explore further by running `snapp_cli --help` or `snapp_cli <command> --help`.

## add Command

The `add` command allows you to add and configure a custom device for the Flutter SDK. When you run this command, `snapp_cli` will prompt you with a series of questions to gather the necessary information for custom device configuration.


Use this command to interactively specify the settings for a custom device that you want to use for your Flutter development. The questions will cover details such as:

- SSH Connection Details: You'll be asked for the IP address of your remote device and the username for the SSH connection.

- Path to Flutter on the Remote Device: You'll be prompted to provide the exact path to the Flutter installation on your remote device.

#### Usage 
To add a custom device, simply run the following command:

```
snapp_cli devices add
```

snapp_cli will then guide you through the process, prompting you with questions to gather the necessary information for your custom device configuration. Follow the on-screen prompts to complete the configuration.

## Troubleshooting

### Manually Editing `flutter_custom_devices.json`

In some cases, you may need to manually edit the `flutter_custom_devices.json` file, which stores the configurations for custom devices. Here are the steps to follow if you encounter this situation:

1. **Locate the `flutter_custom_devices.json` File:**
   - The location of the `flutter_custom_devices.json` file can vary depending on the operating system you are using. You can find it with the `snapp_cli list` command.

2. **Backup the File:**
   - Before making any manual changes, it's a good practice to create a backup of the `flutter_custom_devices.json` file in case something goes wrong.

3. **Edit the JSON File:**
   - Use a text editor to open the `flutter_custom_devices.json` file. You can make changes to the device configurations as needed. Ensure that the JSON structure is valid; any syntax errors can cause issues.

4. **Test the Configuration:**
   - To test the changed configuration you need to run your app again.


Keep in mind that manually editing the `flutter_custom_devices.json` file should be done with caution, as incorrect changes can lead to configuration issues. It's recommended to use the CLI tool to add, update, or delete custom devices whenever possible.


## Contributing

If you encounter any issues with this package or have suggestions for improvements, please [open an issue](https://github.com/Snapp-Embedded/snapp_cli/issues). You are welcome to contribute to the development of this project by forking the repository and submitting pull requests.

## License

This project is licensed under the MIT License

