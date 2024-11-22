import 'package:carbcalc/util/var.dart';
import 'package:carbcalc/utils/functions.dart';
import 'package:flutter/material.dart';

void showBetaWarning(context, bool overrideWarningBool) {
  if (beta && (betaWarning || overrideWarningBool)) {
    showAlertDialogue(context, "Application Warning", "This application is currently in beta. Please do not rely on this application for keeping your data. If your data becomes corrupted, please report by the Feedback icon in settings. Please include details about the error and your foods file. If possible, the data may be recoverable. If you can no longer use your data in CarbCalc, you can clear it.", false, {"show": false});
  }
}

Future<bool?> showConfirmDialogue(BuildContext context, String title) async {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Action'),
        content: Text(title),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}