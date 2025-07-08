import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/env_config.dart';
import '../models/bottom_menu_item.dart';

class CustomBottomNavigation extends StatelessWidget {
  final List<BottomMenuItem> items;
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    Key? key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
      return Colors.grey; // fallback
    } catch (e) {
      return Colors.grey; // fallback
    }
  }

  double _parseFontSize() {
    return double.tryParse(EnvConfig.bottommenuFontSize) ?? 12.0;
  }

  FontWeight _getFontWeight() {
    if (EnvConfig.bottommenuFontBold) {
      return FontWeight.bold;
    }
    return FontWeight.normal;
  }

  FontStyle _getFontStyle() {
    if (EnvConfig.bottommenuFontItalic) {
      return FontStyle.italic;
    }
    return FontStyle.normal;
  }

  Widget _buildIcon(MenuIcon icon, bool isActive) {
    final iconSize = double.tryParse(icon.iconSize ?? '24') ?? 24.0;
    final iconColor = isActive
        ? _parseColor(EnvConfig.bottommenuActiveTabColor)
        : _parseColor(EnvConfig.bottommenuIconColor);

    if (icon.isPreset) {
      return Icon(
        _getPresetIcon(icon.name ?? ''),
        size: iconSize,
        color: iconColor,
      );
    } else if (icon.isCustom && icon.iconUrl != null) {
      if (icon.iconUrl!.endsWith('.svg')) {
        return SvgPicture.network(
          icon.iconUrl!,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        );
      } else {
        return CachedNetworkImage(
          imageUrl: icon.iconUrl!,
          width: iconSize,
          height: iconSize,
          color: iconColor,
          placeholder: (context, url) =>
              Icon(Icons.image, size: iconSize, color: iconColor),
          errorWidget: (context, url, error) =>
              Icon(Icons.error, size: iconSize, color: iconColor),
        );
      }
    }

    return Icon(Icons.home, size: iconSize, color: iconColor);
  }

  IconData _getPresetIcon(String iconName) {
    switch (iconName) {
      case 'home_outlined':
        return Icons.home_outlined;
      case 'home':
        return Icons.home;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'person':
        return Icons.person;
      case 'settings':
        return Icons.settings;
      case 'favorite':
        return Icons.favorite;
      case 'search':
        return Icons.search;
      case 'notifications':
        return Icons.notifications;
      case 'chat':
        return Icons.chat;
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'location_on':
        return Icons.location_on;
      case 'info':
        return Icons.info;
      case 'help':
        return Icons.help;
      case 'about':
        return Icons.info_outline;
      case 'contact':
        return Icons.contact_support;
      case 'card':
        return Icons.credit_card;
      case 'collections':
        return Icons.collections;
      case 'new_arrivals':
        return Icons.new_releases;
      default:
        return Icons.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!EnvConfig.isBottommenu || items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: _parseColor(EnvConfig.bottommenuBgColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (EnvConfig.bottommenuIconPosition == 'above')
                          _buildIcon(item.icon, isActive),
                        if (EnvConfig.bottommenuIconPosition == 'above')
                          const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: _parseFontSize(),
                            fontWeight: _getFontWeight(),
                            fontStyle: _getFontStyle(),
                            color: isActive
                                ? _parseColor(
                                    EnvConfig.bottommenuActiveTabColor,
                                  )
                                : _parseColor(EnvConfig.bottommenuTextColor),
                            fontFamily: EnvConfig.bottommenuFont,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (EnvConfig.bottommenuIconPosition == 'below')
                          const SizedBox(height: 4),
                        if (EnvConfig.bottommenuIconPosition == 'below')
                          _buildIcon(item.icon, isActive),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
