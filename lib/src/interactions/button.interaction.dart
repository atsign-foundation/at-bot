// 🎯 Dart imports:
import 'dart:async';

// 🌎 Project imports:
import 'package:at_bot/src/interactions/role.interaction.dart';
// 📦 Package imports:
import 'package:at_bot/src/services/get_atsign.dart';
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart' as con;
import 'package:at_bot/src/utils/provider.util.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';
import 'package:nyxx_lavalink/nyxx_lavalink.dart';
import 'package:riverpod/riverpod.dart';

import '../utils/load_env.util.dart';

Future<void> buttonInteraction(
    IButtonInteractionEvent event, ProviderContainer container) async {
  try {
    // IMessage? musicMsg;

    /// Get the interaction ID
    String id = event.interaction.customId;

    /// Get the action.
    /// EG: req for request role.
    String action = id.split('_')[0];

    /// Get the Guild ID
    ComponentMessageBuilder componentMessageBuilder = ComponentMessageBuilder();
    if (id.contains('singleAtSign')) {
      bool isDev = id == 'singleAtSignDev';
      String atSign = await AtSignAPI.getNewAtsign(isDev);
      ComponentMessageBuilder emptyComponentMessageBuilder =
          ComponentMessageBuilder();

      ComponentRowBuilder selectedComponentRow = ComponentRowBuilder()
        ..addComponent(ButtonBuilder('Get Random @sign',
            isDev ? 'singleAtSignDev' : 'singleAtSign', ButtonStyle.primary,
            disabled: true));
      ComponentRowBuilder componentRow = ComponentRowBuilder()
        ..addComponent(
            ButtonBuilder('Change @sign', 'changeAtSign', ButtonStyle.primary))
        ..addComponent(ButtonBuilder(
            'I like this one!', 'confirmAtSign_$atSign', ButtonStyle.success));
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
        String newAtSign =
            await AtSignAPI.getNewAtsign(container.read(isDev.state).state);
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
            'Give me options', 'multiAtSigns', ButtonStyle.secondary,
            disabled: true));
      ComponentRowBuilder componentRow = ComponentRowBuilder()
        // ..addComponent(ButtonBuilder(
        //     'Change @sign', 'changeAtSign', ButtonStyle.primary))
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
              'I like this one!',
              'confirmAtSign_$selectedAtSign',
              ButtonStyle.success,
              disabled: true,
            ),
          ),
      );
      emptyComponentMessageBuilder.content =
          'Awesome, You\'ve selected `$selectedAtSign`.';
      await event.acknowledge();
      await event.interaction.message!.edit(emptyComponentMessageBuilder);
      await event.interaction.message!.channel.sendMessage(ComponentMessageBuilder()
        ..content =
            'Great! Please enter the email address you would like to assign `$selectedAtSign` to.\nMake sure you have access to this email address because we\'ll be sending you a one time password in the next step!\n`!${container.read(isDev.state).state ? 'devemail' : 'email'} <email> <@sign>` to submit mail id');
    } else if (id == 'changeAtSign') {
      String atSign =
          await AtSignAPI.getNewAtsign(container.read(isDev.state).state);
      ComponentMessageBuilder newAtSignMsgBuilder = ComponentMessageBuilder();
      newAtSignMsgBuilder.addComponentRow(ComponentRowBuilder()
        ..addComponent(
            ButtonBuilder('Change @sign', 'changeAtSign', ButtonStyle.primary))
        ..addComponent(ButtonBuilder(
            'I like this one!', 'confirmAtSign_$atSign', ButtonStyle.success)));
      await event.acknowledge();
      await event.interaction.message!.edit(
          newAtSignMsgBuilder..content = 'Awesome, We got `$atSign` for you.');
      return;
    }
    IGuild? guild = event.interaction.guild == null
        ? null
        : event.interaction.guild!.getFromCache();

    /// If action is role request
    if (action == 'req') {
      /// get the role ID from button ID
      String btnRoleID = id.split('_')[1];

      /// Get the role from the guild.
      IRole? role;
      guild?.roles.forEach((Snowflake key, IRole value) {
        if (value.id.toString().compareTo(btnRoleID) == 0) {
          role = value;
        }
      });

      /// If role ID from button ID matches with role ID
      if (btnRoleID == role!.id.toString()) {
        /// get the interacted button.
        String userInteraction = id.split('_')[2];

        /// Fetch the member from the guild.
        IMember? mem =
            await guild?.fetchMember(event.interaction.userAuthor!.id);

        /// Fetch the user from the member.
        IUser? user = mem?.user.getFromCache();

        /// User interacted message.
        IMessage? invitationMsg = event.interaction.message;

        /// If the interaction type is accept.
        if (userInteraction == 'accept') {
          await onRoleRequestAccept(
              guild!, id, mem!, user!, invitationMsg!, event, role);
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
          Iterable<IGuildChannel>? modChannel = guild?.channels.where(
            (IGuildChannel channel) =>
                (channel.id.toString() == env['mod_channel_id'] ||
                    channel.id.toString() == env['bot_channel_id']),
          );

          /// Log the user interaction.
          AtBotLogger.logln(LogTypeTag.info,
              '${user!.username} has rejected the ${role?.name} role request.');

          /// If modChannel is empty.
          if (modChannel!.isEmpty) {
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
    }
  } catch (e) {
    AtBotLogger.logln(LogTypeTag.error, e.toString());
    throw e.toString();
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
