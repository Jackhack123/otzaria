import 'dart:convert';

/// מודל לfolder מותאמת אישית שהuser הוסיף
class CustomFolder {
  /// path הfolder בSystem הfiles
  final String path;

  /// האם להכניס את content הfolder ל-DB
  final bool addToDatabase;

  /// date add
  final DateTime addedAt;

  const CustomFolder({
    required this.path,
    this.addToDatabase = false,
    required this.addedAt,
  });

  /// name הfolder (לno הpath הfull)
  String get name => path.split(RegExp(r'[/\\]')).last;

  CustomFolder copyWith({
    String? path,
    bool? addToDatabase,
    DateTime? addedAt,
  }) {
    return CustomFolder(
      path: path ?? this.path,
      addToDatabase: addToDatabase ?? this.addToDatabase,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'addToDatabase': addToDatabase,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CustomFolder.fromJson(Map<String, dynamic> json) {
    return CustomFolder(
      path: json['path'] as String,
      addToDatabase: json['addToDatabase'] as bool? ?? false,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomFolder && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}

/// admin folders מותאמות אישית
class CustomFoldersManager {
  /// טעינת רשימת הfolders מהsettings
  static List<CustomFolder> loadFolders(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => CustomFolder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// האם קיימות folders מותאמות אישית פעילות
  static bool hasFolders(String? jsonString) {
    return loadFolders(jsonString).isNotEmpty;
  }

  /// save רשימת הfolders לsettings
  static String saveFolders(List<CustomFolder> folders) {
    return jsonEncode(folders.map((f) => f.toJson()).toList());
  }

  /// הוספת folder חדשה
  static List<CustomFolder> addFolder(List<CustomFolder> folders, String path) {
    if (folders.any((f) => f.path == path)) {
      return folders; // הfolder כבר קיימת
    }
    return [
      ...folders,
      CustomFolder(path: path, addedAt: DateTime.now()),
    ];
  }

  /// הסרת folder
  static List<CustomFolder> removeFolder(
      List<CustomFolder> folders, String path) {
    return folders.where((f) => f.path != path).toList();
  }

  /// update הגדרת addToDatabase לfolder
  static List<CustomFolder> updateFolderDbSetting(
      List<CustomFolder> folders, String path, bool addToDatabase) {
    return folders.map((f) {
      if (f.path == path) {
        return f.copyWith(addToDatabase: addToDatabase);
      }
      return f;
    }).toList();
  }
}
