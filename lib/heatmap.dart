import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// Data point for heatmap
class HeatmapPoint {
  final double x;
  final double y;
  final double value;
  final double? radius;

  const HeatmapPoint({
    required this.x,
    required this.y,
    required this.value,
    this.radius,
  });
}

/// Heatmap configuration
class HeatmapConfig {
  final Color backgroundColor;
  final Map<int, Color> gradient;
  final double radius;
  final double opacity;
  final double maxOpacity;
  final double minOpacity;
  final double blur;
  final String xField;
  final String yField;
  final String valueField;
  final ImageProvider? backgroundImage;
  final BoxFit backgroundFit;
  final BlendMode? blendMode;
  final double backgroundOpacity;
  final bool useNormalizedCoordinates;

  const HeatmapConfig({
    this.backgroundColor = Colors.transparent,
    this.gradient = const {
      0: Colors.blue,
      50: Colors.green,
      80: Colors.yellow,
      100: Colors.red,
    },
    this.radius = 20.0,
    this.opacity = 0.6,
    this.maxOpacity = 1.0,
    this.minOpacity = 0.0,
    this.blur = 0.85,
    this.xField = 'x',
    this.yField = 'y',
    this.valueField = 'value',
    this.backgroundImage,
    this.backgroundFit = BoxFit.cover,
    this.blendMode,
    this.backgroundOpacity = 1.0,
    this.useNormalizedCoordinates = false,
  });
}

/// Heatmap data container
class HeatmapData {
  final List<HeatmapPoint> points;
  final double max;
  final double min;

  const HeatmapData({required this.points, required this.max, this.min = 0.0});

  /// Create HeatmapData with automatic min/max calculation
  factory HeatmapData.fromPoints(List<HeatmapPoint> points) {
    if (points.isEmpty) {
      return const HeatmapData(points: [], max: 0.0, min: 0.0);
    }

    double max = points.first.value;
    double min = points.first.value;

    for (final point in points) {
      if (point.value > max) max = point.value;
      if (point.value < min) min = point.value;
    }

    return HeatmapData(points: points, max: max, min: min);
  }
}

/// Custom painter for rendering the heatmap
class HeatmapPainter extends CustomPainter {
  final HeatmapData data;
  final HeatmapConfig config;
  final ui.Image? backgroundImage;

