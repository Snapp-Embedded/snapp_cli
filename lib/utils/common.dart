// ignore_for_file: implementation_imports

import 'dart:io';
import 'package:flutter_tools/src/base/io.dart';

final RegExp hostnameRegex = RegExp(
    r'^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$');

final RegExp pathRegex = RegExp(r'^(.+)\/([^\/]+)$');

extension StringExt on String {
  bool get isValidIpAddress => InternetAddress.tryParse(this) != null;

  bool get isValidHostname => hostnameRegex.hasMatch(this);

  bool get isValidPath => pathRegex.hasMatch(this);
}

extension IpExt on InternetAddress {
  String get ipAddress => address;

  bool get isIpv4 => type == InternetAddressType.IPv4;
  bool get isIpv6 => type == InternetAddressType.IPv6;

  String sshTarget([String username = '']) =>
      (username.isNotEmpty ? '$username@' : '') +
      (type == InternetAddressType.IPv6 ? '[$address]' : address);
}
