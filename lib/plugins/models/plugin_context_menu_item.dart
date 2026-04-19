/// מודל המייצג פריט תפריט הקשר שנרname על ידי פnoגין.
class PluginContextMenuItem {
  final String id;
  final String label;
  final String? icon;

  const PluginContextMenuItem({
    required this.id,
    required this.label,
    this.icon,
  });
}
