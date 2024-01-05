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
</p>


## snapp\_cli

`snapp_cli` is a powerful command-line interface tool designed to simplify the integration of embedded devices (like Raspberry Pi) with Flutter applications. Effortlessly manage your embedded devices, establish secure SSH connections, and streamline the development process by installing Flutter directly onto your custom devices from your PC.

## Features
- **🛠️ Single Command Setup:** Prepare your custom device completely by adding it to Flutter, establishing SSH connection, installing Flutter, and running your app—all with a single command.
- **📱 Device Management:** Add, list, and remove custom(**embedded**) devices effortlessly.
- **🔒 Automatic SSH Connection:** Configure and establish SSH connections to devices with ease.
- **🚀 Flutter Installation:** Install Flutter directly onto your custom devices from your PC.
- **🔥 Run & Debug Flutter Apps:** Utilize hot reload, hot restart, and Dart DevTools for efficient app development.
- **🎛️ User-Friendly Interface:** Intuitive CLI for seamless navigation and usage.

## Installation

Before using `snapp_cli`, ensure that you have Dart and Flutter installed. You can install the tool using the Dart package manager:

``` bash
dart pub global activate snapp_cli
```

Make sure that system cache bin directory is added to your system's PATH to use snapp_cli globally. follow this link for more information: [Running a script from your PATH](https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path "Running a script from your PATH")

## Usage

#### Single Command Setup - **Bootstrap**

Bootstrap command is a way to setup a device from scratch.
It will add a new device to custom devices, create a ssh connection to the device,
install flutter on the device and finally help you to run your app on the device.

```bash
$ snapp_cli bootstrap
```

#### Device Management

- **List Devices:** Display all connected/embedded devices.
    ```bash
    $ snapp_cli devices list
    ```
- **Add a Device:** Add a new device to the Flutter SDK.
   ```bash
   $ snapp_cli devices add 
   ```
- **Delete a Device:** Remove a device from the Flutter SDK.
    ```bash
    $ snapp_cli devices delete
    ```
- **Update Device IP:** Update the IP address of a device.
    ```bash
    $ snapp_cli devices update-ip
    ```
- **Install Flutter:** Install Flutter directly onto a device.
    ```bash
    $ snapp_cli devices install-flutter
    ```

#### SSH Connection

- **Create SSH Connection:** Create a passwordless SSH connection to a device.
    ```bash
    $ snapp_cli ssh create-connection
    ```
- **Test SSH Connection:** Test a passwordless SSH connection to a device.
    ```bash
    $ snapp_cli ssh test-connection
    ```

------------------------------------

Each command has specific options and usage, which you can explore further by running `snapp_cli --help` or `snapp_cli <command> --help`.

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

