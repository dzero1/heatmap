# Heatmap Painter

A Flutter package for creating customizable and interactive heatmaps. Ideal for visualizing data distributions, activity tracking, or any scenario where you need a grid-based color representation.

## Features

- Render heatmaps with customizable color gradients.
- Support for interactive touch events.
- Flexible grid sizing and cell shapes.
- Easy integration with existing Flutter widgets.

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
    heatmap_painter: ^latest_version
```

Then run:

```sh
flutter pub get
```

## Usage

Import the main library:

```dart
import 'package:heatmap_painter/heatmap_painter.dart';
```

Here's a basic example:

```dart
final data = [
    [1, 2, 3],  // [x, y, value]
    [4, 5, 6],
    [7, 8, 9],
];

Heatmap(
    data: data,
    colorScheme: HeatmapColorScheme.defaultScheme,
    onCellTap: (row, col) {
        print('Tapped cell at ($row, $col)');
    },
)
```

For more advanced usage and customization, refer to the documentation in `heatmap_painter/lib/heatmap_painter.dart` and see the `/example` folder.

## Additional information

- [API Documentation](https://pub.dev/documentation/heatmap_painter/latest/)
- Contributions are welcome! Please open issues or pull requests on [GitHub](https://github.com/your-repo/heatmap_painter).
- For questions or support, file an issue and expect a response within a few days.
