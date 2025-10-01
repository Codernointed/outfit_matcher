import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/upload_options_screen.dart';
// import 'package:vestiq/features/wardrobe/presentation/screens/item_details_screen.dart'; // For item tap

// Mock data structure for a clothing item
class MockClothingItem {
  final String id;
  final String name;
  final String imagePath; // Local asset path or network URL
  final String type; // e.g., 'Top', 'Bottom', 'Dress'
  final List<String>? occasions; // e.g., ['Casual', 'Work']

  MockClothingItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.type,
    this.occasions,
  });
}

// Provider for mock closet items (replace with actual data source later)
final mockClosetProvider = Provider<List<MockClothingItem>>((ref) {
  // Placeholder images - replace with actual asset paths if you have them
  return [
    MockClothingItem(
      id: '1',
      name: 'Blue Casual Shirt',
      imagePath: 'assets/images/placeholders/top1.png',
      type: 'Top',
      occasions: ['Casual'],
    ),
    MockClothingItem(
      id: '2',
      name: 'Black Denim Jeans',
      imagePath: 'assets/images/placeholders/bottom1.png',
      type: 'Bottom',
    ),
    MockClothingItem(
      id: '3',
      name: 'Red Summer Dress',
      imagePath: 'assets/images/placeholders/dress1.png',
      type: 'Dress',
      occasions: ['Summer', 'Party'],
    ),
    MockClothingItem(
      id: '4',
      name: 'Grey Hoodie',
      imagePath: 'assets/images/placeholders/outerwear1.png',
      type: 'Outerwear',
    ),
    MockClothingItem(
      id: '5',
      name: 'Leather Belt',
      imagePath: 'assets/images/placeholders/accessory1.png',
      type: 'Accessory',
    ),
    MockClothingItem(
      id: '6',
      name: 'Office Blouse',
      imagePath: 'assets/images/placeholders/top2.png',
      type: 'Top',
      occasions: ['Work'],
    ),
  ];
});

// Provider for category tabs
final categoryTabsProvider = Provider<List<String>>((ref) {
  return ['All', 'Tops', 'Bottoms', 'Dresses', 'Outerwear', 'Accessories'];
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final filteredClosetProvider = Provider<List<MockClothingItem>>((ref) {
  final items = ref.watch(mockClosetProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  if (selectedCategory == 'All') {
    return items;
  }
  return items
      .where(
        (item) =>
            item.type ==
                selectedCategory.substring(0, selectedCategory.length - 1) ||
            item.type == selectedCategory,
      )
      .toList(); // Handle plural vs singular
});

class ClosetScreen extends ConsumerWidget {
  const ClosetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryTabsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final itemsToDisplay = ref.watch(filteredClosetProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Closet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Closet',
            onPressed: () {
              /* TODO */
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort & Filter',
            onPressed: () {
              /* TODO */
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      if (selected) {
                        ref.read(selectedCategoryProvider.notifier).state =
                            category;
                      }
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child:
                itemsToDisplay.isEmpty
                    ? _buildEmptyClosetView(context)
                    : GridView.builder(
                      padding: const EdgeInsets.all(12.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Number of columns
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio:
                                0.8, // Adjust for item card proportions
                          ),
                      itemCount:
                          itemsToDisplay.length + 1, // +1 for the Add New tile
                      itemBuilder: (context, index) {
                        if (index == itemsToDisplay.length) {
                          return _buildAddNewTile(context);
                        }
                        final item = itemsToDisplay[index];
                        return _buildItemThumbnail(context, item);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemThumbnail(BuildContext context, MockClothingItem item) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias, // Ensures image respects border radius
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to ItemDetailView (Section 6.3)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tapped on ${item.name}')));
        },
        onLongPress: () {
          // TODO: Show Quick Actions Menu (Section 6.2)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Long pressed ${item.name}')));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[200], // Placeholder background
                // child: Image.asset(item.imagePath, fit: BoxFit.cover, // Use if you have actual assets
                //   errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey))),
                child: Center(
                  child: Icon(
                    Icons.checkroom,
                    size: 50,
                    color: theme.colorScheme.primary,
                  ),
                ), // Placeholder icon
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.occasions != null && item.occasions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 4.0,
                  left: 4.0,
                  right: 4.0,
                ),
                child: Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.center,
                  children:
                      item.occasions!
                          .take(2)
                          .map(
                            (occasion) => Chip(
                              label: Text(
                                occasion,
                                style: theme.textTheme.labelSmall,
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: theme
                                  .colorScheme
                                  .secondaryContainer
                                  .withOpacity(0.5),
                            ),
                          )
                          .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewTile(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const UploadOptionsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: DottedBorder(
        color: theme.colorScheme.primary.withOpacity(0.7),
        strokeWidth: 2,
        dashPattern: const [6, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Add New Item',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyClosetView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Your Closet is Empty',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the "Add New Item" button to start building your virtual wardrobe.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Item'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UploadOptionsScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// A simple DottedBorder widget (often you'd use a package like dotted_border)
// For this example, keeping it self-contained. This is a very basic version.
class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final Radius radius;
  final BorderType borderType;

  const DottedBorder({
    super.key,
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.dashPattern = const [3, 1],
    this.radius = const Radius.circular(0),
    this.borderType = BorderType.Rect,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashPattern: dashPattern,
        radius: radius,
        borderType: borderType,
      ),
      child: child,
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final Radius radius;
  final BorderType borderType;

  _DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
    required this.radius,
    required this.borderType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    Path path;
    if (borderType == BorderType.RRect) {
      path =
          Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, radius));
    } else if (borderType == BorderType.Rect) {
      path = Path()..addRect(Offset.zero & size);
    } else if (borderType == BorderType.Oval) {
      path = Path()..addOval(Offset.zero & size);
    } else {
      // Circle
      path =
          Path()..addOval(
            Rect.fromCircle(
              center: size.center(Offset.zero),
              radius: size.width / 2,
            ),
          );
    }

    final dashPath =
        _DashPathPainter(path: path, dashArray: dashPattern).paint();
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Helper to convert a path to a dashed path
class _DashPathPainter {
  final Path path;
  final List<double> dashArray;

  _DashPathPainter({required this.path, required this.dashArray});

  Path paint() {
    final Path dest = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final len = dashArray[draw ? 0 : 1];
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }
}

// Enum for DottedBorder type (already exists in dotted_border package)
// Re-defined here for self-containment if not using the package.
enum BorderType { Rect, RRect, Oval, Circle }
