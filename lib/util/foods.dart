import 'dart:convert';

import 'package:carbcalc/util/convert.dart';
import 'package:carbcalc/util/func.dart';
import 'package:carbcalc/util/var.dart';
import 'package:carbcalc/utils/functions.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodsWidget extends StatefulWidget {
  final String title;

  const FoodsWidget({
    super.key,
    required this.title
  });

  @override
  State<FoodsWidget> createState() => _FoodsWidgetState();
}

class _FoodsWidgetState extends State<FoodsWidget> {
  Map<String, dynamic> defaultData = {
    "defaultMode": "mode",
    "items": {
      "mode": {
        "items": [
          {
            "name": "a food",
            "value": 1,
            "icon": "fast food"
          },
          {
            "name": "c food 2",
            "value": 5,
            "icon": "chocolate"
          },
          {
            "name": "b food 3",
            "value": 4,
            "icon": "fast food"
          }
        ],
      },
      "mode 2": {
        "items": [
          {
            "name": "c food 3",
            "value": 3,
            "icon": "pizza"
          },
          {
            "name": "d food 4",
            "value": 4,
            "icon": "fast food"
          }
        ],
      },
    },
  };

  List units = [
    {
      "name": "carbohydrates",
      "init": "carbs",
      "unit": "grams",
      "abbr": "g",
    },
    {
      "name": "protein",
      "init": "protein",
      "unit": "grams",
      "abbr": "g",
    },
    {
      "name": "sodium",
      "init": "sodium",
      "unit": "milligrams",
      "abbr": "mg",
    },
  ];

  // initialize json storage
  Future<Map<String, dynamic>>? cache;
  Map<String, double> counters = {};

  // initialize booleans
  bool allowReorder = true;
  bool allowCustomReorder = true;
  bool alwaysSave = true;
  bool selected = true;
  bool cached = false;
  bool allowCache = false;
  bool isDataReady = false;

  // initialize strings and numbers
  String key = "mode";
  String? sortMode = "custom";
  double extraAmount = 0;
  int mode = 1;
  
  // initialize uninitialized variables (what?)
  late List<String> keys;

  // initializing text controllers
  final TextEditingController _extraController = TextEditingController();

  // initialize lists
  List allowedIcons = [
    "unknown",
    "fast food",
    "pizza",
  ];

  @override
  void initState() {
    print("FOODS.DART");
    init();
    super.initState();
  }

  IconData? getIcon(String? icon, bool selected) {
    if (icon == null) {
      return null;
    }

    switch (icon) {
      case "unknown":
        return selected ? Icons.question_mark : Icons.question_mark_outlined;
      case "fast food":
        return selected ? Icons.fastfood : Icons.fastfood_outlined;
      case "pizza":
        return selected ? Icons.local_pizza : Icons.local_pizza_outlined;
      default:
        return selected ? Icons.question_mark : Icons.question_mark_outlined;
    }
  }

  void saveSortedList(List list, String mode, data) {
    data["items"][key]["items"] = list;
    data["items"][key]["sortMode"] = mode;
  }

  Future<bool> init() async {
    print("foods.dart version 1.0.0");
    var response = await getData();
    reloadData(1, response);
    reloadForMode(response);
    refresh(1, response);
    showBetaWarning(context, false);
    return true;
  }

  void refresh(int mode, data) async {
    print("Refreshing for mode $mode...");
    if (data["format"] == null) {
      data["format"] = format;
    }
    if (data["format"] != format) {
      data = carbcalcconvert(data, data["format"].toDouble());
    }
    if (mode == 1) {
      await saveData(data);
    }
    setState(() {});
  }

  void reloadData(int mode, data) {
    if (mode == 1) {
      keys = data["items"].keys.toList();
      key = data["defaultMode"] ?? keys[0];
      sortMode = data["items"][key]["sort"] ?? "custom";
    } else if (mode == 2) {
      keys = data["items"].keys.toList();
    }
  }

  void reloadForMode(data) {
    counters = {};
    for (int i = 0; i < data["items"][key]["items"].length; i++) {
      counters[data["items"][key]["items"][i]["name"]] = 0;
    }
  }

  Future<void> saveData(data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("data", jsonEncode(data));
  }

