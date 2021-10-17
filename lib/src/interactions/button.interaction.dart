// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:dotenv/dotenv.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/interactions.dart';

// 🌎 Project imports:
import 'package:at_bot/src/interactions/role.interaction.dart';
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';
import 'package:nyxx_lavalink/lavalink.dart';

Future<void> buttonInteraction(ButtonInteractionEvent event, {Cluster? cluster}) async {
  try {
    Message? musicMsg;

    /// Get the interaction ID
    String id = event.interaction.customId;

    /// Get the action.
    /// EG: req for request role.
    String action = id.split('_')[0];

    /// Get the Guild ID
    Guild? guild = event.interaction.message!.client.guilds.first;

    Node node = cluster!.getOrCreatePlayerNode(guild!.id);
    EmbedBuilder embed = EmbedBuilder();
    VoiceState? userState =
        guild.voiceStates.findOne((VoiceState item) => item.user.id == event.interaction.userAuthor?.id);
    VoiceState? botState =
        guild.voiceStates.findOne((VoiceState item) => item.user.id == env['botID'].toString().toSnowflake());
    List<List<IComponentBuilder>> components = <List<IComponentBuilder>>[
      <IComponentBuilder>[
        ButtonBuilder('⏮️', 'seek', ComponentStyle.secondary),
        ButtonBuilder('▶️', 'resume', ComponentStyle.secondary),
        ButtonBuilder('⏸️', 'pause', ComponentStyle.secondary),
        ButtonBuilder('⏭️', 'skip', ComponentStyle.secondary),
      ]
    ];
    ComponentMessageBuilder messageBuilder = ComponentMessageBuilder()
      ..embeds = <EmbedBuilder>[embed]
      ..components = components;

    /// If action is role request
    if (action == 'req') {
      /// get the role ID from button ID
      String btnRoleID = id.split('_')[1];

      /// Get the role from the guild.
      Role? role = guild.roles.findOne((Role? item) => (item!.id.toString().compareTo(btnRoleID) == 0));

      /// If role ID from button ID matches with role ID
      if (btnRoleID == role!.id.toString()) {
        /// get the interacted button.
        String userInteraction = id.split('_')[2];

        /// Fetch the member from the guild.
        Member mem = await guild.fetchMember(event.interaction.userAuthor!.id);

        /// Fetch the user from the member.
        User? user = mem.user.getFromCache();

        /// User interacted message.
        Message? invitationMsg = event.interaction.message;

        /// If the interaction type is accept.
        if (userInteraction == 'accept') {
          await onRoleRequestAccept(guild, id, mem, user!, invitationMsg!, event, role);
        } else

        /// If the interaction type is reject.
        {
          /// Delete the interaction message and reply with Thanks.
          await invitationMsg!.delete().then(
                (_) async => event.interaction.message!.channel.sendMessage(
                  MessageContent.custom('Thanks for your the response.'),
                ),
              );

          /// Try getting a moderator/bots channel.
          Iterable<GuildChannel> modChannel = guild.channels.where(
            (GuildChannel channel) =>
                (channel.id.toString() == env['mod_channel_id'] || channel.id.toString() == env['bot_channel_id']),
          );

          /// Log the user interaction.
          AtBotLogger.logln(LogTypeTag.info, '${user!.username} has rejected the ${role.name} role request.');

          /// If modChannel is empty.
          if (modChannel.isEmpty) {
            AtBotLogger.logln(LogTypeTag.info, 'Cannot find a moderator channel to initmate.');
            return;
          }

          /// Notify the moderators about user interaction.
          await (modChannel.first as TextChannel).sendMessage(
            MessageContent.custom('**${user.username}** has rejected the **${role.name}** role request.'),
          );
        }
      }
    } else if (action == 'welcome') {
      try {
        String actionType = id.split('_')[1];
        if (actionType == 'accept') {
          Role? role =
              guild.roles.findOne((Role? item) => (item!.name.toString().toLowerCase().compareTo('member') == 0));

          /// Fetch the member from the guild.
          Member mem = await guild.fetchMember(event.interaction.userAuthor!.id);

          /// Fetch the user from the member.
          User? user = mem.user.getFromCache();

          /// User interacted message.
          Message? invitationMsg = event.interaction.message;
          await onRoleRequestAccept(guild, id, mem, user!, invitationMsg!, event, role);
        }
      } on Exception catch (e) {
        AtBotLogger.logln(LogTypeTag.error, e.toString());
        return;
      }
    } else if (action == 'pause') {
      if (userState == null || userState.channel == null) {
        await event.interaction.message!.channel.sendMessage(
          MessageContent.custom('You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null && botState!.channel != null) {
        await event.interaction.message!.channel
            .sendMessage(MessageBuilder.content("I'm not in any voice channel. Invite me first."));
        return;
      }
      GuildPlayer? player = node.players[guild.id];

      if (player == null) return;

      QueuedTrack? nowPlaying = player.nowPlaying;
      embedDetails(embed, nowPlaying);
      // embed.title = 'Track paused';
      // embed.description = 'Playing ${nowPlaying!.track.info?.title}'.trim();
      // embed.fields
      //   ..add(EmbedFieldBuilder('By', nowPlaying.track.info!.author))
      //   ..add(EmbedFieldBuilder('Requested by', '<@${nowPlaying.requester}>'))
      //   ..add(EmbedFieldBuilder('Duration', millisToMinutesAndSeconds(nowPlaying.track.info!.length) + ' mins'))
      //   ..add(EmbedFieldBuilder('Link', nowPlaying.track.info!.uri));
      node.pause(guild.id);
      await event.interaction.message!.edit(messageBuilder);
    } else if (action == 'resume') {
      if (userState == null || userState.channel == null) {
        await event.interaction.message!.channel.sendMessage(
          MessageContent.custom('You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null && botState!.channel != null) {
        await event.interaction.message!.channel
            .sendMessage(MessageBuilder.content("I'm not in any voice channel. Invite me first."));
        return;
      }

      GuildPlayer? player = node.players[guild.id];

      if (player == null) return;

      QueuedTrack? nowPlaying = player.nowPlaying;
      embedDetails(embed, nowPlaying);
      node.resume(guild.id);
      await event.interaction.message!.edit(messageBuilder);
    } else if (action == 'skip') {
      // EmbedBuilder skipEmbed = EmbedBuilder();
      if (userState == null || userState.channel == null) {
        await event.interaction.message!.channel.sendMessage(
          MessageContent.custom('You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null && botState!.channel != null) {
        await event.interaction.message!.channel
            .sendMessage(MessageBuilder.content("I'm not in any voice channel. Invite me first."));
        return;
      }
      GuildPlayer? player = node.players[guild.id];
      if (player == null) {
        await event.interaction.message!.channel.sendMessage(MessageContent.custom('Player is empty.'));
        return;
      } else {
        QueuedTrack? nowPlaying = player.nowPlaying;
        if (nowPlaying == null) {
          return;
        }
        // skipEmbed.title = 'Track skipped';
        // skipEmbed.description = 'Playing ${player.nowPlaying!.track.info?.title}'.trim();
        // skipEmbed.fields
        //   ..add(EmbedFieldBuilder('By', nowPlaying.track.info!.author))
        //   ..add(EmbedFieldBuilder('Requested by', '<@${nowPlaying.requester}>'))
        //   ..add(EmbedFieldBuilder('Duration', millisToMinutesAndSeconds(nowPlaying.track.info!.length) + ' mins'))
        //   ..add(EmbedFieldBuilder('Link', nowPlaying.track.info!.uri));
        // try {
        //   // await event.interaction.message!.edit(noBtns
        //   //   ..components?.clear()
        //   //   ..embeds.clear());
        //   // ..embeds = ;
        // } on Exception catch (e) {
        //   throw Exception(e.toString());
        // }

        musicMsg =
            await event.interaction.message!.channel.sendMessage(MessageContent.custom('Skipping the current track.'));
        node.skip(guild.id);
        List<QueuedTrack> queue = player.queue;
        if (queue.isEmpty) {
          await musicMsg.delete();
          await event.interaction.message!.channel.sendMessage(MessageContent.custom('Queue is empty.'));
          return;
        }
        await musicMsg.delete();
      }
    } else if (action == 'seek') {
      if (userState == null || userState.channel == null) {
        await event.interaction.message!.channel.sendMessage(
          MessageContent.custom('You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null && botState!.channel != null) {
        await event.interaction.message!.channel
            .sendMessage(MessageBuilder.content("I'm not in any voice channel. Invite me first."));
        return;
      }

      node.seek(guild.id, const Duration(seconds: 0));
    }
  } catch (e) {
    AtBotLogger.logln(LogTypeTag.error, e.toString());
    return;
  }
}

void embedDetails(EmbedBuilder embed, QueuedTrack? nowPlaying) {
  embed.title = 'Track resumed';
  embed.description = 'Playing ${nowPlaying!.track.info?.title}'.trim();
  embed.fields
    ..add(EmbedFieldBuilder('By', nowPlaying.track.info!.author))
    ..add(EmbedFieldBuilder('Requested by', '<@${nowPlaying.requester}>'))
    ..add(EmbedFieldBuilder('Duration', millisToMinutesAndSeconds(nowPlaying.track.info!.length) + ' mins'))
    ..add(EmbedFieldBuilder('Link', nowPlaying.track.info!.uri));
}

List<EmbedBuilder> musicEmbed(EmbedBuilder embed, GuildPlayer player, QueuedTrack nowPlaying) {
  return <EmbedBuilder>[
    embed
      ..title = 'Track skipped'
      ..description = 'Playing ${player.nowPlaying!.track.info?.title}'.trim()
      ..fields = <EmbedFieldBuilder>[
        EmbedFieldBuilder('By', nowPlaying.track.info!.author),
        EmbedFieldBuilder('Duration', millisToMinutesAndSeconds(nowPlaying.track.info!.length) + ' mins'),
        EmbedFieldBuilder('Requested by', '<@${nowPlaying.requester}>'),
        EmbedFieldBuilder('Link', nowPlaying.track.info!.uri),
      ]
  ];
}
