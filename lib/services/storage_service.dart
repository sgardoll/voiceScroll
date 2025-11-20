import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowread/models/script.dart';
import 'package:flowread/utils/sample_data.dart';

class StorageService {
  static const String _scriptsKey = 'flowread_scripts';

  Future<List<Script>> getScripts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scriptsJson = prefs.getStringList(_scriptsKey) ?? [];
      
      if (scriptsJson.isEmpty) {
        // Load sample data on first run
        final sampleScripts = SampleData.getSampleScripts();
        await _saveScripts(sampleScripts);
        return sampleScripts;
      }
      
      return scriptsJson.map((json) {
        final Map<String, dynamic> decoded = jsonDecode(json);
        return Script.fromJson(decoded);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveScript(Script script) async {
    try {
      final scripts = await getScripts();
      final existingIndex = scripts.indexWhere((s) => s.id == script.id);
      
      if (existingIndex != -1) {
        scripts[existingIndex] = script;
      } else {
        scripts.add(script);
      }
      
      await _saveScripts(scripts);
    } catch (e) {
      throw Exception('Failed to save script: $e');
    }
  }

  Future<void> deleteScript(String scriptId) async {
    try {
      final scripts = await getScripts();
      scripts.removeWhere((script) => script.id == scriptId);
      await _saveScripts(scripts);
    } catch (e) {
      throw Exception('Failed to delete script: $e');
    }
  }

  Future<void> _saveScripts(List<Script> scripts) async {
    final prefs = await SharedPreferences.getInstance();
    final scriptsJson = scripts.map((script) => jsonEncode(script.toJson())).toList();
    await prefs.setStringList(_scriptsKey, scriptsJson);
  }
}