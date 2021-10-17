// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:dotenv/dotenv.dart';
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_lavalink/lavalink.dart';

Future<void> onMusicCommand(nyxx.MessageReceivedEvent event, List<String>? args, {Cluster? cluster}) async {
  try {
    /// args is null or args length is not equal to 3, return.
    if (args == null || args.isEmpty) return;
    nyxx.Message? context = event.message;
    nyxx.Guild? guild = (context as nyxx.GuildMessage).guild.getFromCache()!;
    nyxx.GuildChannel? voiceChannel = guild.channels
        .firstWhere((nyxx.GuildChannel? channel) => channel!.id == env['music_channel_id']!.toSnowflake());
    nyxx.VoiceState? userState = guild.voiceStates.findOne((nyxx.VoiceState item) => item.user.id == context.author.id);
    nyxx.VoiceState? botState =
        guild.voiceStates.findOne((nyxx.VoiceState item) => item.user.id == env['botID'].toString().toSnowflake());
    // If args[0] is join, then join to voice channel.
    if (args[0] == 'join') {
      try {
        if (userState == null || userState.channel == null) {
          await context.channel.sendMessage(
            MessageContent.custom('You need to be connected to a voice chat to use this command'),
          );
          return;
        }
        if (botState != null && botState.channel != null) {
          await context.channel.sendMessage(MessageBuilder.content("I'm already in <#${botState.channel!.id}>."));
          return;
        }
        if (voiceChannel.id.isZero || voiceChannel.name.isEmpty) {
          await context.channel.sendMessage(
            MessageContent.custom(
              'Could not find voice channel with name: ${args[1]}',
            ),
          );
          return;
        }
        cluster!.getOrCreatePlayerNode(context.guild.id);
        (voiceChannel as VoiceGuildChannel).connect(selfDeafen: true);
        return;
      } on ClusterException catch (_) {
        await context.channel.sendMessage(
          MessageContent.custom(
            'Could not find enough nodes to join in voice channel. Try again after a while.',
          ),
        );
        return;
      }
    } else if (args[0] == 'leave' || args[0] == 'l' || args[0] == 'exit' || args[0] == 'e') {
      if (userState == null || userState.channel == null) {
        await context.channel.sendMessage(
          MessageContent.custom('You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null || botState.channel == null) {
        await context.channel.sendMessage(MessageBuilder.content("I'm not connected to any voice channel"));
        return;
      }
      // await context.edit(messageBuilder..components!.clear());
      cluster!.getOrCreatePlayerNode(context.guild.id).destroy(context.guild.id);
      (voiceChannel as VoiceGuildChannel).disconnect();
      await context.channel.sendMessage(MessageBuilder.content('Left the voice channel.'));
    } else if (args[0] == 'add') {
      if (userState == null || userState.channel == null) {
        await context.channel.sendMessage(
          MessageContent.custom('You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null || botState.channel == null) {
        await context.channel.sendMessage(MessageBuilder.content("I'm not connected to any voice channel"));
        return;
      }
      args.removeRange(0, 1);
      String query = args.join(' ');
      Node node = cluster!.getOrCreatePlayerNode(context.guild.id);
      Tracks results = await node.autoSearch(query, platform: SearchPlatform.soundcloud);
      if (results.tracks.isEmpty) {
        await context.channel.sendMessage(MessageBuilder.content('No matches with $query'));
        return;
      }
      node
          .play(
            Snowflake(context.guild.id),
            results.tracks[0],
            channelId: context.channel.id,
            requester: event.message.author.id,
          )
          .queue();
      await context.channel.sendMessage(MessageContent.custom('Added ${results.tracks[0].info!.title} to queue'));
    } else if (args[0] == 'play') {
      if (args.length < 2) {
        await context.channel.sendMessage(MessageContent.custom('No track provided.'));
        return;
      }
      if (userState == null || userState.channel == null) {
        await context.channel.sendMessage(
          MessageContent.custom('You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null || botState.channel == null) {
        await context.channel.sendMessage(MessageBuilder.content("I'm not connected to any voice channel"));
        return;
      }
      Node node = cluster!.getOrCreatePlayerNode(context.guild.id);
      GuildPlayer? player = node.players[context.guild.id];
      if (player != null) {
        List<QueuedTrack> queue = player.queue.toList();
        if (queue.isNotEmpty) {
          await context.channel.sendMessage(
              MessageContent.custom('Use **${env['prefix']}music add** ***YOUR SONG NAME*** to add it to the queue.'));
          return;
        }
      }
      args.removeRange(0, 1);
      String query = args.join(' ');
      Tracks results = await node.autoSearch(query);
      if (results.tracks.isEmpty) {
        await context.channel.sendMessage(MessageBuilder.content('No matches with $query'));
        return;
      }
      node
          .play(
            Snowflake(context.guild.id),
            results.tracks[0],
            channelId: context.channel.id,
            requester: event.message.author.id,
          )
          .queue();
    } else if (args[0] == 'pause' || args[0] == 'p') {
      Node node = cluster!.getOrCreatePlayerNode(context.guild.id);
      node.pause(context.guild.id);
    } else if (args[0] == 'resume' || args[0] == 'r') {
      Node node = cluster!.getOrCreatePlayerNode(context.guild.id);
      node.resume(context.guild.id);
    } else if (args[0] == 'node' || args[0] == 'n') {
      await context.channel.sendMessage(MessageContent.custom('${cluster!.connectedNodes.length} connected nodes'));
      return;
    } else if (args[0] == 'queue' || args[0] == 'q') {
      if (botState == null || botState.channel == null) {
        await context.channel.sendMessage(MessageBuilder.content("I'm not connected to any voice channel"));
        return;
      }
      Node node = cluster!.getOrCreatePlayerNode(context.guild.id);
      GuildPlayer? player = node.players[context.guild.id];
      if (player == null) return;
      List<QueuedTrack> queue = player.queue.toList();
      if (queue.isEmpty) {
        await context.channel.sendMessage(MessageContent.custom('Queue is empty'));
        return;
      } else {
        List<String> queueList = <String>[];
        for (QueuedTrack element in queue) {
          queueList.add('▶️ - ' + element.track.info!.title);
        }
        await context.channel.sendMessage(MessageContent.custom(queueList.join('\n')));
        return;
      }
    } else if (args[0] == 'skip') {
      if (userState == null || userState.channel == null) {
        await context.channel.sendMessage(
          MessageContent.custom('You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null || botState.channel == null) {
        await context.channel.sendMessage(MessageBuilder.content("I'm not connected to any voice channel"));
        return;
      }
      Node node = cluster!.getOrCreatePlayerNode(context.guild.id);
      GuildPlayer? player = node.players[guild.id];
      if (player == null) {
        await context.channel.sendMessage(MessageContent.custom('Player is empty.'));
        return;
      } else {
        if (player.queue.isEmpty) {
          await context.channel.sendMessage(MessageContent.custom('Queue is empty.'));
          return;
        } else {
          node.skip(guild.id);
        }
      }
    } else if (args[0] == 'playing' || args[0] == 'np') {
      Node node = cluster!.getOrCreatePlayerNode(context.guild.id);

      GuildPlayer? player = node.players[context.guild.id];

      if (player == null) return;

      if (player.nowPlaying == null) {
        await context.channel.sendMessage(MessageBuilder.content('Queue clear'));
        return;
      }

      await context.channel
          .sendMessage(MessageBuilder.content('Currently playing ${player.nowPlaying!.track.info?.title}'));
    }
  } catch (e) {
    await logAndSendMessage(event, MessageContent.exception(e), LogTypeTag.error, e.toString());
    return;
  }
}
