// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:at_bot/src/services/get_atsign.dart';
import 'package:dotenv/dotenv.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';

// 🌎 Project imports:
import 'package:at_bot/src/interactions/role.interaction.dart';
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart' as con;
import 'package:nyxx_lavalink/nyxx_lavalink.dart';

Future<void> buttonInteraction(IButtonInteractionEvent event,
    {ICluster? cluster}) async {
  try {
    IMessage? musicMsg;

    /// Get the interaction ID
    String id = event.interaction.customId;

    /// Get the action.
    /// EG: req for request role.
    String action = id.split('_')[0];

    /// Get the Guild ID
    ComponentMessageBuilder componentMessageBuilder = ComponentMessageBuilder();
    if (id == 'singleAtSign') {
      String atSign = await AtSignAPI.getNewAtsign();
      ComponentMessageBuilder emptyComponentMessageBuilder =
          ComponentMessageBuilder();

      ComponentRowBuilder selectedComponentRow = ComponentRowBuilder()
        ..addComponent(ButtonBuilder(
            'Get Random @sign', 'singleAtSign', ComponentStyle.primary,
            disabled: true));
      ComponentRowBuilder componentRow = ComponentRowBuilder()
        ..addComponent(ButtonBuilder(
            'Change @sign', 'changeAtSign', ComponentStyle.primary))
        ..addComponent(ButtonBuilder(
            'Confirm', 'confirmAtSign_$atSign', ComponentStyle.success));
      componentMessageBuilder.addComponentRow(componentRow);
      emptyComponentMessageBuilder.componentRows?.clear();
      emptyComponentMessageBuilder.addComponentRow(selectedComponentRow);
      emptyComponentMessageBuilder.content = event.interaction.message!.content;
      await event.acknowledge();
      await event.interaction.message!.edit(emptyComponentMessageBuilder);
      await event.interaction.message!.channel.sendMessage(
          componentMessageBuilder
            ..content = 'Awesome, We got `$atSign` for you.');
      return;
    } else if (id == 'multiAtSigns') {
      List<String> atSigns = <String>[];
      // generate atsigns 3 times and add atSigns to list
      for (int i = 0; atSigns.length < 3; i++) {
        String newAtSign = await AtSignAPI.getNewAtsign();
        if (!atSigns.contains(newAtSign)) {
          atSigns.add(newAtSign);
        } else if (atSigns.length == 3) {
          break;
        }
      }
      ComponentMessageBuilder emptyComponentMessageBuilder =
          ComponentMessageBuilder();

      ComponentRowBuilder selectedComponentRow = ComponentRowBuilder()
        ..addComponent(ButtonBuilder(
            'Give me options', 'multiAtSigns', ComponentStyle.secondary,
            disabled: true));
      ComponentRowBuilder componentRow = ComponentRowBuilder()
        // ..addComponent(ButtonBuilder(
        //     'Change @sign', 'changeAtSign', ComponentStyle.primary))
        ..addComponent(
          MultiselectBuilder(
            '@signDropdown',
            <MultiselectOptionBuilder>[
              // for the first value set isDefault to true
              ...atSigns.map(
                (String atSign) => MultiselectOptionBuilder(
                  atSign,
                  atSign,
                ),
              ),
            ],
          )..placeholder = 'Select @sign',
        );
      con.Constants.msg = null;
      componentMessageBuilder.addComponentRow(componentRow);
      emptyComponentMessageBuilder.componentRows?.clear();
      emptyComponentMessageBuilder.addComponentRow(selectedComponentRow);
      emptyComponentMessageBuilder.content = event.interaction.message!.content;
      await event.acknowledge();
      await event.interaction.message!.edit(emptyComponentMessageBuilder);
      await event.respond(componentMessageBuilder
        ..content = 'Awesome, We got some @signs for you.');
      return;
    } else if (id.split('_')[0] == 'confirmAtSign') {
      String selectedAtSign = id.split('_')[1];
      ComponentMessageBuilder emptyComponentMessageBuilder =
          ComponentMessageBuilder();
      // emptyComponentMessageBuilder.componentRows?.clear();
      emptyComponentMessageBuilder.addComponentRow(
        ComponentRowBuilder()
          ..addComponent(
            ButtonBuilder(
              'Confirm',
              'confirmAtSign',
              ComponentStyle.success,
              disabled: true,
            ),
          ),
      );
      emptyComponentMessageBuilder.content =
          'Thanks for choosing `$selectedAtSign`';
      await event.acknowledge();
      await event.interaction.message!.edit(emptyComponentMessageBuilder);
      await event.interaction.message!.channel.sendMessage(ComponentMessageBuilder()
        ..content =
            'Please enter your email to activate `$selectedAtSign`.\n**NOTE :** Use `!email YOUR_MAIL YOUR_@SIGN` to submit mail id.\nWe don\'t save any of your data.');
    } else if (id == 'changeAtSign') {
      String atSign = await AtSignAPI.getNewAtsign();
      await event.acknowledge();
      await event.interaction.message!.edit(
          con.MessageContent.custom('Awesome, We got `$atSign` for you.'));
      return;
    }
    IGuild? guild = event.interaction.guild == null
        ? null
        : event.interaction.guild!.getFromCache();

    INode node = cluster!.getOrCreatePlayerNode(guild!.id);
    EmbedBuilder embed = EmbedBuilder();
    IVoiceState? userState;
    guild.voiceStates.forEach((Snowflake key, IVoiceState value) {
      if (value.user.id == event.interaction.memberAuthor?.id) {
        userState = value;
      }
    });
    IVoiceState? botState;
    guild.voiceStates.forEach((Snowflake key, IVoiceState value) {
      if (value.user.id == guild.selfMember.id) {
        botState = value;
      }
    });
    List<List<ButtonBuilder>> components = <List<ButtonBuilder>>[
      <ButtonBuilder>[
        ButtonBuilder('⏮', 'seek', ComponentStyle.secondary),
        ButtonBuilder('▶', 'resume', ComponentStyle.secondary),
        ButtonBuilder('⏸', 'pause', ComponentStyle.secondary),
        ButtonBuilder('⏭', 'skip', ComponentStyle.secondary),
      ]
    ];
    ComponentMessageBuilder messageBuilder = ComponentMessageBuilder()
      ..embeds = <EmbedBuilder>[embed]
      ..componentRows = components;

    /// If action is role request
    if (action == 'req') {
      /// get the role ID from button ID
      String btnRoleID = id.split('_')[1];

      /// Get the role from the guild.
      IRole? role;
      guild.roles.forEach((Snowflake key, IRole value) {
        if (value.id.toString().compareTo(btnRoleID) == 0) {
          role = value;
        }
      });

      /// If role ID from button ID matches with role ID
      if (btnRoleID == role!.id.toString()) {
        /// get the interacted button.
        String userInteraction = id.split('_')[2];

        /// Fetch the member from the guild.
        IMember mem = await guild.fetchMember(event.interaction.userAuthor!.id);

        /// Fetch the user from the member.
        IUser? user = mem.user.getFromCache();

        /// User interacted message.
        IMessage? invitationMsg = event.interaction.message;

        /// If the interaction type is accept.
        if (userInteraction == 'accept') {
          await onRoleRequestAccept(
              guild, id, mem, user!, invitationMsg!, event, role);
        } else

        /// If the interaction type is reject.
        {
          /// Delete the interaction message and reply with Thanks.
          await invitationMsg!.delete().then(
                (_) async => event.interaction.message!.channel.sendMessage(
                  con.MessageContent.custom('Thanks for your the response.'),
                ),
              );

          /// Try getting a moderator/bots channel.
          Iterable<IGuildChannel> modChannel = guild.channels.where(
            (IGuildChannel channel) =>
                (channel.id.toString() == env['mod_channel_id'] ||
                    channel.id.toString() == env['bot_channel_id']),
          );

          /// Log the user interaction.
          AtBotLogger.logln(LogTypeTag.info,
              '${user!.username} has rejected the ${role?.name} role request.');

          /// If modChannel is empty.
          if (modChannel.isEmpty) {
            AtBotLogger.logln(LogTypeTag.info,
                'Cannot find a moderator channel to initmate.');
            return;
          }

          /// Notify the moderators about user interaction.
          await (modChannel.first as ITextChannel).sendMessage(
            con.MessageContent.custom(
                '**${user.username}** has rejected the **${role?.name}** role request.'),
          );
        }
      }
    } else if (action == 'welcome') {
      try {
        String actionType = id.split('_')[1];
        if (actionType == 'accept') {
          IRole? role;
          guild.roles.forEach((Snowflake key, IRole value) {
            if (value.name.toString().toLowerCase().compareTo('member') == 0) {
              role = value;
            }
          });

          /// Fetch the member from the guild.
          IMember mem =
              await guild.fetchMember(event.interaction.userAuthor!.id);

          /// Fetch the user from the member.
          IUser? user = mem.user.getFromCache();

          /// User interacted message.
          IMessage? invitationMsg = event.interaction.message;
          await onRoleRequestAccept(
              guild, id, mem, user!, invitationMsg!, event, role);
        }
      } on Exception catch (e) {
        AtBotLogger.logln(LogTypeTag.error, e.toString());
        return;
      }
    } else if (action == 'pause') {
      if (userState == null || userState?.channel == null) {
        await event.interaction.message!.channel.sendMessage(
          con.MessageContent.custom(
              'You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null && botState!.channel != null) {
        await event.interaction.message!.channel.sendMessage(
            MessageBuilder.content(
                "I'm not in any voice channel. Invite me first."));
        return;
      }
      IGuildPlayer? player = node.players[guild.id];

      if (player == null) return;

      IQueuedTrack? nowPlaying = player.nowPlaying;
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
      if (userState == null || userState?.channel == null) {
        await event.interaction.message!.channel.sendMessage(
          con.MessageContent.custom(
              'You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null && botState!.channel != null) {
        await event.interaction.message!.channel.sendMessage(
            MessageBuilder.content(
                "I'm not in any voice channel. Invite me first."));
        return;
      }

      IGuildPlayer? player = node.players[guild.id];

      if (player == null) return;

      IQueuedTrack? nowPlaying = player.nowPlaying;
      embedDetails(embed, nowPlaying);
      node.resume(guild.id);
      await event.interaction.message!.edit(messageBuilder);
    } else if (action == 'skip') {
      // EmbedBuilder skipEmbed = EmbedBuilder();
      if (userState == null || userState?.channel == null) {
        await event.interaction.message!.channel.sendMessage(
          con.MessageContent.custom(
              'You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null && botState!.channel != null) {
        await event.interaction.message!.channel.sendMessage(
            MessageBuilder.content(
                "I'm not in any voice channel. Invite me first."));
        return;
      }
      IGuildPlayer? player = node.players[guild.id];
      if (player == null) {
        await event.interaction.message!.channel
            .sendMessage(con.MessageContent.custom('Player is empty.'));
        return;
      } else {
        IQueuedTrack? nowPlaying = player.nowPlaying;
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

        musicMsg = await event.interaction.message!.channel.sendMessage(
            con.MessageContent.custom('Skipping the current track.'));
        node.skip(guild.id);
        List<IQueuedTrack> queue = player.queue;
        if (queue.isEmpty) {
          await musicMsg.delete();
          await event.interaction.message!.channel
              .sendMessage(con.MessageContent.custom('Queue is empty.'));
          return;
        }
        await musicMsg.delete();
      }
    } else if (action == 'seek') {
      if (userState == null || userState?.channel == null) {
        await event.interaction.message!.channel.sendMessage(
          con.MessageContent.custom(
              'You need to be connected to a voice chat to use this command'),
        );
        return;
      }
      if (botState == null && botState!.channel != null) {
        await event.interaction.message!.channel.sendMessage(
            MessageBuilder.content(
                "I'm not in any voice channel. Invite me first."));
        return;
      }

      node.seek(guild.id, const Duration(seconds: 0));
    }
  } catch (e) {
    AtBotLogger.logln(LogTypeTag.error, e.toString());
    return;
  }
}

void embedDetails(EmbedBuilder embed, IQueuedTrack? nowPlaying) {
  embed.title = 'Track resumed';
  embed.description = 'Playing ${nowPlaying!.track.info?.title}'.trim();
  embed.fields
    ..add(EmbedFieldBuilder('By', nowPlaying.track.info!.author))
    ..add(EmbedFieldBuilder('Requested by', '<@${nowPlaying.requester}>'))
    ..add(EmbedFieldBuilder('Duration',
        con.millisToMinutesAndSeconds(nowPlaying.track.info!.length) + ' mins'))
    ..add(EmbedFieldBuilder('Link', nowPlaying.track.info!.uri));
}

List<EmbedBuilder> musicEmbed(
    EmbedBuilder embed, IGuildPlayer player, IQueuedTrack nowPlaying) {
  return <EmbedBuilder>[
    embed
      ..title = 'Track skipped'
      ..description = 'Playing ${player.nowPlaying!.track.info?.title}'.trim()
      ..fields = <EmbedFieldBuilder>[
        EmbedFieldBuilder('By', nowPlaying.track.info!.author),
        EmbedFieldBuilder(
            'Duration',
            con.millisToMinutesAndSeconds(nowPlaying.track.info!.length) +
                ' mins'),
        EmbedFieldBuilder('Requested by', '<@${nowPlaying.requester}>'),
        EmbedFieldBuilder('Link', nowPlaying.track.info!.uri),
      ]
  ];
}
