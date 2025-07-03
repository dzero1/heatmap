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
    heatmap: ^latest_version
```

Then run:

```sh
flutter pub get
```

## Usage

Import the main library:

```dart
import 'package:heatmap/heatmap.dart';
```

Here's a basic example:

```dart
final data = [
    [400, 522, 6],  // or [real world x, y, value]
    [0.1, 0.2, 3],  // or [Normalized x, Normalized y, value], use useNormalizedCoordinates=true in config
];

Heatmap(
    data: data,
    config: HeatmapConfig(
        radius: 40.0,
        blur: 0.6,
        maxOpacity: 0.7,
        minOpacity: 0.1,
        backgroundImage: ImageProvider,
        backgroundFit: BoxFit.fill,
        backgroundOpacity: 1.0,
        backgroundColor: Colors.transparent,
    ),
)
```

For more advanced usage and customization, refer to the documentation in `heatmap/lib/heatmap.dart` and see the `/example` folder.

## Additional information

- API Documentation (To be update)
- Contributions are welcome! Please open issues or pull requests on [GitHub](https://github.com/dzero1/heatmap).
- For questions or support, file an issue and expect a response within a few days.
