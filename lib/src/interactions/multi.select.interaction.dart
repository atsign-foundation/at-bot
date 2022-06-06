import 'package:nyxx/nyxx.dart' as nyxx;
import 'package:at_bot/src/utils/constants.util.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';

Future<void> multiSelectInteraction(IMultiselectInteractionEvent event) async {
  if (event.interaction.customId == '@signDropdown') {
    await event.acknowledge();
    String atSign = event.interaction.values.first;
    ComponentMessageBuilder emptyComponentMessageBuilder =
        ComponentMessageBuilder();
    emptyComponentMessageBuilder.componentRows?.clear();
    emptyComponentMessageBuilder.content = event.interaction.message!.content;
    await event.interaction.message!.edit(emptyComponentMessageBuilder);
    ComponentMessageBuilder confirmMsg = ComponentMessageBuilder();
    confirmMsg.addComponentRow(
      ComponentRowBuilder()
        ..addComponent(
          ButtonBuilder(
            'I like this one!',
            'confirmAtSign_$atSign',
            nyxx.ButtonStyle.success,
          ),
        ),
    );
    if (Constants.msg == null) {
      Constants.msg = await event.interaction.message!.channel
          .sendMessage(confirmMsg..content = 'You have selected `$atSign`');
    } else {
      await Constants.msg!
          .edit(confirmMsg..content = 'You have selected `$atSign`');
    }
  }
}
