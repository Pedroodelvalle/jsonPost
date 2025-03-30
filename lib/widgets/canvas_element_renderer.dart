import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_element_widget.dart';

Color _parseColor(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) hexColor = 'FF$hexColor';
  else if (hexColor.length == 3) {
    // Converte formato simplificado #RGB para #RRGGBB
    final r = hexColor[0];
    final g = hexColor[1];
    final b = hexColor[2];
    hexColor = 'FF$r$r$g$g$b$b';
  }
  try {
    return Color(int.parse('0x$hexColor'));
  } catch (e) {
    return Colors.black; // Cor padrão em caso de erro
  }
}

FontWeight _parseFontWeight(String? weight) {
  switch (weight?.toLowerCase()) {
    case 'thin':
      return FontWeight.w100;
    case 'extralight':
      return FontWeight.w200;
    case 'light':
      return FontWeight.w300;
    case 'regular':
      return FontWeight.w400;
    case 'medium':
      return FontWeight.w500;
    case 'semibold':
      return FontWeight.w600;
    case 'bold':
      return FontWeight.bold;
    case 'extrabold':
      return FontWeight.w800;
    case 'black':
      return FontWeight.w900;
    case 'normal':
      return FontWeight.normal;
    default:
      return FontWeight.normal;
  }
}

TextAlign _parseTextAlign(String? align) {
  switch (align?.toLowerCase()) {
    case 'center':
      return TextAlign.center;
    case 'right':
      return TextAlign.right;
    case 'justify':
      return TextAlign.justify;
    case 'left':
    default:
      return TextAlign.left;
  }
}

TextDecoration _parseTextDecoration(String? decoration) {
  switch (decoration?.toLowerCase()) {
    case 'underline':
      return TextDecoration.underline;
    case 'overline':
      return TextDecoration.overline;
    case 'linethrough':
      return TextDecoration.lineThrough;
    default:
      return TextDecoration.none;
  }
}

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

List<Shadow>? _buildTextShadows(Map<String, dynamic>? shadow) {
  if (shadow == null) return null;

  return [
    Shadow(
      color: _parseColor(shadow['color'] ?? '#000000'),
      blurRadius: shadow['blur'] is num ? (shadow['blur'] as num).toDouble() : 0.0,
      offset: Offset(
        shadow['offsetX'] is num ? (shadow['offsetX'] as num).toDouble() : 0.0,
        shadow['offsetY'] is num ? (shadow['offsetY'] as num).toDouble() : 0.0,
      ),
    )
  ];
}

List<BoxShadow>? _buildBoxShadows(Map<String, dynamic>? shadow) {
  if (shadow == null) return null;

  return [
    BoxShadow(
      color: _parseColor(shadow['color'] ?? '#000000'),
      blurRadius: shadow['blur'] is num ? (shadow['blur'] as num).toDouble() : 0.0,
      offset: Offset(
        shadow['offsetX'] is num ? (shadow['offsetX'] as num).toDouble() : 0.0,
        shadow['offsetY'] is num ? (shadow['offsetY'] as num).toDouble() : 0.0,
      ),
    )
  ];
}