  Future<Map<String, dynamic>> getData() async {
    if (!cached || cache == null || !allowCache) {
      print("Not cached or disabled cache: loading");
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString("data");
      if (jsonString != null && isValidJson(jsonString) && prefs.containsKey("data")) {
        print("Loaded jsonString into data");
        cache = Future.value(jsonDecode(jsonString));
        cached = true;
        return jsonDecode(jsonString);
      } else {
        prefs.setString("data", defaultData.toString());
        print("No valid data found in SharedPreferences");
        print("Running checks on jsonString...");
        if (jsonString == null) {
          print("isNull: true");
          print("Checks terminated: jsonData is null");
        } else {
          print("isValidJson: ${isValidJson(jsonString)}");
        }
      }
      return defaultData;
    } else {
      print("Cached: fetching");
      return cache!;
    }
  }

  bool isValidJson(String str) {
    try {
      json.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> sortList(String mode, data) {
    List sortedItems = jsonDecode(jsonEncode(data["items"][key]["items"])) as List;

    switch(mode) {
      case "custom":
        sortedItems = data["items"][key]["items"];
      case "alphabetical (a to z)":
        sortedItems = List<Map<String, dynamic>>.from(data["items"][key]["items"] as List<dynamic>)..sort((a, b) {
          return (a['name'] as String).compareTo(b['name'] as String);
        });
      case "alphabetical (z to a)":
        sortedItems = List<Map<String, dynamic>>.from(data["items"][key]["items"] as List<dynamic>)..sort((a, b) {
          return (b['name'] as String).compareTo(a['name'] as String);
        });
      case "value (highest to lowest)":
        sortedItems = List<Map<String, dynamic>>.from(data["items"][key]["items"] as List<dynamic>)..sort((a, b) {
          return (b['value'] as num).compareTo(a['value'] as num);
        });
      case "value (lowest to highest)":
        sortedItems = List<Map<String, dynamic>>.from(data["items"][key]["items"] as List<dynamic>)..sort((a, b) {
          return (a['value'] as num).compareTo(b['value'] as num);
        });
      default:
        sortedItems = data["items"][key]["items"];
    }

    print("sort: $mode");
    print(sortedItems);
    saveSortedList(sortedItems, mode, data);
    return data;
  }

  double calculateTotal(data) {
    List<String> counterKeys = counters.keys.toList();
    double total = 0;

    for (int i = 0; i < counterKeys.length; i++) {
      double value = data["items"][key]["items"][i]["value"].toDouble();
      double amount = counters[counterKeys[i]]!;
      total = total + (value * amount);
    }

    total = total + extraAmount;
    return total;
  }

  bool validateNumber(double number) {
    if (number >= 0 && number.toString().length <= 8) {
      return true;
    } else {
      return false;
    }
  }

  bool validateText(String text) {
    RegExp invalidChars = RegExp(r'[\"\\]');
    return text.length <= 16 && !invalidChars.hasMatch(text);
  }

  Object formatDouble(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value;
    }
  }

  Future<void> selectMode(BuildContext context, data) async {
    final selectedOption = await _showSelectionDialog(context, keys, "mode");
    if (selectedOption != null) {
      changeMode(selectedOption, data);
    }
  }

  void changeMode(String mode, data) async {
    data["defaultMode"] = mode;
    key = mode;
    await saveData(data);
    print(data);
    reloadData(2, data);
    reloadForMode(data);
    refresh(1, data);
  }

  Future<String?> _showSelectionDialog(BuildContext context, List array, String title) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text("Select a $title..."),
          children: array.map((option) {
            print("option(lowercase), sortMode: ${option.toLowerCase()}, $sortMode");
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, option);
              },
              child: Row(
                children: [
                  if (option.toLowerCase() == sortMode) 
                    Icon(
                      Icons.check
                    ),
                  SizedBox(width: 8),
                  Text(option),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<String?> showAddDialogue(BuildContext context) async {
    List array = [
      "Item",
      "Mode"
    ];

    String title = "new item to add"; // This is because I copied _showSelectionDialogue and I was too lazy to change the text lol

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text("Select a $title..."),
          children: array.map((option) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, option);
              },
              child: Row(
                children: [
                  if (option == sortMode) 
                    Icon(
                      Icons.check
                    ),
                  SizedBox(width: 8),
                  Text(option),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Future<String> showTextInput(String title) async {
    String inputText = '';
    String userInput = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter a new ${title.toLowerCase()}...'),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            decoration: InputDecoration(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                setState(() {
                  userInput = inputText;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return userInput;
  }

  Future<double?> _showNumberInputDialog(BuildContext context, double defaultAmount) async {
    TextEditingController numberController = TextEditingController(text: formatDouble(defaultAmount).toString());

    return showDialog<double?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Input a value'),
          content: TextField(
            controller: numberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: 'Enter a number'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                String input = numberController.text;
                double? number = double.tryParse(input);
                Navigator.of(context).pop(number);
              },
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  bool allowReorderHandles() {
    return mode == 1 ? false : mode == 2 && sortMode == "custom" && allowCustomReorder ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: (!cached) ? getData() : cache,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else {
          Map defaultUnit = units[0];
          Map unit;
          var foods;

          if (snapshot.data != null) {
            print("data: using set");
            foods = snapshot.data;
            if (foods["items"][key]["unit"] == null) {
              print("setting unit");
              foods["items"][key]["unit"] = defaultUnit;
            }
            unit = foods["items"][key]["unit"];
          } else {
            print("no data: using default");
            foods = defaultData;
            unit = defaultUnit;
          }

          print("unit: $unit");

          return Scaffold(
            appBar: AppBar(
              leading: Tooltip(
                message: "Switch mode",
                child: IconButton(
                  onPressed: () {
                    selectMode(context, foods);
                  },
                  icon: Icon(
                    Icons.menu
                  )
                ),
              ),
              actions: [
                Tooltip(
                  message: "Show options",
                  child: PopupMenuButton(
                    icon: Icon(Icons.more_vert),
                    onSelected: (String value) async {
                      if (value == 'blank') {
                        print("blank action called");
                      } else if (value == 'refresh') {
                        refresh(1, await getData());
                      } else if (value == 'edit') {
                        mode = mode == 1 ? 2 : 1;
                        refresh(1, foods);
                      } else if (value == 'add') {
                        String? response = await showAddDialogue(context);
                        Map? response2;
                  
                        if (response != null) {
                          if (response == 'Mode') {
                            response2 = {"name": await showTextInput(response)};
                          } else if (response == 'Item') {
                            response2 = await editItem({"name": "", "value": 0, "icon": ""}, 2);
                          }
                        }
                        if (response2 == "error") {
                          print("Error occurred with response2: unknown");
                          showAlertDialogue(context, "Error", "There was an error with your response.", false, {"show": false});
                        }
                        if (response2 == "invalid") {
                          print("Error occurred with response2: invalid");
                          showAlertDialogue(context, "Error", "Your response was invalid.", false, {"show": false});
                        }
                        if (response != null && (response2 != null && response2["name"] != '')) {
                          setState(() {
                            switch(response) {
                              case "Item":
                                print("Item added: $response2");
                                foods["items"][key]["items"].add(response2);
                                saveData(foods);
                              case "Mode":
                                print("Mode added: $response2");
                                foods["items"][response2!["name"]] = {"items":[{"name": "My First Food", "value": 0, "icon": "fast food"}]};
                                changeMode(response2["name"]!, foods);
                                saveData(foods);
                              default:
                                print("Unable to judge dialogue choice: $response");
                                showAlertDialogue(context, "Error", "Unable to judge your chosen item.", false, {"show": false});
                            }
                          });
                        }
                      } else if (value == 'sort') {
                        List sortOptions = ["Alphabetical (A to Z)", "Alphabetical (Z to A)", "Value (lowest to highest)", "Value (highest to lowest)"];
                        if (allowCustomReorder) {
                          sortOptions.add("Custom");
                        }
                  
                        sortMode = await _showSelectionDialog(context, sortOptions, "sorting option");
                  
                        if (sortMode != null) {
                          sortMode = sortMode!.toLowerCase();
                        } else {
                          sortMode = "custom";
                        }
                  
                        setState(() {
                          print("sort: $sortMode");
                          refresh(1, sortList(sortMode!, foods));
                        });
                      } else if (value == 'calculate') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CalculationsPage(data: foods, counters: counters, keyS: key, extraAmount: extraAmount, unit: unit)),
                        );
                      } else if (value == 'modeChange') {
                        selectMode(context, foods);
                      } else if (value == 'modeEdit') {
                        foods = await editMode(foods, true);
                        print(foods);
                        refresh(1, foods);
                        init();
                      } else {
                        print("Unresolved condition: PopupMenuButton(value): $value");
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem(
                        value: "add",
                        child: Row(
                          children: [
                            Icon(
                              Icons.add,
                            ),
                            SizedBox(width: 6),
                            Text("Add"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(
                              mode == 1 ? Icons.edit : Icons.calculate,
                            ),
                            SizedBox(width: 6),
                            Text(
                              mode == 1 ? "Edit" : "Calculate",
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "sort",
                        child: Row(
                          children: [
                            Icon(
                              Icons.swap_vert,
                            ),
                            SizedBox(width: 6),
                            Text("Sort"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "modeChange",
                        child: Row(
                          children: [
                            Icon(
                              Icons.multiple_stop,
                            ),
                            SizedBox(width: 6),
                            Text("Change Mode"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "modeEdit",
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                            ),
                            SizedBox(width: 6),
                            Text("Edit Mode"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "refresh",
                        child: Row(
                          children: [
                            Icon(
                              Icons.refresh,
                            ),
                            SizedBox(width: 6),
                            Text("Refresh")
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "calculate",
                        child: Row(
                          children: [
                            Icon(
                              Icons.calculate_outlined,
                            ),
                            SizedBox(width: 6),
                            Text("Calculations"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "blank",
                        child: Row(
                          children: [
                            Icon(
                              Icons.close,
                            ),
                            SizedBox(width: 6),
                            Text("Close"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              title: Text("${widget.title} - $key"),
              centerTitle: true
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: allowReorderHandles(),
                        itemCount: foods["items"][key]["items"].length,
                        itemBuilder: (context, index) {
                          String itemName = foods["items"][key]["items"][index]["name"];
                          double itemValue = foods["items"][key]["items"][index]["value"].toDouble();
                          return ListTile(
                            key: ValueKey(itemName),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  counters[itemName] != 0 && mode == 1 ? IconButton(
                                      icon: Icon(Icons.check_box_outlined),
                                      iconSize: 25,
                                      onPressed: () {
                                        setState(() {
                                          counters[itemName] = 0;
                                        });
                                      }
                                    )
                                  : mode == 1 ? IconButton(
                                      icon: Icon(Icons.check_box_outline_blank),
                                      iconSize: 25,
                                      onPressed: () {
                                        setState(() {
                                          counters[itemName] = 1;
                                        });
                                      }
                                    )
                                  : SizedBox.shrink(),
                                SizedBox(width: 8),
                                Icon(getIcon(foods["items"][key]["items"][index]["icon"], false)),
                              ],
                            ),
                            title: Text(itemName),
                            subtitle: Text('Amount: ${formatDouble(itemValue).toString()}${unit["abbr"]}'),
                            trailing: mode == 1
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              if (validateNumber(counters[itemName]! + 1)) {
                                                counters[itemName] = (counters[itemName]! + 1);
                                              }
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.all(8),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            size: 25
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () async {
                                          var response = await _showNumberInputDialog(context, counters[itemName]!);
                                          setState(() {
                                            if (response != null && validateNumber(response)) {
                                              counters[itemName] = response;
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                          ),
                                          child: Text(
                                            (() {
                                              if (counters[itemName] == null) {
                                                counters[itemName] = 0;
                                              }
                                              return formatDouble(counters[itemName]!).toString();
                                            })(),
                                            style: TextStyle(fontSize: 20.0),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              if (validateNumber(counters[itemName]! - 1)) {
                                                counters[itemName] = counters[itemName]! - 1;
                                              } else {
                                                counters[itemName] = 0;
                                              }
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            fixedSize: Size(20, 20),
                                            padding: EdgeInsets.all(8),
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 25
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                : mode == 2
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                foods["items"][key]["items"][index] = await editItem(foods["items"][key]["items"][index], 1);
                                                refresh(1, foods);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                fixedSize: Size(20, 20),
                                                padding: EdgeInsets.all(8)
                                              ),
                                              child: Icon(
                                                Icons.edit,
                                                size: 25,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  counters.remove(foods["items"][key]["items"][index]["name"]);
                                                  foods["items"][key]["items"].removeAt(index);
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                fixedSize: Size(20, 20),
                                                padding: EdgeInsets.all(8)
                                              ),
                                              child: Icon(
                                                Icons.delete,
                                                size: 25,
                                                color: Colors.redAccent
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: allowReorderHandles() ? 16 : 0)
                                        ],
                                      )
                                    : null,
                          );
                        },
                        onReorder: (int oldIndex, int newIndex) {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = foods["items"][key]["items"].removeAt(oldIndex);
                          foods["items"][key]["items"].insert(newIndex, item);
                          refresh(1, foods);
                        },
                      ),
                    ),
                    mode == 1
                    ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 12),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 22
                                  ),
                                  SizedBox(width: 6.0),
                                  Text(
                                    "Extra:",
                                    style: TextStyle(
                                      fontSize: 20
                                    )
                                  ),
                                  Spacer(),
                                  Expanded(
                                    child: TextField(
                                      controller: _extraController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Extra ${unit["init"]}...',
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          double parsedValue = double.tryParse(_extraController.text) ?? 0;
                                          extraAmount = validateNumber(parsedValue) ? parsedValue : 0;
                                        });
                                      },
                                    )
                                  )
                                ]
                              )
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 0, right: 0, top: 10, bottom: 0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 22
                                  ),
                                  SizedBox(width: 6.0),
                                  Text(
                                    "Total:",
                                    style: TextStyle(
                                      fontSize: 20
                                    )
                                  ),
                                  Spacer(),
                                  Text(
                                    "${formatDouble(calculateTotal(foods))}${unit["abbr"]}",
                                    style: TextStyle(
                                      fontSize: 20
                                    )
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                    : Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 18),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 0, right: 0, top: 10, bottom: 0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 22
                                  ),
                                  SizedBox(width: 6.0),
                                  Text(
                                    "Total:",
                                    style: TextStyle(
                                      fontSize: 20
                                    )
                                  ),
                                  Spacer(),
                                  Text(
                                    "${(foods["items"][key]["items"].length).toString()} items",
                                    style: TextStyle(
                                      fontSize: 20
                                    )
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ]
            ),
          );
        }
      },
    );
  }

  Future<Map> editItem(food, int mode) async {
    print("edit food: initializing");

    final TextEditingController stringController = TextEditingController(text: food["name"]);
    final TextEditingController numberController = TextEditingController(text: formatDouble(food["value"].toDouble()).toString());

    String? selectedOption = allowedIcons.contains((food["icon"] ?? "unknown")) ? food["icon"] : "unknown";
    bool useValues = false;

    print("edit food: starting");

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${mode == 1 ? "Edit" : "Add"} Food'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: stringController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: numberController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Object>(
                    value: selectedOption,
                    items: allowedIcons
                      .map((option) => DropdownMenuItem(
                        value: option,
                        child: Row(
                          children: [
                            Icon(
                              getIcon(option, false),
                            ),
                            SizedBox(width: 6),
                            Text(
                              option == 'unknown' ? "Other" : toTitleCase(option),
                            ),
                          ],
                        ),
                      )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value.toString();
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Icon'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                useValues = false;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                useValues = true;
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (useValues) {
      print("edit food: using values");

      String name = stringController.text == '' ? food["name"] : stringController.text;
      String icon = selectedOption ?? food["icon"] ?? "unknown";
      double? inputNumber = double.tryParse(numberController.text);
      double value = (inputNumber != null && validateNumber(inputNumber)) 
        ? inputNumber 
        : food["value"];

      food["name"] = name;
      food["value"] = value;
      food["icon"] = icon;
    } else {
      print("edit food: not using values");
    }

    print("edit food: complete");
    return food;
  }

  Future<Map> editMode(Map foods, bool deleteButton) async {
    print("edit mode: initializing");

    final TextEditingController stringController = TextEditingController(text: key);

    bool useValues = false;
    bool delete = false;
    Map selectedOption = foods["items"][key]["unit"] ?? units[0];

    selectedOption = units.firstWhere(
      (unit) => unit['name'] == foods["items"][key]["unit"]['name'],
      orElse: () => units[0],
    );

    print("Selected Option: $selectedOption");
    print("Dropdown Items: ${units.map((u) => u.toString()).toList()}");
    print("edit mode: starting");

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Mode'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: stringController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Object>(
                    value: selectedOption,
                    items: units.map((option) => DropdownMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          Text(
                            "${option['name']} - ${option["unit"]}",
                          ),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value as Map;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ],
              );
            },
          ),
          actions: [
            deleteButton ? TextButton(
              onPressed: () {
                useValues = false;
                delete = true;
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ) : SizedBox.shrink(),
            TextButton(
              onPressed: () {
                useValues = false;
                delete = false;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                useValues = true;
                delete = false;
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (useValues) {
      print("edit mode: using values");
      String name = stringController.text == '' ? key : stringController.text;
      Map unitS = selectedOption;

      if (foods["items"].containsKey(key) && key != name) {
        Map<String, dynamic> map = foods["items"];
        Map<String, dynamic> updatedMap = {};

        if (map.containsKey(key) && name != key) {
          map.forEach((keyS, value) {
            if (keyS == key) {
              updatedMap[name] = value;
            } else {
              updatedMap[keyS] = value;
            }
          });

          foods["items"] = updatedMap;
          foods["defaultMode"] = name;
          key = name;
          keys = foods.keys.toList() as List<String>;
        }
      } else {
        print("edit mode: not replacing key");
      }

      print("edit mode: saving unit: $unitS");
      foods["items"][name]["unit"] = unitS;
    } else {
      print("edit mode: not using values");
    }

    if (delete) {
      print("edit mode: deleting values by conf");
      bool? response = await showConfirmDialogue(context, "Are you sure you want to delete the mode $key? All the foods in it will be deleted. This cannot be undone.");
      if (response != null) {
        if (response) {
          foods["items"].remove(key);
          if (foods["defaultMode"] == key) {
            key = foods["items"].keys.first;
          }
          changeMode(foods["items"].keys.first, foods);
        }
      }
    } else {
      print("edit mode: not deleting values");
    }

    print("edit mode: complete");
    return foods;
  }

  String toTitleCase(String input) {
    if (input.isEmpty) return input;

    return input
      .split(' ')
      .map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
        : word)
      .join(' ');
  }
}

class CalculationsPage extends StatefulWidget {
  final dynamic data;
  final dynamic counters;
  final dynamic keyS;
  final dynamic extraAmount;
  final dynamic unit;

  const CalculationsPage({
    super.key,
    required this.data,
    required this.counters,
    required this.keyS,
    required this.extraAmount,
    required this.unit,
  });

  @override
  State<CalculationsPage> createState() => _CalculationsPageState();
}

class _CalculationsPageState extends State<CalculationsPage> {
  double calculateTotal(int mode) {
    List<String> counterKeys = widget.counters.keys.toList();
    double total = 0;

    for (int i = 0; i < counterKeys.length; i++) {
      double value = widget.data["items"][widget.keyS]["items"][i]["value"].toDouble();
      double amount = widget.counters[counterKeys[i]]!;
      total = total + (value * amount);
    }

    if (mode == 1) {
      total = total + widget.extraAmount;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {Navigator.pop(context);},
          icon: Icon(Icons.arrow_back)
        ),
        title: Text("Calculations"),
        centerTitle: true
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.data["items"][widget.keyS]["items"].length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    widget.data["items"][widget.keyS]["items"][index]["name"],
                    style: TextStyle(
                      fontSize: 15
                    )
                  ),
                  subtitle: Text(
                    "${widget.data["items"][widget.keyS]["items"][index]["value"].toDouble()}${widget.unit["abbr"]}/serving",
                    style: TextStyle(
                      fontSize: 15
                    )
                  ),
                  trailing: Column(
                    children: [
                      Text(
                        "${widget.counters[widget.data["items"][widget.keyS]["items"][index]["name"]]} servings",
                        style: TextStyle(
                          fontSize: 15
                        )
                      ),
                      Text(
                        "${widget.counters[widget.data["items"][widget.keyS]["items"][index]["name"]] * widget.data["items"][widget.keyS]["items"][index]["value"]}${widget.unit["abbr"]} total",
                        style: TextStyle(
                          fontSize: 15
                        ),
                      )
                    ],
                  )
                );
              }
            )
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "Extra:",
                      style: TextStyle(
                        fontSize: 18
                      )
                    ),
                    Spacer(),
                    Text(
                      "${widget.extraAmount}${widget.unit["abbr"]}",
                      style: TextStyle(
                        fontSize: 18
                      )
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Subtotal:",
                      style: TextStyle(
                        fontSize: 18
                      )
                    ),
                    Spacer(),
                    Text(
                      "${calculateTotal(2)}${widget.unit["abbr"]}",
                      style: TextStyle(
                        fontSize: 18
                      )
                    )
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Total:",
                      style: TextStyle(
                        fontSize: 18
                      )
                    ),
                    Spacer(),
                    Text(
                      "${calculateTotal(1)}${widget.unit["abbr"]}",
                      style: TextStyle(
                        fontSize: 18
                      )
                    )
                  ],
                )
              ]
            ),
          )
        ],
      )
    );
  }
}