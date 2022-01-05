// import 'package:at_bot/src/utils/constants.util.dart';
// import 'package:at_server_status/at_status_impl.dart';
// import 'package:at_lookup/at_lookup.dart';
import 'package:riverpod/riverpod.dart';

final StateProvider<Map<String, String>> atSignMail =
    StateProvider<Map<String, String>>((_) => <String, String>{});
final StateProvider<bool> isDev = StateProvider<bool>((_) => false);

// final Provider<AtStatusImpl> atStatusProvider = Provider<AtStatusImpl>(
//     (_) => AtStatusImpl(rootUrl: Constants.prodRootDomain));

// final ProviderFamily<AtLookupImpl, String> atLookupFamily =
//     Provider.family<AtLookupImpl, String>(
//   (_, String atSign) => AtLookupImpl(
//     atSign,
//     Constants.prodRootDomain,
//     Constants.port,
//   ),
// );