ColorFilter? _applyFilter(String? filter) {
  if (filter == null) return null;
  
  switch (filter.toLowerCase()) {
    case 'grayscale':
      return const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    case 'sepia':
      return const ColorFilter.matrix([
        0.393, 0.769, 0.189, 0, 0,
        0.349, 0.686, 0.168, 0, 0,
        0.272, 0.534, 0.131, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    case 'vintage':
      return const ColorFilter.matrix([
        0.9, 0.5, 0.1, 0, 0,
        0.3, 0.8, 0.1, 0, 0,
        0.2, 0.3, 0.5, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    default:
      return null;
  }
}

final Map<String, IconData> _materialIcons = {
  "star": Icons.star,
  "heart": Icons.favorite,
  "home": Icons.home,
  "settings": Icons.settings,
  "search": Icons.search,
  "arrow": Icons.arrow_forward,
  "check": Icons.check,
  "close": Icons.close,
  "play": Icons.play_arrow,
  "pause": Icons.pause,
  "share": Icons.share,
  "delete": Icons.delete,
  "edit": Icons.edit,
  "camera": Icons.camera_alt,
  "photo": Icons.photo,
  "person": Icons.person,
};

class CanvasElementRenderer {
  final Offset parentOffset;
  final Size canvasSize;
  final Color backgroundColor;

  const CanvasElementRenderer({
    this.parentOffset = Offset.zero,
    required this.canvasSize,
    this.backgroundColor = Colors.white,
  });  

  Widget render(Map<String, dynamic> el) {
    final String type = el['type'];
    final double x = el['x'] is num ? (el['x'] as num).toDouble() : 0.0;
    final double y = el['y'] is num ? (el['y'] as num).toDouble() : 0.0;
    final Offset offset = parentOffset + Offset(x, y);
    
    // Zindex para organização de camadas
    final int zIndex = el['zIndex'] is num ? (el['zIndex'] as num).toInt() : 0;
    
    // Propriedade de rotação comum a vários elementos
    final double rotation = el['rotation'] is num ? (el['rotation'] as num).toDouble() : 0.0;

    Widget element;

    if (type == 'group') {
      final children = (el['children'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      element = Stack(
        children: children
            .map((child) => CanvasElementRenderer(
                  parentOffset: offset,
                  canvasSize: canvasSize,
                  backgroundColor: backgroundColor,
                ).render(child))
            .toList(),
      );
    } else if (type == 'text') {
      element = _renderText(el, offset);
    } else if (type == 'image') {
      element = _renderImage(el, offset);
    } else if (type == 'rect') {
      element = _renderRect(el, offset);
    } else if (type == 'line') {
      element = _renderLine(el, offset);
    } else if (type == 'circle') {
      element = _renderCircle(el, offset);
    } else if (type == 'icon') {
      element = _renderIcon(el, offset);
    } else if (type == 'video') {
      element = _renderVideo(el, offset);
    } else {
      return const SizedBox.shrink();
    }

    // Aplicar rotação se especificada e retornar o widget posicionado
    if (rotation != 0) {
      element = Transform.rotate(
        angle: rotation * 3.14159 / 180, // Converte graus para radianos
        child: element,
      );
    }

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: element,
    );
  }

  Widget _renderText(Map<String, dynamic> el, Offset offset) {
    final dynamic maxWidthValue = el['maxWidth'];
    final dynamic fontSizeValue = el['fontSize'];
    final dynamic lineHeightValue = el['lineHeight'];
    final dynamic letterSpacingValue = el['letterSpacing'];
    
    final double maxWidth = maxWidthValue is num 
        ? maxWidthValue.toDouble() 
        : 300.0;
    
    final double fontSize = fontSizeValue is num ? fontSizeValue.toDouble() : 16.0;
    final double lineHeight = lineHeightValue is num ? lineHeightValue.toDouble() : 1.2;
    final double letterSpacing = letterSpacingValue is num ? letterSpacingValue.toDouble() : 0.0;

    // Verifica se há spans para texto avançado
    final dynamic spans = el['spans'];
    
    if (spans is List && spans.isNotEmpty) {
      // Renderização com spans para estilos avançados
      List<InlineSpan> textSpans = [];
      
      for (final span in spans) {
        final String text = span['text'] ?? '';
        final String? color = span['color'];
        final String? weight = span['weight'];
        final String? decoration = span['textDecoration'];
        final String? background = span['background'];
        final dynamic spanLetterSpacing = span['letterSpacing'];
        
        final TextStyle spanStyle = TextStyle(
          color: color != null ? _parseColor(color) : Colors.black,
          fontSize: fontSize,
          fontWeight: _parseFontWeight(weight),
          fontFamily: el['fontFamily'],
          height: lineHeight,
          letterSpacing: spanLetterSpacing is num ? spanLetterSpacing.toDouble() : letterSpacing,
          decoration: _parseTextDecoration(decoration),
          backgroundColor: background != null ? _parseColor(background) : null,
          shadows: _buildTextShadows(el['boxShadow']),
        );
        
        textSpans.add(TextSpan(
          text: text,
          style: spanStyle,
        ));
      }
      
      return Opacity(
        opacity: el['opacity'] is num ? (el['opacity'] as num).toDouble() : 1.0,
        child: Container(
          width: maxWidth,
          child: RichText(
            text: TextSpan(
              children: textSpans,
            ),
            textAlign: _parseTextAlign(el['textAlign']),
            overflow: TextOverflow.clip,
          ),
        ),
      );
    } else {
      // Renderização simples sem spans
      return Opacity(
        opacity: el['opacity'] is num ? (el['opacity'] as num).toDouble() : 1.0,
        child: Container(
          width: maxWidth,
          child: Text(
            el['content'] ?? '',
            textAlign: _parseTextAlign(el['textAlign'] ?? el['align']),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: _parseFontWeight(el['weight']),
              color: _parseColor(el['color'] ?? "#000000"),
              fontFamily: el['fontFamily'],
              height: lineHeight,
              letterSpacing: letterSpacing,
              decoration: _parseTextDecoration(el['textDecoration']),
              shadows: _buildTextShadows(el['boxShadow']),
            ),
          ),
        ),
      );
    }
  }

  Widget _renderImage(Map<String, dynamic> el, Offset offset) {
    final bool fullSize = el['fullSize'] == true;

    final dynamic widthValue = el['width'];
    final dynamic heightValue = el['height'];
    
    final double width = fullSize 
        ? canvasSize.width 
        : (widthValue is num) 
            ? widthValue.toDouble() 
            : 100.0;
            
    final double height = fullSize 
        ? canvasSize.height 
        : (heightValue is num) 
            ? heightValue.toDouble() 
            : 100.0;
            
    final double offsetX = el['offsetX'] is num ? (el['offsetX'] as num).toDouble() : 0.0;
    final double offsetY = el['offsetY'] is num ? (el['offsetY'] as num).toDouble() : 0.0;

    final String? path = el['src'] as String?;
    final String fitStr = (el['fit'] ?? 'cover').toString().toLowerCase();
    final BoxFit fit = _parseBoxFit(fitStr);

    final double alignmentX = el['alignmentX'] is num ? (el['alignmentX'] as num).toDouble() : 0.0;
    final double alignmentY = el['alignmentY'] is num ? (el['alignmentY'] as num).toDouble() : 0.0;
    final Alignment alignment = Alignment(alignmentX, alignmentY);

    final double borderRadius = el['borderRadius'] is num ? (el['borderRadius'] as num).toDouble() : 0.0;
    final double borderWidth = el['borderWidth'] is num ? (el['borderWidth'] as num).toDouble() : 0.0;
    final String? borderColor = el['borderColor'] as String?;
    
    final double opacity = el['opacity'] is num ? (el['opacity'] as num).toDouble() : 1.0;
    final double? blur = el['blur'] is num ? (el['blur'] as num).toDouble() : null;
    final bool grayscale = el['grayscale'] == true;
    final String? filter = el['filter'] as String?;

    if (path == null) return const SizedBox.shrink();

    Widget image = Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
    );

    // Aplicar filtros
    if (filter != null) {
      final ColorFilter? colorFilter = _applyFilter(filter);
      if (colorFilter != null) {
        image = ColorFiltered(
          colorFilter: colorFilter,
          child: image,
        );
      }
    } else if (grayscale) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: image,
      );
    }

    if (blur != null) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: image,
      );
    }

    // Aplicar borda se necessário
    if (borderWidth > 0 && borderColor != null) {
      image = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: _parseColor(borderColor),
            width: borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: image,
        ),
      );
    } else {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }

    // Aplicar deslocamento
    if (offsetX != 0 || offsetY != 0) {
      image = Transform.translate(
        offset: Offset(offsetX, offsetY),
        child: image,
      );
    }

    return Opacity(
      opacity: opacity,
      child: image,
    );
  }

  Widget _renderRect(Map<String, dynamic> el, Offset offset) {
    final dynamic widthValue = el['width'];
    final dynamic heightValue = el['height'];
    final dynamic radiusValue = el['borderRadius'];
    final dynamic borderWidthValue = el['borderWidth'];
    
    final double width = widthValue is num ? widthValue.toDouble() : 100.0;
    final double height = heightValue is num ? heightValue.toDouble() : 100.0;
    final double radius = radiusValue is num ? radiusValue.toDouble() : 0.0;
    final double borderWidth = borderWidthValue is num ? borderWidthValue.toDouble() : 0.0;
    final String colorHex = el['color'] ?? "#000000";
    final String borderColorHex = el['borderColor'] ?? "#000000";

    return Opacity(
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
    );
  }

  Widget _renderLine(Map<String, dynamic> el, Offset offset) {
    final dynamic widthValue = el['width'];
    final dynamic thicknessValue = el['thickness'];
    
    final double width = widthValue is num ? widthValue.toDouble() : 100.0;
    final double thickness = thicknessValue is num ? thicknessValue.toDouble() : 1.0;
    final String colorHex = el['color'] ?? "#000000";

    return Container(
      width: width,
      height: thickness,
      color: _parseColor(colorHex),
    );
  }

  Widget _renderCircle(Map<String, dynamic> el, Offset offset) {
    final dynamic widthValue = el['width'];
    final dynamic heightValue = el['height'];
    final dynamic radiusValue = el['radius'];
    final dynamic borderWidthValue = el['borderWidth'];
    
    // Suporta tanto width/height quanto raio direto
    double diameter;
    if (radiusValue is num) {
      diameter = radiusValue.toDouble() * 2;
    } else {
      // Se width e height forem fornecidos, usamos o menor valor para manter um círculo
      final double width = widthValue is num ? widthValue.toDouble() : 60.0;
      final double height = heightValue is num ? heightValue.toDouble() : 60.0;
      diameter = width < height ? width : height;
    }
    
    final double borderWidth = borderWidthValue is num ? borderWidthValue.toDouble() : 0.0;
    final String colorHex = el['color'] ?? "#000000";
    final String borderColorHex = el['borderColor'] ?? "#000000";

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: _parseColor(colorHex),
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(
                color: _parseColor(borderColorHex),
                width: borderWidth,
              )
            : null,
        boxShadow: _buildBoxShadows(el['boxShadow']),
      ),
    );
  }

  Widget _renderIcon(Map<String, dynamic> el, Offset offset) {
    final dynamic sizeValue = el['size'];
    final double size = sizeValue is num ? sizeValue.toDouble() : 24.0;
    final String iconName = el['name'] ?? "star";
    final String colorHex = el['color'] ?? "#000000";

    final iconData = _materialIcons[iconName] ?? Icons.star;

    return Icon(
      iconData, 
      size: size, 
      color: _parseColor(colorHex),
    );
  }

  Widget _renderVideo(Map<String, dynamic> el, Offset offset) {
    final bool fullSize = el['fullSize'] == true;
    final bool preserveAspectRatio = el['preserveAspectRatio'] == true;

    final dynamic widthValue = el['width'];
    final dynamic heightValue = el['height'];
    
    final double width = fullSize 
        ? canvasSize.width 
        : (widthValue is num) 
            ? widthValue.toDouble() 
            : 100.0;
            
    final double height = fullSize 
        ? canvasSize.height 
        : (heightValue is num) 
            ? heightValue.toDouble() 
            : 100.0;

    final String? url = el['src'] as String?;
    if (url == null) return const SizedBox.shrink();

    final double offsetX = el['offsetX'] is num ? (el['offsetX'] as num).toDouble() : 0.0;
    final double offsetY = el['offsetY'] is num ? (el['offsetY'] as num).toDouble() : 0.0;

    final double alignmentX = el['alignmentX'] is num ? (el['alignmentX'] as num).toDouble() : 0.0;
    final double alignmentY = el['alignmentY'] is num ? (el['alignmentY'] as num).toDouble() : 0.0;

    final double borderRadius = el['borderRadius'] is num ? (el['borderRadius'] as num).toDouble() : 0.0;
    final double borderWidth = el['borderWidth'] is num ? (el['borderWidth'] as num).toDouble() : 0.0;
    final String? borderColor = el['borderColor'] as String?;
    
    final double opacity = el['opacity'] is num ? (el['opacity'] as num).toDouble() : 1.0;
    final bool grayscale = el['grayscale'] == true;
    final double? blur = el['blur'] is num ? (el['blur'] as num).toDouble() : null;
    final String playback = el['playback'] ?? 'loop';
    final bool muted = el['muted'] ?? false;

    return VideoElementWidget(
      url: url,
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
      preserveAspectRatio: preserveAspectRatio,
      borderWidth: borderWidth,
      borderColor: borderColor != null ? _parseColor(borderColor) : null,
    );
  }
} 
