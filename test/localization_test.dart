import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/localization/strings.dart';
void main(){test('English and German labels',(){L.language='en';expect(L.text('Einstellungen'),'Settings');expect(L.text('Zähle ●'),'Count ●');L.language='de';expect(L.text('Einstellungen'),'Einstellungen');});}
