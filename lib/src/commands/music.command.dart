// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:dotenv/dotenv.dart';
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_lavalink/nyxx_lavalink.dart';

Future<void> onMusicCommand(
    nyxx.IMessageReceivedEvent event, List<String>? args,
    {ICluster? cluster}) async {
  try {
    /// args is null or args length is not equal to 3, return.
    if (args == null || args.isEmpty) return;
    nyxx.IMessage? context = event.message;
    nyxx.IGuild? guild = context.guild?.getFromCache()!;
    nyxx.IGuildChannel? voiceChannel = guild?.channels.firstWhere(
        (nyxx.IGuildChannel? channel) =>
            channel!.id == env['music_channel_id']!.toSnowflake());
    nyxx.IVoiceState? userState;
    guild?.voiceStates.forEach((nyxx.Snowflake key, nyxx.IVoiceState value) {
      if (value.user.id == context.author.id) {
        userState = value;
      }
    });
    nyxx.IVoiceState? botState;
    guild?.voiceStates.forEach((nyxx.Snowflake key, nyxx.IVoiceState value) {
      if (value.user.id == env['botID'].toString().toSnowflake()) {
        botState = value;
      }
    });
    // If args[0] is join, then join to voice channel.
    if (args[0] == 'join') {
      try {
        if (userState == null || userState?.channel == null) {
          await context.channel.sendMessage(
            MessageContent.custom(
                'You need to be connected to a voice chat to use this command'),
          );
          return;
        }
        if (botState != null && botState!.channel != null) {
          await context.channel.sendMessage(MessageBuilder.content(
              "I'm already in <#${botState!.channel!.id}>."));
          return;
        }
        if (voiceChannel!.id.isZero || voiceChannel.name.isEmpty) {
          await context.channel.sendMessage(
            MessageContent.custom(
              'Could not find voice channel with name: ${args[1]}',
            ),
          );
          return;
        }
        cluster!.getOrCreatePlayerNode(context.guild!.id);
        (voiceChannel as IVoiceGuildChannel).connect(selfDeafen: true);
        return;
      } on ClusterException catch (_) {
        await context.channel.sendMessage(
          MessageContent.custom(
            'Could not find enough nodes to join in voice channel. Try again after a while.',
          ),
        );
        return;
      }
    } else if (args[0] == 'leave' ||
        args[0] == 'l' ||
        args[0] == 'exit' ||
        args[0] == 'e') {
      if (userState == null || userState!.channel == null) {
        await context.channel.sendMessage(
          MessageContent.custom(
              'You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null || botState!.channel == null) {
        await context.channel.sendMessage(
            MessageBuilder.content("I'm not connected to any voice channel"));
        return;
      }
      // await context.edit(messageBuilder..components!.clear());
      cluster!
          .getOrCreatePlayerNode(context.guild!.id)
          .destroy(context.guild!.id);
      (voiceChannel! as IVoiceGuildChannel).disconnect();
      await context.channel
          .sendMessage(MessageBuilder.content('Left the voice channel.'));
    } else if (args[0] == 'add') {
      if (userState == null || userState!.channel == null) {
        await context.channel.sendMessage(
          MessageContent.custom(
              'You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null || botState!.channel == null) {
        await context.channel.sendMessage(
            MessageBuilder.content("I'm not connected to any voice channel"));
        return;
      }
      args.removeRange(0, 1);
      String query = args.join(' ');
      INode node = cluster!.getOrCreatePlayerNode(context.guild!.id);
      ITracks results =
          await node.autoSearch(query, platform: SearchPlatform.soundcloud);
      if (results.tracks.isEmpty) {
        await context.channel
            .sendMessage(MessageBuilder.content('No matches with $query'));
        return;
      }
      node
          .play(
            Snowflake(context.guild!.id),
            results.tracks[0],
            channelId: context.channel.id,
            requester: event.message.author.id,
          )
          .queue();
      await context.channel.sendMessage(MessageContent.custom(
          'Added ${results.tracks[0].info!.title} to queue'));
    } else if (args[0] == 'play') {
      if (args.length < 2) {
        await context.channel
            .sendMessage(MessageContent.custom('No track provided.'));
        return;
      }
      if (userState == null || userState!.channel == null) {
        await context.channel.sendMessage(
          MessageContent.custom(
              'You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null || botState!.channel == null) {
        await context.channel.sendMessage(
            MessageBuilder.content("I'm not connected to any voice channel"));
        return;
      }
      INode node = cluster!.getOrCreatePlayerNode(context.guild!.id);
      IGuildPlayer? player = node.players[context.guild!.id];
      if (player != null) {
        List<IQueuedTrack> queue = player.queue.toList();
        if (queue.isNotEmpty) {
          await context.channel.sendMessage(MessageContent.custom(
              'Use **${env['prefix']}music add** ***YOUR SONG NAME*** to add it to the queue.'));
          return;
        }
      }
      args.removeRange(0, 1);
      String query = args.join(' ');
      ITracks results = await node.autoSearch(query);
      if (results.tracks.isEmpty) {
        await context.channel
            .sendMessage(MessageBuilder.content('No matches with $query'));
        return;
      }
      node
          .play(
            Snowflake(context.guild!.id),
            results.tracks[0],
            channelId: context.channel.id,
            requester: event.message.author.id,
          )
          .queue();
    } else if (args[0] == 'pause' || args[0] == 'p') {
      INode node = cluster!.getOrCreatePlayerNode(context.guild!.id);
      node.pause(context.guild!.id);
    } else if (args[0] == 'resume' || args[0] == 'r') {
      INode node = cluster!.getOrCreatePlayerNode(context.guild!.id);
      node.resume(context.guild!.id);
    } else if (args[0] == 'node' || args[0] == 'n') {
      await context.channel.sendMessage(MessageContent.custom(
          '${cluster!.connectedNodes.length} connected nodes'));
      return;
    } else if (args[0] == 'queue' || args[0] == 'q') {
      if (botState == null || botState!.channel == null) {
        await context.channel.sendMessage(
            MessageBuilder.content("I'm not connected to any voice channel"));
        return;
      }
      INode node = cluster!.getOrCreatePlayerNode(context.guild!.id);
      IGuildPlayer? player = node.players[context.guild!.id];
      if (player == null) return;
      List<IQueuedTrack> queue = player.queue.toList();
      if (queue.isEmpty) {
        await context.channel
            .sendMessage(MessageContent.custom('Queue is empty'));
        return;
      } else {
        List<String> queueList = <String>[];
        for (IQueuedTrack element in queue) {
          queueList.add('▶ - ' + element.track.info!.title);
        }
        await context.channel
            .sendMessage(MessageContent.custom(queueList.join('\n')));
        return;
      }
    } else if (args[0] == 'skip') {
      if (userState == null || userState!.channel == null) {
        await context.channel.sendMessage(
          MessageContent.custom(
              'You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null || botState!.channel == null) {
        await context.channel.sendMessage(
            MessageBuilder.content("I'm not connected to any voice channel"));
        return;
      }
      INode node = cluster!.getOrCreatePlayerNode(context.guild!.id);
      IGuildPlayer? player = node.players[guild!.id];
      if (player == null) {
        await context.channel
            .sendMessage(MessageContent.custom('Player is empty.'));
        return;
      } else {
        if (player.queue.isEmpty) {
          await context.channel
              .sendMessage(MessageContent.custom('Queue is empty.'));
          return;
        } else {
          node.skip(guild.id);
        }
      }
    } else if (args[0] == 'playing' || args[0] == 'np') {
      INode node = cluster!.getOrCreatePlayerNode(context.guild!.id);

      IGuildPlayer? player = node.players[context.guild!.id];

      if (player == null) return;

      if (player.nowPlaying == null) {
        await context.channel
            .sendMessage(MessageBuilder.content('Queue clear'));
        return;
      }

      await context.channel.sendMessage(MessageBuilder.content(
          'Currently playing ${player.nowPlaying!.track.info?.title}'));
    }
  } catch (e) {
    await logAndSendMessage(
        event, MessageContent.exception(e), LogTypeTag.error, e.toString());
    return;
  }
}
