import 'package:carbcalc/util/var.dart';
import 'package:personal/dialogue.dart';

void showBetaWarning(context, bool overrideWarningBool) {
  if (beta && (betaWarning || overrideWarningBool)) {
    showAlertDialogue(context, "Application Warning", "This application is currently in beta. Please do not rely on this application for keeping your data. If your data becomes corrupted, please report by the Feedback icon in settings. Please include details about the error and your foods file. If possible, the data may be recoverable. If you can no longer use your data in CarbCalc, you can clear it.", false, {"show": false});
  }
}