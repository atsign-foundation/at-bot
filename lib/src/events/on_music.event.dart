// // ignore_for_file: cast_nullable_to_non_nullable

// import 'dart:async';

// import 'package:at_bot/src/utils/constants.util.dart';
// import 'package:nyxx/nyxx.dart' as nyxx;
// import 'package:nyxx_interactions/nyxx_interactions.dart';
// import 'package:nyxx_lavalink/nyxx_lavalink.dart';

// Future<StreamSubscription<ITrackStartEvent>> onMusicEvent(
//     ICluster cluster) async {
//   nyxx.IMessage? musicMsg;
//   return cluster.eventDispatcher.onTrackStart
//       .listen((ITrackStartEvent event) async {
//     try {
//       IGuildPlayer? player = event.node.players[event.guildId];
//       if (player == null) return;
//       IQueuedTrack? nowPlaying = player.nowPlaying;
//       if (nowPlaying == null) return;
//       List<IQueuedTrack> queue = player.queue;
//       nyxx.IChannel? channel = event.client.channels[nowPlaying.channelId];
//       nyxx.EmbedBuilder embed = nyxx.EmbedBuilder();
//       embed.title = 'Track started';
//       embed.description = 'Playing ${nowPlaying.track.info?.title}';
//       embed.fields
//         ..add(nyxx.EmbedFieldBuilder('By', nowPlaying.track.info!.author))
//         ..add(nyxx.EmbedFieldBuilder(
//             'Requested by', '<@${nowPlaying.requester}>'))
//         ..add(nyxx.EmbedFieldBuilder('Duration',
//             millisToMinutesAndSeconds(nowPlaying.track.info!.length) + ' mins'))
//         ..add(nyxx.EmbedFieldBuilder('Link', nowPlaying.track.info!.uri));
//       List<ButtonBuilder> musicComponents = <ButtonBuilder>[
//         ButtonBuilder('⏮️', 'seek', nyxx.ButtonStyle.secondary),
//         ButtonBuilder('▶️', 'resume', nyxx.ButtonStyle.secondary),
//         ButtonBuilder('⏸️', 'pause', nyxx.ButtonStyle.secondary),
//         ButtonBuilder('⏭️', 'skip', nyxx.ButtonStyle.secondary),
//       ];
//       ComponentMessageBuilder messageBuilder = ComponentMessageBuilder()
//         ..embeds = <nyxx.EmbedBuilder>[embed]
//         ..componentRows = <List<ButtonBuilder>>[musicComponents];
//       ComponentMessageBuilder noBtns = messageBuilder;
//       if (queue.isEmpty || nowPlaying.track.track.isEmpty) {
//         try {
//           await musicMsg?.edit(noBtns..componentRows?.clear());
//         } on Exception catch (e) {
//           print(e.toString());
//         }
//       } else if (queue.length < 2) {
//         try {
//           await musicMsg?.edit(noBtns..componentRows?.clear());
//           musicMsg = await (channel as nyxx.ITextGuildChannel).sendMessage(
//             messageBuilder
//               ..componentRows ??= <List<ButtonBuilder>>[musicComponents],
//           );
//         } on Exception catch (e) {
//           print(e.toString());
//         }
//       } else {
//         try {
//           if (musicMsg!.components.isEmpty) {
//             await musicMsg?.edit(
//                 messageBuilder..componentRows = <List<ButtonBuilder>>[]);
//           } else {
//             await musicMsg
//                 ?.edit(noBtns..componentRows = <List<ButtonBuilder>>[]);
//           }
//           if (messageBuilder.componentRows!.isEmpty) {
//             musicMsg = await (channel as nyxx.ITextGuildChannel).sendMessage(
//               messageBuilder..componentRows!.add(musicComponents),
//             );
//           } else {
//             musicMsg = await (channel as nyxx.ITextGuildChannel).sendMessage(
//               messageBuilder
//                 ..componentRows!.clear()
//                 ..componentRows!.add(musicComponents),
//             );
//           }
//         } on Exception catch (e) {
//           print(e.toString());
//         }
//       }
//     } on Exception catch (e) {
//       print(e.toString());
//     }
//   });
// }
