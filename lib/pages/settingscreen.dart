import 'dart:convert';
import 'dart:io';

import 'package:carbcalc/util/convert.dart';
import 'package:carbcalc/util/var.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:localpkg/functions.dart';
import 'package:localpkg/widgets.dart';
import 'package:localpkg/dialogue.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool showCarbCalcConvert = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Settings"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingTitle(title: "Import/Export"),
            Setting(
              title: "Import",
              desc: "Import a JSON file as your foods data.",
              text: "",
              action: () async {
                try {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                    //allowedExtensions: ["json", "txt"],
                  );
        
                  if (result != null) {
                    File file = File(result.files.single.path!);
                    String content = await file.readAsString();
        
                    dynamic jsonData = jsonDecode(content);
                    if (jsonData is Map<String, dynamic>) {
                      if (jsonData["format"] != null) {
                        double dataFormat;
                        if (jsonData["format"] is String) {
                          dataFormat = double.tryParse(jsonData["format"]) ?? format;
                        } else {
                          dataFormat = jsonData["format"];
                        }
                        dataFormat = dataFormat.toDouble();
                        jsonData["format"] = dataFormat;
                        if (jsonData["format"] == format) {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('data', jsonEncode(jsonData));
        
                          showConstantDialogue(context, "Changes Saved", "Your data has been imported. You will need to close and reopen the app for your changes to take effect.");
                        } else {
                          if (showCarbCalcConvert) {
                            try {
                              jsonData = carbcalcconvert(jsonData, dataFormat);
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setString('data', jsonEncode(jsonData));
        
                              print('Data imported');
                              showSnackBar(context, "Data imported! Please reload the home page for it to take effect.");
                            } catch (e) {
                              showSnackBar(context, "Unsupported file type");
                            }
                          } else {
                            showSnackBar(context, "Unsupported file format");
                          }
                        }
                      } else {
                        showSnackBar(context, "Unsupported file type");
                      }
                    } else {
                      showSnackBar(context, "Unsupported file type");
                    }
                  } else {
                    print('File selection was canceled');
                  }
                } catch (e) {
                  print('An error occurred: $e');
                  showSnackBar(context, "Unsupported file type");
                }
              },
            ),
            Setting(
              title: "Export",
              desc: "Export your foods data as a JSON file.",
              text: "",
              action: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String json = jsonEncode(prefs.get("data"));
                shareTextFile(true, "CarbCalc Foods", json, "json");
              },
            ),
            AboutSettings(context: context, version: version, beta: beta, about: "CarbCalc is an application that allows you to log custom foods and use them to calculate carbs (or anything else). It was originally created to replace the Omnipod 5 custom foods feature, which is a very bare part of the app."),
            SettingTitle(title: "Reset"),
            Setting(
              title: "Reset Foods Data",
              desc: "Resets all foods data. This cannot be undone.",
              text: "",
              action: () async {
                bool? response = await showConfirmDialogue(context, "Confirm Action", "Are you sure you want to erase foods data? All modes and foods will be erased. This cannot be undone.");
                if (response != null) {
                  if (response) {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setString("data", "");
                    print("SharedPreferences.data cleared");
                    showConstantDialogue(context, "Changes Saved", "Your foods data has been reset. You will need to close and reopen the app for your changes to take effect.");
                    setState(() {});
                  }
                }
              },
            ),
            Setting(
              title: "Reset All Data",
              desc: "Resets all data and settings. This cannot be undone.",
              text: "",
              action: () async {
                bool? response = await showConfirmDialogue(context, "Confirm Action", "Are you sure you want to erase all data? This will delete your foods, modes, and settings. This cannot be undone.");
                if (response != null) {
                  if (response) {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    print("SharedPreferences cleared");
                    showConstantDialogue(context, "Changes Saved", "Your data has been reset. You will need to close and reopen the app for your changes to take effect.");
                    setState(() {});
                  }
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openUrlConf(context, Uri.parse("mailto:calebh101dev@icloud.com"));
        },
        child: Icon(FontAwesomeIcons.message),
      ),
    );
  }
}