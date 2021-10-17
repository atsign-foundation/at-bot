import 'dart:async';

import 'package:at_bot/src/utils/constants.util.dart';
import 'package:nyxx/nyxx.dart' as nyxx;
import 'package:nyxx_interactions/interactions.dart';
import 'package:nyxx_lavalink/lavalink.dart';

Future<StreamSubscription<TrackStartEvent>> onMusicEvent(Cluster cluster) async {
  nyxx.Message? musicMsg;
  return cluster.onTrackStart.listen((TrackStartEvent event) async {
    try {
      GuildPlayer? player = event.node.players[event.guildId];
      if (player == null) return;
      QueuedTrack? nowPlaying = player.nowPlaying;
      if (nowPlaying == null) return;
      List<QueuedTrack> queue = player.queue;
      nyxx.TextGuildChannel channel = await event.client.fetchChannel<nyxx.TextGuildChannel>(nowPlaying.channelId!);
      nyxx.EmbedBuilder embed = nyxx.EmbedBuilder();
      embed.title = 'Track started';
      embed.description = 'Playing ${nowPlaying.track.info?.title}';
      embed.fields
        ..add(nyxx.EmbedFieldBuilder('By', nowPlaying.track.info!.author))
        ..add(nyxx.EmbedFieldBuilder('Requested by', '<@${nowPlaying.requester}>'))
        ..add(nyxx.EmbedFieldBuilder('Duration', millisToMinutesAndSeconds(nowPlaying.track.info!.length) + ' mins'))
        ..add(nyxx.EmbedFieldBuilder('Link', nowPlaying.track.info!.uri));
      List<IComponentBuilder> musicComponents = <IComponentBuilder>[
        ButtonBuilder('⏮️', 'seek', nyxx.ComponentStyle.secondary),
        ButtonBuilder('▶️', 'resume', nyxx.ComponentStyle.secondary),
        ButtonBuilder('⏸️', 'pause', nyxx.ComponentStyle.secondary),
        ButtonBuilder('⏭️', 'skip', nyxx.ComponentStyle.secondary),
      ];
      ComponentMessageBuilder messageBuilder = ComponentMessageBuilder()
        ..embeds = <nyxx.EmbedBuilder>[embed]
        ..components = <List<IComponentBuilder>>[musicComponents];
      ComponentMessageBuilder noBtns = messageBuilder;
      if (queue.isEmpty || nowPlaying.track.track.isEmpty) {
        try {
          await musicMsg?.edit(noBtns..components?.clear());
        } on Exception catch (e) {
          print(e.toString());
        }
      } else if (queue.length < 2) {
        try {
          await musicMsg?.edit(noBtns..components?.clear());
          musicMsg = await channel.sendMessage(
            messageBuilder..components ??= <List<IComponentBuilder>>[musicComponents],
          );
        } on Exception catch (e) {
          print(e.toString());
        }
      } else {
        try {
          if (musicMsg!.components.isEmpty) {
            await musicMsg?.edit(messageBuilder..components = <List<IComponentBuilder>>[]);
          } else {
            await musicMsg?.edit(noBtns..components = <List<IComponentBuilder>>[]);
          }
          if (messageBuilder.components!.isEmpty) {
            musicMsg = await channel.sendMessage(
              messageBuilder..components!.add(musicComponents),
            );
          } else {
            musicMsg = await channel.sendMessage(
              messageBuilder
                ..components!.clear()
                ..components!.add(musicComponents),
            );
          }
        } on Exception catch (e) {
          print(e.toString());
        }
      }
    } on Exception catch (e) {
      print(e.toString());
    }
  });
}
