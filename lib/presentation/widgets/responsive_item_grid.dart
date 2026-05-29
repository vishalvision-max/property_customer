import 'package:flutter/material.dart';

/// A premium, highly responsive grid widget that dynamically calculates how many 
/// columns can fit in a single row based on the available width and a minimum item width.
/// 
/// Unlike a standard GridView, it uses a Wrap layout with calculated equal-width 
/// children to prevent nested scrolling issues, making it perfect for lists of:
/// * Amenities
/// * Highlights
/// * Facilities / Tags
/// * Property Specs
/// 
/// Supports an optional collapsible state, showing exactly one row of items 
/// initially when collapsed, with a dynamic "Show More/Less" toggle link.
/// Automatically handles mobile, tablet, and desktop viewports seamlessly.
class ResponsiveItemGrid<T> extends StatelessWidget {
  /// The collection of generic model items to display.
  final List<T> items;

  /// Builder function called to construct a widget for each item in [items].
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// The minimum width allowed for each item. Columns are dynamically computed 
  /// by dividing the parent's width by this value.
  final double minItemWidth;

  /// The horizontal spacing between items in a row.
  final double spacing;

  /// The vertical spacing between rows.
  final double runSpacing;

  /// Whether the grid can be collapsed.
  final bool isCollapsible;

  /// The expansion state of the grid (only active when [isCollapsible] is true).
  final bool isExpanded;

  /// Callback executed when the user clicks the "More/Less" toggle button.
  final VoidCallback? onToggle;

  /// Optional builder function to customize the label of the "More" button.
  final String Function(int hiddenCount)? moreLabel;

  /// The label to display on the collapse button.
  final String lessLabel;

  /// Optional fixed column count to bypass dynamic width-based calculation.
  final int? fixedColumns;

  const ResponsiveItemGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.minItemWidth = 120,
    this.spacing = 12,
    this.runSpacing = 12,
    this.isCollapsible = false,
    this.isExpanded = false,
    this.onToggle,
    this.moreLabel,
    this.lessLabel = 'Show Less',
    this.fixedColumns,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.maxWidth;

        // Dynamically compute or use fixed column count for the grid
        int columns = fixedColumns ?? (parentWidth / minItemWidth).floor();
        if (columns < 1) columns = 1;

        // Determine if the grid needs to collapse to exactly one row of items
        final showCollapseToggle = isCollapsible && items.length > columns;
        final visibleItems = (isCollapsible && !isExpanded)
            ? items.take(columns).toList()
            : items;

        // Calculate the columns to render for width distribution
        int activeColumns = columns;
        if (activeColumns > visibleItems.length) {
          activeColumns = visibleItems.length;
        }
        if (activeColumns < 1) activeColumns = 1;

        // Calculate equal-width children that stretch across the entire available space
        final totalSpacing = spacing * (activeColumns - 1);
        final itemWidth = (parentWidth - totalSpacing) / activeColumns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: runSpacing,
              children: visibleItems.map((item) {
                return SizedBox(
                  width: itemWidth,
                  child: itemBuilder(context, item),
                );
              }).toList(),
            ),
            if (showCollapseToggle && onToggle != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onToggle,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isExpanded
                              ? lessLabel
                              : (moreLabel != null
                                  ? moreLabel!(items.length - visibleItems.length)
                                  : '+ ${items.length - visibleItems.length} More'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5C46E8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: const Color(0xFF5C46E8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
