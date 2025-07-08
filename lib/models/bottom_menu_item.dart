import 'dart:convert';

class BottomMenuItem {
  final String label;
  final MenuIcon icon;
  final String url;
  final bool isActive;

  BottomMenuItem({
    required this.label,
    required this.icon,
    required this.url,
    this.isActive = false,
  });

  factory BottomMenuItem.fromJson(Map<String, dynamic> json) {
    return BottomMenuItem(
      label: json['label'] ?? '',
      icon: MenuIcon.fromJson(json['icon'] ?? {}),
      url: json['url'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'icon': icon.toJson(),
      'url': url,
      'isActive': isActive,
    };
  }

  BottomMenuItem copyWith({
    String? label,
    MenuIcon? icon,
    String? url,
    bool? isActive,
  }) {
    return BottomMenuItem(
      label: label ?? this.label,
      icon: icon ?? this.icon,
      url: url ?? this.url,
      isActive: isActive ?? this.isActive,
    );
  }

  static List<BottomMenuItem> fromJsonString(String jsonString) {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => BottomMenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error parsing bottom menu items: $e');
      return [];
    }
  }
}

class MenuIcon {
  final String type; // 'preset' or 'custom'
  final String? name; // for preset icons
  final String? iconUrl; // for custom icons
  final String? iconSize; // for custom icons

  MenuIcon({required this.type, this.name, this.iconUrl, this.iconSize});

  factory MenuIcon.fromJson(Map<String, dynamic> json) {
    return MenuIcon(
      type: json['type'] ?? 'preset',
      name: json['name'],
      iconUrl: json['icon_url'],
      iconSize: json['icon_size']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'icon_url': iconUrl,
      'icon_size': iconSize,
    };
  }

  bool get isPreset => type == 'preset';
  bool get isCustom => type == 'custom';
}
