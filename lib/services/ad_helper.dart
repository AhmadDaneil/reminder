import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if(Platform.isAndroid){
      return 'ca-app-pub-2039694461304943/1295988887';
    } else if(Platform.isIOS) {
      return 'ca-app-pub-2039694461304943/4970707687';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}