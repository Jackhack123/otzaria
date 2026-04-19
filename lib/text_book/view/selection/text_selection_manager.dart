import 'package:flutter/material.dart';

/// admin מצב בחירת text זמני (Selection-only mode)
/// מאפשר בחירת text לצורך Copyה בלבד, לno עריכה
class TextSelectionManager extends ChangeNotifier {
  /// נקודת העיגון לבחירה (anchor point)
  int? _anchorIndex;

  /// האם נמצאים במצב בחירה זמני
  bool _isInSelectionMode = false;

  int? get anchorIndex => _anchorIndex;
  bool get isInSelectionMode => _isInSelectionMode;

  /// קביעת anchor point (נקודת start לבחירה)
  void setAnchor(int index) {
    _anchorIndex = index;
    _isInSelectionMode = true;
    notifyListeners();
  }

  /// כניסה למצב בחירה עם double-click
  /// note: הפיצ'ר no מומש במלואו בגלל מגבלות Flutter
  void enterDoubleClickMode(int index) {
    _anchorIndex = index;
    _isInSelectionMode = true;
    notifyListeners();
  }

  /// יציאה ממצב בחירה
  void exitSelectionMode() {
    _anchorIndex = null;
    _isInSelectionMode = false;
    notifyListeners();
  }

  /// check אם יש anchor פעיל
  bool hasAnchor() => _anchorIndex != null;

  /// איפוס full
  void reset() {
    _anchorIndex = null;
    _isInSelectionMode = false;
    notifyListeners();
  }
}

/// Intent לבחירת פסקה (double-click)
class SelectParagraphIntent extends Intent {
  const SelectParagraphIntent();
}

/// Intent לבחירת טווח עם Shift+Click
class SelectRangeIntent extends Intent {
  const SelectRangeIntent();
}

/// Intent לניקוי בחירה
class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}
