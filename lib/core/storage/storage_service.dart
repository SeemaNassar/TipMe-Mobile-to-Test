// lib/core/storage/storage_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static bool _initialized = false;

  /// Initialize storage service
  static Future<void> init() async {
    _initialized = true;
  }

  /// Check if storage is initialized
  static void _checkInitialized() {
    if (!_initialized) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
  }

  static Future<void> save(String key, String? value) async {
    _checkInitialized();
    await _secureStorage.write(key: key, value: value ?? "");
  }

  static Future<String?> get(String key) async {
    _checkInitialized();
    return await _secureStorage.read(key: key);
  }

  static Future<void> delete(String key) async {
    _checkInitialized();
    await _secureStorage.delete(key: key);
  }

  static Future<bool> hasKey(String key) async {
    _checkInitialized();
    final value = await _secureStorage.read(key: key);
    return value != null && value.isNotEmpty;
  }

  static Future<bool> clear() async {
    _checkInitialized();
    await _secureStorage.deleteAll();
    return true;
  }

  static Future<void> setList(String key, List<dynamic> list) async {
    _checkInitialized();
    final jsonString = json.encode(list);
    await _secureStorage.write(key: key, value: jsonString);
  }

  static Future<List<dynamic>> getList(String key) async {
    _checkInitialized();
    final jsonString = await _secureStorage.read(key: key);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        return json.decode(jsonString) as List<dynamic>;
      } catch (e) {
        print('Error parsing list from storage: $e');
        return [];
      }
    }
    return [];
  }

  static Future<bool> hasList(String key) async {
    _checkInitialized();
    final value = await _secureStorage.read(key: key);
    return value != null && value.isNotEmpty;
  }

  /// Save any object to storage (as JSON)
  static Future<void> saveObject(String key, dynamic object) async {
    _checkInitialized();
    final jsonString = json.encode(object);
    await _secureStorage.write(key: key, value: jsonString);
  }

  /// Get any object from storage (from JSON)
  static Future<T?> getObject<T>(String key) async {
    _checkInitialized();
    final jsonString = await _secureStorage.read(key: key);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        return json.decode(jsonString) as T?;
      } catch (e) {
        print('Error parsing object from storage: $e');
        return null;
      }
    }
    return null;
  }

  /// Get all keys in storage
  static Future<Set<String>> getAllKeys() async {
    _checkInitialized();
    final allData = await _secureStorage.readAll();
    return allData.keys.toSet();
  }

  /// Get storage size
  static Future<int> getSize() async {
    _checkInitialized();
    final allData = await _secureStorage.readAll();
    return allData.length;
  }
}
