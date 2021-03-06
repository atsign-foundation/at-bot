import 'dart:convert';
import 'dart:io';

import 'package:at_bot/src/services/atsign.service.dart';
import 'package:at_bot/src/utils/provider.util.dart';
// import 'package:http/http.dart' as http;
import 'package:at_client/at_client.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_commons/at_commons.dart' as commons;
import 'package:at_lookup/at_lookup.dart';
import 'package:at_server_status/at_server_status.dart';
import 'package:crypton/crypton.dart';
import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:riverpod/riverpod.dart';

import '../utils/constants.util.dart';

class AtSignAPI {
  // create a singleton
  AtSignAPI._internal() {
    _init();
  }
  factory AtSignAPI() => _singleton;
  static final AtSignAPI _singleton = AtSignAPI._internal();

  static late IOClient _client = IOClient();
  static bool _clientInitialized = false;

  static void _init() {
    HttpClient ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    _client = IOClient(ioc);
    _clientInitialized = true;
  }

  bool Function(X509Certificate cert, String host, int port) ioc =
      HttpClient().badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

  static Future<String> getNewAtsign(bool isDev) async {
    if (!_clientInitialized) {
      _init();
    }
    http.Response wtf = await _client.get(
      Uri.https(isDev ? Constants.devDomain : Constants.prodDomain,
          Constants.path + Constants.getFreeAtSign),
      headers: <String, String>{
        'Authorization': isDev ? Constants.devApiKey() : Constants.prodApiKey(),
        'Content-Type': 'application/json',
      },
    );

    if (wtf.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(wtf.body);
      return '@' + body['data']['atsign'].toString();
    } else {
      return wtf.statusCode.toString();
    }
  }

  static Future<Map<String, dynamic>> registerAtSign(
      String email, String atSign, bool isDev) async {
    if (!_clientInitialized) {
      _init();
    }
    String path = Constants.path + Constants.registerAtSign;
    Map<String, String?> body = <String, String?>{
      'email': email,
      'atsign': atSign
    };
    http.Response response = await _client.post(
      Uri.https(isDev ? Constants.devDomain : Constants.prodDomain, path),
      body: json.encode(body),
      headers: <String, String>{
        'Authorization': isDev ? Constants.devApiKey() : Constants.prodApiKey(),
        'Content-Type': 'application/json',
      },
    );
    Map<String, dynamic> responseBody = jsonDecode(response.body);
    return responseBody;
  }

  static Future<Map<String, dynamic>> validatingOTP(
      String atSign, String email, String otp,
      {bool confirmation = false, required bool isDev}) async {
    if (!_clientInitialized) {
      _init();
    }
    String path = Constants.path + Constants.validateOTP;
    Map<String, String?> body = <String, String?>{
      'email': email,
      'atsign': atSign.replaceAll('@', ''),
      'otp': otp,
      'confirmation': confirmation.toString()
    };

    http.Response response = await _client.post(
      Uri.https(isDev ? Constants.devDomain : Constants.prodDomain, path),
      body: json.encode(body),
      headers: <String, String>{
        'Authorization': isDev ? Constants.devApiKey() : Constants.prodApiKey(),
        'Content-Type': 'application/json',
      },
    );
    return json.decode(response.body);
  }

  static Future<void> initialAuthenticate(String atSign,
      {required AtClientPreference atClientPreference,
      required ProviderContainer container}) async {
    bool dev = container.read(isDev.state).state;
    // AtLookupImpl atLookupInitialAuth = container.read(atLookupFamily(atSign));
    AtLookupImpl atLookupInitialAuth = AtLookupImpl(
        atSign,
        dev ? Constants.devRootDomain : Constants.prodRootDomain,
        Constants.port);
    if (atClientPreference.cramSecret == null) {
      print('CRAM null');
    } else {
      try {
        bool isCramSuccessful = await atLookupInitialAuth
            .authenticate_cram(atClientPreference.cramSecret);
        print('CRAM authentications: $isCramSuccessful');
      } on commons.UnAuthenticatedException catch (e) {
        print('Auth failed');
        print(e.message);
      }
    }
  }

  static RSAKeypair generateKeyPair() => RSAKeypair.fromRandom();

  static String generateAESKey() {
    AES aesKey = AES(Key.fromSecureRandom(32));
    String keyString = aesKey.key.base64;
    return keyString;
  }

  static Future<AtSignStatus?> checkAtsignStatus(String? atsign,
      {required ProviderContainer container}) async {
    bool dev = container.read(isDev.state).state;
    if (atsign == null) {
      return null;
    }
    atsign = AtSignService.formatAtSign(atsign);
    // AtStatusImpl atStatusImpl = container.read(atStatusProvider);
    AtStatusImpl atStatusImpl = AtStatusImpl(
        rootUrl: dev ? Constants.devRootDomain : Constants.prodRootDomain,
        rootPort: Constants.port);
    AtStatus getStatus = await atStatusImpl.get(atsign!);
    return getStatus.status();
  }

  static Future<AtStatus?> checkAtSignServerStatus(String atsign,
      {required ProviderContainer container}) async {
    bool dev = container.read(isDev.state).state;
    AtStatusImpl atStatusImpl = AtStatusImpl(
        rootUrl: dev ? Constants.devRootDomain : Constants.prodRootDomain,
        rootPort: Constants.port);
    // AtStatusImpl atStatusImpl = container.read(atStatusProvider);
    return atStatusImpl.get(atsign);
  }

  Future<void> putData() async {
    Directory atSignDir = Directory('/home/at_sign/');
    if (!await atSignDir.exists()) {
      await atSignDir.create(recursive: true);
    }
    AtClientPreference preference = AtClientPreference();
    preference.hiveStoragePath = '/home/at_sign/';
    preference.commitLogPath = '/home/at_sign/';
    preference.isLocalStoreRequired = true;
    preference.rootDomain = Constants.prodRootDomain;

    AtClientManager atClientManager = await AtClientManager.getInstance()
        .setCurrentAtSign('atSign', null, preference);
    RSAKeypair keyPair = generateKeyPair();
    RSAKeypair publickeyPair = generateKeyPair();
    String aes = generateAESKey();
    AtClient atClient = atClientManager.atClient;
    Metadata metadata = Metadata();
    metadata.namespaceAware = false;
    bool privateKeyResult = await atClient
        .getLocalSecondary()!
        .putValue(AT_PKAM_PRIVATE_KEY, keyPair.privateKey.toString());
    bool publicKeyResult = await atClient
        .getLocalSecondary()!
        .putValue(AT_PKAM_PUBLIC_KEY, keyPair.publicKey.toString());
    bool encryptionPrivateKey = await atClient.getLocalSecondary()!.putValue(
        AT_ENCRYPTION_PRIVATE_KEY, publickeyPair.privateKey.toString());
    bool aesKeyResult = await atClient
        .getLocalSecondary()!
        .putValue(AT_ENCRYPTION_SELF_KEY, aes.toString());
    metadata.isPublic = true;
    AtKey atKey = AtKey()
      ..key = 'publickey'
      ..metadata = metadata;
    bool result = await atClient.put(atKey, publickeyPair.publicKey.toString());
    print('privateKeyResult: $privateKeyResult');
    print('publicKeyResult: $publicKeyResult');
    print('encryptionPrivateKey: $encryptionPrivateKey');
    print('aesKeyResult: $aesKeyResult');
    print('result: $result');
  }
}
