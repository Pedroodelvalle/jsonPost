import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_element_widget.dart';

class CanvasElementRenderer {
  final Offset parentOffset;
  final Size canvasSize;
  final double scaleFactor;
  final bool isExporting;

  const CanvasElementRenderer({
    this.parentOffset = Offset.zero,
    required this.canvasSize,
    this.scaleFactor = 1.0,
    this.isExporting = false,
  });  

  // Método auxiliar para escalar valores de acordo com o fator de escala
  double _scaleValue(double value) {
    return isExporting ? value : value / scaleFactor;
  }

  // Método auxiliar para escalar posições
  Offset _scaleOffset(Offset offset) {
    return isExporting ? offset : Offset(offset.dx / scaleFactor, offset.dy / scaleFactor);
  }

  // Método para obter o tamanho do canvas escalado para visualização
  Size get displaySize => Size(
    canvasSize.width / scaleFactor, 
    canvasSize.height / scaleFactor
  );
  
  // Movido para dentro da classe
  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse('0x$hexColor'));
  }
  
  // Movido para dentro da classe
  FontWeight _parseFontWeight(String? weight) {
    switch (weight?.toLowerCase()) {
      case 'thin':
        return FontWeight.w100;
      case 'semibold':
        return FontWeight.w600;
      case 'bold':
        return FontWeight.bold;
      case 'normal':
        return FontWeight.normal;
      default:
        return FontWeight.normal;
    }
  }

  // Movido para dentro da classe
  TextAlign _parseTextAlign(String? align) {
    switch (align?.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  // Movido para dentro da classe
  BoxFit _parseBoxFit(String? fit) {
    switch (fit?.toLowerCase()) {
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      case 'fitwidth':
        return BoxFit.fitWidth;
      case 'fitheight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaledown':
        return BoxFit.scaleDown;
      default:
        return BoxFit.cover;
    }
  }

  // Movido para dentro da classe
  Widget _buildImageWidget(String path, double width, double height, String? fitKey) {
    final isNetwork = path.startsWith('http') || path.startsWith('https');
    final fit = _parseBoxFit(fitKey);

    return isNetwork
        ? Image.network(
            path,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
          )
        : Image.asset(
            path,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => const Icon(Icons.error, size: 40),
          );
  }
  
  // Movido para dentro da classe
  final Map<String, IconData> _materialIcons = const {
    "star": Icons.star,
    "heart": Icons.favorite,
    "home": Icons.home,
    "settings": Icons.settings,
    "search": Icons.search,
    "arrow": Icons.arrow_forward,
    "check": Icons.check,
    "close": Icons.close,
    // adicione mais conforme quiser
  };
  
  // Movido para dentro da classe
  List<Shadow>? _buildTextShadows(Map<String, dynamic>? shadow) {
    if (shadow == null) return null;

    final double blur = shadow['blur'] is num 
        ? (shadow['blur'] as num).toDouble() 
        : 0.0;
    final double offsetX = shadow['offsetX'] is num 
        ? (shadow['offsetX'] as num).toDouble() 
        : 0.0;
    final double offsetY = shadow['offsetY'] is num 
        ? (shadow['offsetY'] as num).toDouble() 
        : 0.0;

    // Aplicar escala aos valores da sombra
    final double scaledBlur = isExporting ? blur : blur / scaleFactor;
    final double scaledOffsetX = isExporting ? offsetX : offsetX / scaleFactor;
    final double scaledOffsetY = isExporting ? offsetY : offsetY / scaleFactor;

    return [
      Shadow(
        color: _parseColor(shadow['color'] ?? '#000000'),
        blurRadius: scaledBlur,
        offset: Offset(scaledOffsetX, scaledOffsetY),
      )
    ];
  }

  // Movido para dentro da classe
  List<BoxShadow>? _buildBoxShadows(Map<String, dynamic>? shadow) {
    if (shadow == null) return null;

    final double blur = shadow['blur'] is num 
        ? (shadow['blur'] as num).toDouble() 
        : 0.0;
    final double offsetX = shadow['offsetX'] is num 
        ? (shadow['offsetX'] as num).toDouble() 
        : 0.0;
    final double offsetY = shadow['offsetY'] is num 
        ? (shadow['offsetY'] as num).toDouble() 
        : 0.0;

    // Aplicar escala aos valores da sombra
    final double scaledBlur = isExporting ? blur : blur / scaleFactor;
    final double scaledOffsetX = isExporting ? offsetX : offsetX / scaleFactor;
    final double scaledOffsetY = isExporting ? offsetY : offsetY / scaleFactor;

    return [
      BoxShadow(
        color: _parseColor(shadow['color'] ?? '#000000'),
        blurRadius: scaledBlur,
        offset: Offset(scaledOffsetX, scaledOffsetY),
      )
    ];
  }

  Widget render(Map<String, dynamic> el) {
    final String type = el['type'];
    final double x = (el['x'] is num) ? (el['x'] as num).toDouble() : 0.0;
    final double y = (el['y'] is num) ? (el['y'] as num).toDouble() : 0.0;
    final Offset originalOffset = parentOffset + Offset(x, y);
    final Offset offset = _scaleOffset(originalOffset);

    if (type == 'group') {
      final children = (el['children'] as List)
          .cast<Map<String, dynamic>>();

      return Stack(
        children: children
            .map((child) => CanvasElementRenderer(
                  parentOffset: originalOffset,
                  canvasSize: canvasSize,
                  scaleFactor: scaleFactor,
                  isExporting: isExporting,
                ).render(child))
            .toList(),
      );
    } else if (type == 'text') {
      final dynamic maxWidthValue = el['maxWidth'];
      final dynamic fontSizeValue = el['fontSize'];
      
      final double originalMaxWidth = maxWidthValue is num 
          ? maxWidthValue.toDouble() 
          : 300.0;
      
      final double maxWidth = _scaleValue(originalMaxWidth);
      final double fontSize = fontSizeValue is num 
          ? _scaleValue(fontSizeValue.toDouble()) 
          : _scaleValue(16.0);

      return Positioned(
        left: offset.dx,
        top: offset.dy,
        child: Opacity(
          opacity: el['opacity'] is num ? (el['opacity'] as num).toDouble() : 1.0,
          child: SizedBox(
            width: maxWidth,
            child: Text(
              el['content'] ?? '',
              textAlign: _parseTextAlign(el['align']),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: _parseFontWeight(el['weight']),
                color: _parseColor(el['color'] ?? "#000000"),
                fontFamily: el['fontFamily'],
                shadows: _buildTextShadows(el['boxShadow']),
              ),
            ),
          ),
        ),
      );
    } else if (type == 'image') {
      final bool fullSize = el['fullSize'] == true;

      final dynamic widthValue = el['width'];
      final dynamic heightValue = el['height'];
      
      // Obter valores originais
      final double originalWidth = fullSize 
          ? canvasSize.width 
          : (widthValue is num) 
              ? widthValue.toDouble() 
              : 100.0;
              
      final double originalHeight = fullSize 
          ? canvasSize.height 
          : (heightValue is num) 
              ? heightValue.toDouble() 
              : 100.0;
      
      // Aplicar escala
      final double width = _scaleValue(originalWidth);
      final double height = _scaleValue(originalHeight);
              
      final Offset finalOffset = fullSize ? Offset.zero : offset;

      // Escalar offset e border radius
      final double offsetX = el['offsetX'] is num ? _scaleValue((el['offsetX'] as num).toDouble()) : 0.0;
      final double offsetY = el['offsetY'] is num ? _scaleValue((el['offsetY'] as num).toDouble()) : 0.0;

      final String? path = el['src'] as String?;
      final String fitStr = (el['fit'] ?? 'cover').toString().toLowerCase();
      final BoxFit fit = _parseBoxFit(fitStr);

      final double alignmentX = el['alignmentX'] is num ? (el['alignmentX'] as num).toDouble() : 0.0;
      final double alignmentY = el['alignmentY'] is num ? (el['alignmentY'] as num).toDouble() : 0.0;
      final Alignment alignment = Alignment(alignmentX, alignmentY);

      final double borderRadius = el['borderRadius'] is num ? _scaleValue((el['borderRadius'] as num).toDouble()) : 0.0;
      final double opacity = el['opacity'] is num ? (el['opacity'] as num).toDouble() : 1.0;
      final double? blur = el['blur'] is num ? _scaleValue((el['blur'] as num).toDouble()) : null;
      final bool grayscale = el['grayscale'] == true;

      if (path != null) {
        Widget image = Image.network(
          path,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
        );

        if (blur != null) {
          image = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: image,
          );
        }

        if (grayscale) {
          image = ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
            child: image,
          );
        }

        // Alinhar e aplicar corte se necessário
        image = Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: image,
        );

        image = ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: image,
        );

        return Positioned(
          left: finalOffset.dx,
          top: finalOffset.dy,
          child: Opacity(
            opacity: opacity,
            child: image,
          ),
        );
      }
      return const SizedBox.shrink();
    } else if (type == 'rect') {
      final dynamic widthValue = el['width'];
      final dynamic heightValue = el['height'];
      final dynamic radiusValue = el['borderRadius'];
      final dynamic borderWidthValue = el['borderWidth'];
      
      // Obter valores originais
      final double originalWidth = widthValue is num ? widthValue.toDouble() : 100.0;
      final double originalHeight = heightValue is num ? heightValue.toDouble() : 100.0;
      final double originalRadius = radiusValue is num ? radiusValue.toDouble() : 0.0;
      final double originalBorderWidth = borderWidthValue is num ? borderWidthValue.toDouble() : 0.0;
      
      // Aplicar escala
      final double width = _scaleValue(originalWidth);
      final double height = _scaleValue(originalHeight);
      final double radius = _scaleValue(originalRadius);
      final double borderWidth = _scaleValue(originalBorderWidth);
      
      final String colorHex = el['color'] ?? "#000000";
      final String borderColorHex = el['borderColor'] ?? "#000000";

      return Positioned(
        left: offset.dx,
        top: offset.dy,
        child: Opacity(
          opacity: el['opacity'] is num ? (el['opacity'] as num).toDouble() : 1.0,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _parseColor(colorHex),
              borderRadius: BorderRadius.circular(radius),
              border: borderWidth > 0
                  ? Border.all(
                      color: _parseColor(borderColorHex),
                      width: borderWidth,
                    )
                  : null,
              boxShadow: _buildBoxShadows(el['boxShadow']),
            ),      
          ),
        ),
      );
    } else if (type == 'line') {
      final dynamic widthValue = el['width'];
      final dynamic thicknessValue = el['thickness'];
      
      // Obter valores originais
      final double originalWidth = widthValue is num ? widthValue.toDouble() : 100.0;
      final double originalThickness = thicknessValue is num ? thicknessValue.toDouble() : 1.0;
      
      // Aplicar escala
      final double width = _scaleValue(originalWidth);
      final double thickness = _scaleValue(originalThickness);
      
      final String colorHex = el['color'] ?? "#000000";

      return Positioned(
        left: offset.dx,
        top: offset.dy,
        child: Container(
          width: width,
          height: thickness,
          color: _parseColor(colorHex),
        ),
      );
    } else if (type == 'circle') {
      final dynamic radiusValue = el['radius'];
      
      // Obter valor original
      final double originalRadius = radiusValue is num ? radiusValue.toDouble() : 30.0;
      
      // Aplicar escala
      final double radius = _scaleValue(originalRadius);
      
      final String colorHex = el['color'] ?? "#000000";

      return Positioned(
        left: offset.dx,
        top: offset.dy,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            color: _parseColor(colorHex),
            shape: BoxShape.circle,
          ),
        ),
      );
    } else if (type == 'icon') {
      final dynamic sizeValue = el['size'];
      
      // Obter valor original
      final double originalSize = sizeValue is num ? sizeValue.toDouble() : 24.0;
      
      // Aplicar escala
      final double size = _scaleValue(originalSize);
      
      final String iconName = el['name'] ?? "star";
      final String colorHex = el['color'] ?? "#000000";

      final iconData = _materialIcons[iconName] ?? Icons.star;

      return Positioned(
        left: offset.dx,
        top: offset.dy,
        child: Icon(iconData, size: size, color: _parseColor(colorHex)),
      );
    } else if (type == 'video') {
      final bool fullSize = el['fullSize'] == true;

      final dynamic widthValue = el['width'];
      final dynamic heightValue = el['height'];
      
      // Obter valores originais
      final double originalWidth = fullSize 
          ? canvasSize.width 
          : (widthValue is num) 
              ? widthValue.toDouble() 
              : 100.0;
              
      final double originalHeight = fullSize 
          ? canvasSize.height 
          : (heightValue is num) 
              ? heightValue.toDouble() 
              : 100.0;
      
      // Aplicar escala
      final double width = _scaleValue(originalWidth);
      final double height = _scaleValue(originalHeight);
              
      final Offset finalOffset = fullSize ? Offset.zero : offset;

      final String? url = el['src'] as String?;
      if (url == null) return const SizedBox.shrink();

      // Escalar valores de offset
      final double offsetX = el['offsetX'] is num ? _scaleValue((el['offsetX'] as num).toDouble()) : 0.0;
      final double offsetY = el['offsetY'] is num ? _scaleValue((el['offsetY'] as num).toDouble()) : 0.0;

      final double alignmentX = el['alignmentX'] is num ? (el['alignmentX'] as num).toDouble() : 0.0;
      final double alignmentY = el['alignmentY'] is num ? (el['alignmentY'] as num).toDouble() : 0.0;

      // Escalar valores visuais
      final double borderRadius = el['borderRadius'] is num ? _scaleValue((el['borderRadius'] as num).toDouble()) : 0.0;
      final double opacity = el['opacity'] is num ? (el['opacity'] as num).toDouble() : 1.0;
      final bool grayscale = el['grayscale'] == true;
      final double? blur = el['blur'] is num ? _scaleValue((el['blur'] as num).toDouble()) : null;
      final String playback = el['playback'] ?? 'loop';
      final bool muted = el['muted'] ?? false;

      return VideoElementWidget(
        url: url,
        offset: finalOffset,
        width: width,
        height: height,
        playback: playback,
        fit: _parseBoxFit(el['fit']),
        alignmentX: alignmentX,
        alignmentY: alignmentY,
        offsetX: offsetX,
        offsetY: offsetY,
        grayscale: grayscale,
        opacity: opacity,
        borderRadius: borderRadius,
        blur: blur,
        muted: muted,
      );
    }
    return const SizedBox.shrink();
  }

  // Método para obter pré-configurações de escalas para tamanhos comuns
  static double getScaleFactor(double originalWidth, double originalHeight, double displayWidth, double displayHeight) {
    // Determine um fator de escala apropriado para manter as proporções
    double widthRatio = originalWidth / displayWidth;
    double heightRatio = originalHeight / displayHeight;
    
    // Escolha o maior ratio para garantir que o conteúdo caiba dentro da tela de exibição
    return widthRatio > heightRatio ? widthRatio : heightRatio;
  }
  
  // Métodos utilitários para tamanhos comuns
  static CanvasConfig getPhoneConfig() {
    return CanvasConfig(
      originalSize: const Size(1080, 1920),
      displaySize: const Size(180, 320),
    );
  }
  
  static CanvasConfig getSquareConfig() {
    return CanvasConfig(
      originalSize: const Size(1080, 1080),
      displaySize: const Size(320, 320),
    );
  }
  
  static CanvasConfig getInstagramConfig() {
    return CanvasConfig(
      originalSize: const Size(1080, 1350),
      displaySize: const Size(256, 320),
    );
  }
}

// Classe para armazenar configurações de tamanho de canvas
class CanvasConfig {
  final Size originalSize;
  final Size displaySize;
  
  const CanvasConfig({
    required this.originalSize, 
    required this.displaySize,
  });
  
  double get scaleFactor => CanvasElementRenderer.getScaleFactor(
    originalSize.width, 
    originalSize.height, 
    displaySize.width, 
    displaySize.height
  );
  
  Map<String, dynamic> toJson() => {
    'canvas': {
      'width': originalSize.width,
      'height': originalSize.height,
      'displayWidth': displaySize.width,
      'displayHeight': displaySize.height,
    }
  };
} 