  HeatmapPainter({
    required this.data,
    required this.config,
    this.backgroundImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background image if provided - fill the entire canvas
    if (backgroundImage != null) {
      _drawBackgroundImage(canvas, size);
    }

    if (data.points.isEmpty) return;

    // Get image dimensions for coordinate scaling
    double imageWidth = size.width;
    double imageHeight = size.height;

    if (backgroundImage != null) {
      imageWidth = backgroundImage!.width.toDouble();
      imageHeight = backgroundImage!.height.toDouble();
    }

    // Create a picture recorder for off-screen heatmap rendering
    final recorder = ui.PictureRecorder();
    final offscreenCanvas = Canvas(recorder);

    // Render each point as a radial gradient on offscreen canvas
    for (final point in data.points) {
      _drawHeatPoint(
        offscreenCanvas,
        point,
        size,
        imageWidth,
        imageHeight,
        config.blendMode,
      );
    }

    // Complete the heatmap picture
    final heatmapPicture = recorder.endRecording();

    // Draw the heatmap with blend mode
    // final paint = Paint()..blendMode = config.blendMode;
    canvas.drawPicture(heatmapPicture);
  }

  void _drawBackgroundImage(Canvas canvas, Size size) {
    if (backgroundImage == null) return;

    final image = backgroundImage!;

    // Calculate the destination rectangle based on BoxFit
    final Rect destRect;
    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    switch (config.backgroundFit) {
      case BoxFit.fill:
        destRect = Rect.fromLTWH(0, 0, size.width, size.height);
        break;
      case BoxFit.contain:
        final double scale = math.min(
          size.width / image.width,
          size.height / image.height,
        );
        final double scaledWidth = image.width * scale;
        final double scaledHeight = image.height * scale;
        final double offsetX = (size.width - scaledWidth) / 2;
        final double offsetY = (size.height - scaledHeight) / 2;
        destRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
        break;
      case BoxFit.cover:
        final double scale = math.max(
          size.width / image.width,
          size.height / image.height,
        );
        final double scaledWidth = image.width * scale;
        final double scaledHeight = image.height * scale;
        final double offsetX = (size.width - scaledWidth) / 2;
        final double offsetY = (size.height - scaledHeight) / 2;
        destRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
        break;
      case BoxFit.fitWidth:
        final double scale = size.width / image.width;
        final double scaledHeight = image.height * scale;
        final double offsetY = (size.height - scaledHeight) / 2;
        destRect = Rect.fromLTWH(0, offsetY, size.width, scaledHeight);
        break;
      case BoxFit.fitHeight:
        final double scale = size.height / image.height;
        final double scaledWidth = image.width * scale;
        final double offsetX = (size.width - scaledWidth) / 2;
        destRect = Rect.fromLTWH(offsetX, 0, scaledWidth, size.height);
        break;
      case BoxFit.none:
        final double offsetX = (size.width - image.width) / 2;
        final double offsetY = (size.height - image.height) / 2;
        destRect = Rect.fromLTWH(
          offsetX,
          offsetY,
          image.width.toDouble(),
          image.height.toDouble(),
        );
        break;
      case BoxFit.scaleDown:
        if (image.width <= size.width && image.height <= size.height) {
          // Use BoxFit.none if image is smaller than canvas
          final double offsetX = (size.width - image.width) / 2;
          final double offsetY = (size.height - image.height) / 2;
          destRect = Rect.fromLTWH(
            offsetX,
            offsetY,
            image.width.toDouble(),
            image.height.toDouble(),
          );
        } else {
          // Use BoxFit.contain if image is larger than canvas
          final double scale = math.min(
            size.width / image.width,
            size.height / image.height,
          );
          final double scaledWidth = image.width * scale;
          final double scaledHeight = image.height * scale;
          final double offsetX = (size.width - scaledWidth) / 2;
          final double offsetY = (size.height - scaledHeight) / 2;
          destRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
        }
        break;
    }

    final paint = Paint()
      ..color = Colors.white.withAlpha(
        (config.backgroundOpacity * 255).round(),
      );
    canvas.drawImageRect(image, srcRect, destRect, paint);
  }

  void _drawHeatPoint(
    Canvas canvas,
    HeatmapPoint point,
    Size canvasSize,
    double imageWidth,
    double imageHeight,
    BlendMode? blendMode,
  ) {
    final pointRadius = point.radius ?? config.radius;

    // Normalize value to range [0.0, 1.0]
    final normalizedValue = (point.value - data.min) / (data.max - data.min);

    // Scale coordinates from image space to canvas space
    final scaleX = canvasSize.width / imageWidth;
    final scaleY = canvasSize.height / imageHeight;

    final canvasX =
        point.x * scaleX * (config.useNormalizedCoordinates ? imageWidth : 1);
    final canvasY =
        point.y * scaleY * (config.useNormalizedCoordinates ? imageHeight : 1);

    // Scale radius proportionally to the smaller dimension to maintain aspect ratio
    final scaleFactor = math.min(scaleX, scaleY);
    final scaledRadius = pointRadius * scaleFactor;

    // Calculate opacity based on config
    double pointOpacity = config.opacity.clamp(
      config.minOpacity,
      config.maxOpacity,
    );
    /* if (config.opacity < 1.0) {
      pointOpacity = config.opacity;
    } else {
      pointOpacity =
          config.minOpacity +
          (config.maxOpacity - config.minOpacity) * normalizedValue;
    } */

    // Get color from gradient
    final color = _getGradientColor(normalizedValue);

    // Create radial gradient
    final gradient = RadialGradient(
      colors: [
        color.withAlpha((pointOpacity * 255).round()),
        color.withAlpha(0),
      ],
      stops: const [0.0, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(
          center: Offset(canvasX, canvasY),
          radius: scaledRadius * (1.0 + config.blur),
        ),
      )
      ..isAntiAlias = true;
    if (blendMode != null) {
      paint.blendMode = blendMode;
    }

    canvas.drawCircle(
      Offset(canvasX, canvasY),
      scaledRadius * (1.0 + config.blur),
      paint,
    );
  }

  Color _getGradientColor(double value) {
    if (config.gradient.isEmpty) return Colors.red;

    // Convert normalized value (0.0-1.0) to percentage (0-100)
    final percentage = (value * 100).round();

    final sortedKeys = config.gradient.keys.toList()..sort();

    if (percentage <= sortedKeys.first) {
      return config.gradient[sortedKeys.first]!;
    }

    if (percentage >= sortedKeys.last) {
      return config.gradient[sortedKeys.last]!;
    }

    // Find the two colors to interpolate between
    int lowerKey = sortedKeys.first;
    int upperKey = sortedKeys.last;

    for (int i = 0; i < sortedKeys.length - 1; i++) {
      if (percentage >= sortedKeys[i] && percentage <= sortedKeys[i + 1]) {
        lowerKey = sortedKeys[i];
        upperKey = sortedKeys[i + 1];
        break;
      }
    }

    final lowerColor = config.gradient[lowerKey]!;
    final upperColor = config.gradient[upperKey]!;

    final t = (percentage - lowerKey) / (upperKey - lowerKey);
    return Color.lerp(lowerColor, upperColor, t)!;
  }

  @override
  bool shouldRepaint(HeatmapPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.config != config ||
        oldDelegate.backgroundImage != backgroundImage;
  }
}

/// Flutter Heatmap Widget - equivalent to heatmap.js
class Heatmap extends StatefulWidget {
  final HeatmapData data;
  final HeatmapConfig config;
  final Function(double min, double max)? onExtremaChange;
  final Function(Size imageSize)? onImageSizeChange;

  const Heatmap({
    super.key,
    required this.data,
    this.config = const HeatmapConfig(),
    this.onExtremaChange,
    this.onImageSizeChange,
  });

  /// Generate heatmap data scaled to image dimensions
  @override
  State<Heatmap> createState() => _HeatmapState();
}

class _HeatmapState extends State<Heatmap> {
  ui.Image? _backgroundImage;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Size? _imageSize;
  bool _imageLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    // Schedule the callback for after the build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyExtremaChange();
    });
  }

  @override
  void didUpdateWidget(Heatmap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if background image changed
    if (oldWidget.config.backgroundImage != widget.config.backgroundImage) {
      _disposeImageStream();
      _loadBackgroundImage();
    }

    if (oldWidget.data != widget.data) {
      // Schedule the callback for after the build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyExtremaChange();
      });
    }
  }

  @override
  void dispose() {
    _disposeImageStream();
    super.dispose();
  }

  void _disposeImageStream() {
    if (_imageStreamListener != null && _imageStream != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStreamListener = null;
    _imageStream = null;
    _backgroundImage = null;
    _imageSize = null;
  }

  void _loadBackgroundImage() {
    if (widget.config.backgroundImage == null) {
      setState(() {
        _backgroundImage = null;
        _imageSize = null;
        _imageLoading = false;
      });
      return;
    }

    setState(() {
      _imageLoading = true;
    });

    final ImageConfiguration config = const ImageConfiguration();
    _imageStream = widget.config.backgroundImage!.resolve(config);

    _imageStreamListener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (mounted) {
          final size = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          setState(() {
            _backgroundImage = info.image;
            _imageSize = size;
            _imageLoading = false;
          });
          _notifyImageSizeChange(size);
        }
      },
      onError: (exception, stackTrace) {
        if (mounted) {
          setState(() {
            _backgroundImage = null;
            _imageSize = null;
            _imageLoading = false;
          });
        }
      },
    );

    _imageStream!.addListener(_imageStreamListener!);
  }

  void _notifyExtremaChange() {
    if (widget.onExtremaChange != null && mounted) {
      widget.onExtremaChange!(widget.data.min, widget.data.max);
    }
  }

  void _notifyImageSizeChange(Size size) {
    if (widget.onImageSizeChange != null && mounted) {
      widget.onImageSizeChange!(size);
    }
  }

  /// Get image dimensions from the currently loaded image
  Size? get imageSize => _imageSize;

  /// Check if image is currently loading
  bool get isImageLoading => _imageLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: HeatmapPainter(
              data: widget.data,
              config: widget.config,
              backgroundImage: _backgroundImage,
            ),
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
          );
        },
      ),
    );
  }
}
