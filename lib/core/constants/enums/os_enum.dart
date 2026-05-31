import 'dart:io';

enum OsEnum {
  android,
  ios;

  static OsEnum get currentOs =>
      Platform.isIOS ? OsEnum.ios : OsEnum.android;
}
