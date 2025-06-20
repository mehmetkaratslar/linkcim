// Dosya Konumu: lib/widgets/tag_chip.dart

import 'package:flutter/material.dart';

enum TagChipSize { small, medium, large }

class TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final bool showDelete;
  final bool highlighted;
  final TagChipSize size;
  final Color? backgroundColor;
  final Color? textColor;

  const TagChip({
    Key? key,
    required this.tag,
    this.onDeleted,
    this.onTap,
    this.showDelete = false,
    this.highlighted = false,
    this.size = TagChipSize.medium,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color chipColor = backgroundColor ??
        (highlighted ? Colors.yellow[200]! : Colors.blue[50]!);
    Color labelColor = textColor ??
        (highlighted ? Colors.black : Colors.blue[800]!);

    double fontSize;
    EdgeInsets padding;
    double iconSize;

    switch (size) {
      case TagChipSize.small:
        fontSize = 10;
        padding = EdgeInsets.symmetric(horizontal: 8, vertical: 2);
        iconSize = 14;
        break;
      case TagChipSize.large:
        fontSize = 16;
        padding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        iconSize = 20;
        break;
      case TagChipSize.medium:
      default:
        fontSize = 12;
        padding = EdgeInsets.symmetric(horizontal: 12, vertical: 4);
        iconSize = 16;
        break;
    }

    if (showDelete && onDeleted != null) {
      return Chip(
        label: Text(
          tag,
          style: TextStyle(
            color: labelColor,
            fontSize: fontSize,
            fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onDeleted: onDeleted,
        deleteIcon: Icon(Icons.close, size: iconSize),
        deleteIconColor: labelColor,
        backgroundColor: chipColor,
        side: highlighted ? BorderSide(color: Colors.orange, width: 2) : null,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(16),
          border: highlighted
              ? Border.all(color: Colors.orange, width: 2)
              : Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tag,
              size: iconSize,
              color: labelColor,
            ),
            SizedBox(width: 4),
            Text(
              tag,
              style: TextStyle(
                color: labelColor,
                fontSize: fontSize,
                fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}