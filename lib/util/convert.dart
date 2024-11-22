import 'package:carbcalc/util/var.dart';

Map carbcalcconvert(Map data, double dataFormat) {
  Map converted = {};
  double newFormat = format;

  switch (dataFormat) {
    default:
      converted = data;
      newFormat = format;
      return converted;
  }

  // ignore: dead_code
  return carbcalcconvert(converted, newFormat);
}