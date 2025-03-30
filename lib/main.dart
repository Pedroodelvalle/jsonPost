import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/json.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'widgets/canvas_element_renderer.dart';

class Template {
  final String name;
  final String json;

  Template({required this.name, required this.json});

  Map<String, dynamic> toJson() => {
    'name': name,
    'json': json,
  };

  factory Template.fromJson(Map<String, dynamic> json) => Template(
    name: json['name'],
    json: json['json'],
  );
}

class TemplateManager {
  static const String _storageKey = 'canvas_templates';
  static final TemplateManager _instance = TemplateManager._internal();
  factory TemplateManager() => _instance;
  TemplateManager._internal();

  Future<List<Template>> getTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? templatesJson = prefs.getString(_storageKey);
    if (templatesJson == null) return [];

    final List<dynamic> templatesList = jsonDecode(templatesJson);
    return templatesList.map((json) => Template.fromJson(json)).toList();
  }

  Future<void> saveTemplate(Template template) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await getTemplates();
    templates.add(template);
    
    final templatesJson = jsonEncode(templates.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, templatesJson);
  }

  Future<void> deleteTemplate(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await getTemplates();
    templates.removeWhere((t) => t.name == name);
    
    final templatesJson = jsonEncode(templates.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, templatesJson);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CanvasEditor(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CanvasEditor extends StatefulWidget {
  const CanvasEditor({super.key});

  @override
  State<CanvasEditor> createState() => _CanvasEditorState();
}

class _CanvasEditorState extends State<CanvasEditor> {
  double canvasWidth = 360;
  double canvasHeight = 640;
  double originalWidth = 1080; // Dimensão original em alta resolução
  double originalHeight = 1920; // Dimensão original em alta resolução
  bool isExporting = false; // Controla se estamos no modo de exportação
  CanvasConfig canvasConfig = CanvasElementRenderer.getPhoneConfig(); // Configuração padrão
  final GlobalKey _canvasKey = GlobalKey();

  List<Map<String, dynamic>> elements = [];
  late CodeController _codeController;
  String? jsonErrorMessage;
  final TemplateManager _templateManager = TemplateManager();
  List<Template> _templates = [];
  bool _showTemplates = false;
  
  // Calcula o fator de escala atual
  double get scaleFactor => canvasConfig.scaleFactor;
  
  // Dimensões de exibição (reduzidas para edição)
  double get displayWidth => canvasConfig.displaySize.width;
  double get displayHeight => canvasConfig.displaySize.height;

  @override
  void initState() {
    super.initState();
    _loadTemplates();

    const defaultJson = {
      "canvas": {
        "width": 1080,
        "height": 1920,
        "displayWidth": 180,
        "displayHeight": 320
      },
      "elements": [
        {
          "type": "rect",
          "x": 20,
          "y": 80,
          "width": 300,
          "height": 100,
          "color": "#EEEEEE",
          "borderRadius": 10,
          "borderWidth": 2,
          "borderColor": "#EA3E0A",
          "boxShadow": {
            "color": "#000000",
            "blur": 4,
            "offsetX": 2,
            "offsetY": 2
          },
          "zIndex": 0
        },
        {
          "type": "image",
          "src": "https://videos.openai.com/vg-assets/assets%2Ftask_01jq9shwswfy89m1ztbvaafcyg%2Fimg_1.webp?st=2025-03-27T09%3A50%3A18Z&se=2025-04-02T10%3A50%3A18Z&sks=b&skt=2025-03-27T09%3A50%3A18Z&ske=2025-04-02T10%3A50%3A18Z&sktid=a48cca56-e6da-484e-a814-9c849652bcb3&skoid=aa5ddad1-c91a-4f0a-9aca-e20682cc8969&skv=2019-02-02&sv=2018-11-09&sr=b&sp=r&spr=https%2Chttp&sig=lx6N%2FV1dC0o2DDUpwrppweaxxJow%2FerQpEZAJUskPp0%3D&az=oaivgprodscus",
          "x": 1,
          "y": 1,
          "width": 30,
          "height": 30,
          "fit": "cover",
          "fullSize": false,
          "alignmentX": 0,
          "alignmentY": 0,
          "borderRadius": 0,
          "opacity": 1,
          "grayscale": false,
          "blur": 0,
          "zIndex": 0
        },
        {
          "type": "text",
          "content": "Texto centralizado",
          "x": 30,
          "y": 100,
          "fontSize": 20,
          "fontFamily": "Arial",
          "weight": "bold",
          "maxWidth": 300,
          "align": "center",
          "color": "#2984F6",
          "opacity": 1,
          "boxShadow": {
            "color": "#000000",
            "blur": 0,
            "offsetX": 0,
            "offsetY": 0
          },
          "zIndex": 0
        },
        {
          "type": "line",
          "x": 20,
          "y": 300,
          "width": 300,
          "thickness": 2,
          "color": "#888888",
          "zIndex": 0
        },
        {
          "type": "circle",
          "x": 150,
          "y": 400,
          "radius": 40,
          "color": "#2984F6",
          "zIndex": 0
        },
        {
          "type": "icon",
          "x": 160,
          "y": 630,
          "name": "star",
          "size": 36,
          "color": "#FFCC00",
          "zIndex": 1
        }
      ]
    };

    final formattedJson = const JsonEncoder.withIndent('  ').convert(defaultJson);
    _codeController = CodeController(
      text: formattedJson,
      language: json,
    );

    _updateElementsFromJson(formattedJson);
  }

  Future<void> _loadTemplates() async {
    final templates = await _templateManager.getTemplates();
    setState(() {
      _templates = templates;
    });
  }

  Future<void> _saveTemplate() async {
    final nameController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvar Template'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome do Template',
            hintText: 'Digite um nome para o template',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final template = Template(
                  name: nameController.text,
                  json: _codeController.text,
                );
                await _templateManager.saveTemplate(template);
                await _loadTemplates();
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _loadTemplate(Template template) {
    setState(() {
      _codeController.text = template.json;
      _updateElementsFromJson(template.json);
      _showTemplates = false;
    });
  }

  void _updateElementsFromJson(String jsonString) {
    try {
      final parsed = jsonDecode(jsonString);

      if (parsed is! Map) {
        setState(() {
          jsonErrorMessage = "O JSON precisa ser um objeto com as propriedades 'canvas' e 'elements'.";
        });
        return;
      }

      // Atualiza as dimensões do canvas
      if (parsed['canvas'] != null && parsed['canvas'] is Map) {
        final canvasConfig = parsed['canvas'] as Map;
        setState(() {
          // Dimensões originais (alta resolução)
          originalWidth = (canvasConfig['width'] as num?)?.toDouble() ?? 1080;
          originalHeight = (canvasConfig['height'] as num?)?.toDouble() ?? 1920;
          
          // Dimensões de exibição (reduzidas para edição)
          canvasWidth = (canvasConfig['displayWidth'] as num?)?.toDouble() ?? 
                        (originalWidth / 6); // Default display scale of 1/6
          canvasHeight = (canvasConfig['displayHeight'] as num?)?.toDouble() ?? 
                         (originalHeight / 6); // Default display scale of 1/6
          
          // Atualiza a configuração
          this.canvasConfig = CanvasConfig(
            originalSize: Size(originalWidth, originalHeight),
            displaySize: Size(canvasWidth, canvasHeight),
          );
        });
      }

      // Atualiza os elementos
      if (parsed['elements'] == null || parsed['elements'] is! List) {
        setState(() {
          jsonErrorMessage = "O JSON precisa conter a propriedade 'elements' com uma lista.";
        });
        return;
      }

      final elementsList = parsed['elements'] as List;
      for (var el in elementsList) {
        if (el is! Map || !el.containsKey('type')) {
          setState(() {
            jsonErrorMessage = "Cada elemento precisa conter a chave 'type'.";
          });
          return;
        }

        if (el['type'] == 'group') {
          if (el['children'] == null || el['children'] is! List) {
            setState(() {
              jsonErrorMessage = "Um grupo precisa conter a chave 'children' com uma lista.";
            });
            return;
          }
        }
      }

      // Se chegou aqui, está tudo certo
      setState(() {
        jsonErrorMessage = null;
        elements = List<Map<String, dynamic>>.from(elementsList);
      });
    } catch (e) {
      setState(() {
        jsonErrorMessage = "Erro ao interpretar o JSON: ${e.toString()}";
      });
    }
  }

  void _formatJson() {
    try {
      final jsonString = _codeController.text;
      final parsed = jsonDecode(jsonString);
      
      // Garante que o objeto canvas está presente com dimensions originais e de exibição
      if (parsed is Map && !parsed.containsKey('canvas')) {
        parsed['canvas'] = {
          'width': originalWidth,
          'height': originalHeight,
          'displayWidth': displayWidth,
          'displayHeight': displayHeight
        };
      } else if (parsed is Map && parsed.containsKey('canvas')) {
        final canvas = parsed['canvas'] as Map;
        if (!canvas.containsKey('displayWidth')) {
          canvas['displayWidth'] = displayWidth;
        }
        if (!canvas.containsKey('displayHeight')) {
          canvas['displayHeight'] = displayHeight;
        }
      }
      
      final formattedJson = const JsonEncoder.withIndent('  ').convert(parsed);
      _codeController.text = formattedJson;
      _updateElementsFromJson(formattedJson);
    } catch (e) {
      setState(() {
        jsonErrorMessage = "Erro ao formatar JSON: ${e.toString()}";
      });
    }
  }

  Future<void> _exportToPNG() async {
    try {
      // Antes de exportar, define que estamos no modo de exportação
      setState(() {
        isExporting = true;
      });
      
      // Mostra diálogo para selecionar a qualidade
      final quality = await showDialog<double>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            // Mova a variável para fora do builder
            final qualityController = ValueNotifier<double>(3.0);
            
            return ValueListenableBuilder<double>(
              valueListenable: qualityController,
              builder: (context, selectedQuality, _) {
                return AlertDialog(
                  title: const Text('Exportar como PNG'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Selecione a qualidade da imagem:'),
                      const SizedBox(height: 16),
                      Slider(
                        value: selectedQuality,
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        label: '${selectedQuality}x',
                        onChanged: (value) {
                          qualityController.value = value;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Qualidade: ${selectedQuality}x (${(selectedQuality * selectedQuality * 100).round()}% do tamanho original)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, selectedQuality),
                      child: const Text('Exportar'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );

      if (quality == null) return; // Usuário cancelou

      // Captura a imagem usando RenderRepaintBoundary
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: quality);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        Uint8List imageBytes = byteData.buffer.asUint8List();
        
        // Obtém o diretório de documentos do aplicativo
        final appDir = await getApplicationDocumentsDirectory();
        
        // Cria um nome único para o arquivo
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = "canvas_${quality}x_$timestamp.png";
        final file = File('${appDir.path}/$fileName');
        
        // Salva o arquivo
        await file.writeAsBytes(imageBytes);

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Imagem Exportada'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('A imagem foi salva com sucesso!'),
                  const SizedBox(height: 8),
                  Text('Caminho: ${file.path}', 
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Qualidade: ${quality}x (${(quality * quality * 100).round()}% do tamanho original)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  const Text('Você pode encontrar a imagem no diretório de documentos do aplicativo.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar a imagem: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      // Após exportar, voltamos ao modo de edição
      setState(() {
        isExporting = false;
      });
    }
  }

  void _changeCanvasFormat(CanvasConfig newConfig) {
    setState(() {
      canvasConfig = newConfig;
      originalWidth = newConfig.originalSize.width;
      originalHeight = newConfig.originalSize.height;
      canvasWidth = newConfig.displaySize.width;
      canvasHeight = newConfig.displaySize.height;
      
      // Atualiza o JSON
      final jsonString = _codeController.text;
      try {
        final parsed = jsonDecode(jsonString);
        if (parsed is Map && parsed.containsKey('canvas')) {
          parsed['canvas'] = {
            'width': originalWidth,
            'height': originalHeight,
            'displayWidth': canvasWidth,
            'displayHeight': canvasHeight
          };
          
          final updatedJson = const JsonEncoder.withIndent('  ').convert(parsed);
          _codeController.text = updatedJson;
          _updateElementsFromJson(updatedJson);
        }
      } catch (e) {
        // Ignora erros de parse aqui
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse('0x$hexColor'));
  }

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

  BoxFit _parseBoxFit(String? fit) {
    switch (fit?.toLowerCase()) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'fitwidth':
        return BoxFit.fitWidth;
      case 'fitheight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaledown':
        return BoxFit.scaleDown;
      case 'fill':
      default:
        return BoxFit.fill;
    }
  }

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

  List<Shadow>? _buildTextShadows(Map<String, dynamic>? shadow) {
    if (shadow == null) return null;

    return [
      Shadow(
        color: _parseColor(shadow['color'] ?? '#000000'),
        blurRadius: (shadow['blur'] as num?)?.toDouble() ?? 0.0,
        offset: Offset(
          (shadow['offsetX'] as num?)?.toDouble() ?? 0.0,
          (shadow['offsetY'] as num?)?.toDouble() ?? 0.0,
        ),
      )
    ];
  }

  List<BoxShadow>? _buildBoxShadows(Map<String, dynamic>? shadow) {
    if (shadow == null) return null;

    return [
      BoxShadow(
        color: _parseColor(shadow['color'] ?? '#000000'),
        blurRadius: (shadow['blur'] as num?)?.toDouble() ?? 0.0,
        offset: Offset(
          (shadow['offsetX'] as num?)?.toDouble() ?? 0.0,
          (shadow['offsetY'] as num?)?.toDouble() ?? 0.0,
        ),
      )
    ];
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
    // adicione mais conforme quiser
  };

  Widget _buildTemplatesPanel() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Templates Salvos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showTemplates = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return ListTile(
                  title: Text(template.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await _templateManager.deleteTemplate(template.name);
                      await _loadTemplates();
                    },
                  ),
                  onTap: () => _loadTemplate(template),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Visual com JSON'),
        actions: [
          // Adiciona dropdown para selecionar formatos comuns de canvas
          PopupMenuButton<CanvasConfig>(
            tooltip: 'Formato do Canvas',
            icon: const Icon(Icons.aspect_ratio),
            onSelected: _changeCanvasFormat,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: CanvasElementRenderer.getPhoneConfig(),
                child: const Text('Celular (1080x1920)'),
              ),
              PopupMenuItem(
                value: CanvasElementRenderer.getSquareConfig(),
                child: const Text('Quadrado (1080x1080)'),
              ),
              PopupMenuItem(
                value: CanvasElementRenderer.getInstagramConfig(),
                child: const Text('Instagram (1080x1350)'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTemplate,
            tooltip: 'Salvar Template',
          ),
          IconButton(
            icon: const Icon(Icons.format_align_left),
            onPressed: _formatJson,
            tooltip: 'Formatar JSON',
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () => setState(() => _showTemplates = !_showTemplates),
            tooltip: 'Templates Salvos',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToPNG,
            tooltip: 'Exportar como PNG',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 1200;
          
          if (_showTemplates) {
            return _buildTemplatesPanel();
          }
          
          if (isDesktop) {
            return Row(
              children: [
                // Editor JSON na esquerda
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("JSON de entrada (edite abaixo):"),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: CodeTheme(
                                    data: CodeThemeData(
                                      styles: {
                                        'comment': const TextStyle(color: Colors.grey),
                                        'keyword': const TextStyle(color: Colors.blue),
                                        'string': const TextStyle(color: Colors.green),
                                        'number': const TextStyle(color: Colors.orange),
                                        'punctuation': const TextStyle(color: Colors.grey),
                                      },
                                    ),
                                    child: CodeField(
                                      controller: _codeController,
                                      textStyle: const TextStyle(fontFamily: 'Courier', fontSize: 14),
                                      wrap: false,
                                      lineNumberStyle: LineNumberStyle(
                                        textStyle: TextStyle(color: Colors.grey.shade700),
                                      ),
                                      onChanged: (text) {
                                        setState(() {
                                          _updateElementsFromJson(text);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (jsonErrorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    jsonErrorMessage!,
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Canvas na direita
                Expanded(
                  flex: 1,
                  child: Center(
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: Container(
                        width: isExporting ? originalWidth : canvasWidth,
                        height: isExporting ? originalHeight : canvasHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Builder(
                          builder: (_) {
                            final sortedElements = [...elements];
                            sortedElements.sort((a, b) {
                              final aZ = (a['zIndex'] ?? 0) as num;
                              final bZ = (b['zIndex'] ?? 0) as num;
                              return aZ.compareTo(bZ);
                            });

                            return Stack(
                              children: sortedElements
                                  .map((el) => CanvasElementRenderer(
                                      canvasSize: Size(originalWidth, originalHeight),
                                      scaleFactor: scaleFactor,
                                      isExporting: isExporting,
                                    ).render(el))
                                  .toList(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Layout vertical para telas menores
            return Column(
              children: [
                // Editor JSON em cima
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("JSON de entrada (edite abaixo):"),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: CodeTheme(
                                    data: CodeThemeData(
                                      styles: {
                                        'comment': const TextStyle(color: Colors.grey),
                                        'keyword': const TextStyle(color: Colors.blue),
                                        'string': const TextStyle(color: Colors.green),
                                        'number': const TextStyle(color: Colors.orange),
                                        'punctuation': const TextStyle(color: Colors.grey),
                                      },
                                    ),
                                    child: CodeField(
                                      controller: _codeController,
                                      textStyle: const TextStyle(fontFamily: 'Courier', fontSize: 14),
                                      wrap: false,
                                      lineNumberStyle: LineNumberStyle(
                                        textStyle: TextStyle(color: Colors.grey.shade700),
                                      ),
                                      onChanged: (text) {
                                        setState(() {
                                          _updateElementsFromJson(text);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (jsonErrorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    jsonErrorMessage!,
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Canvas embaixo
                Expanded(
                  flex: 2,
                  child: Center(
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: Container(
                        width: isExporting ? originalWidth : canvasWidth,
                        height: isExporting ? originalHeight : canvasHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Builder(
                          builder: (_) {
                            final sortedElements = [...elements];
                            sortedElements.sort((a, b) {
                              final aZ = (a['zIndex'] ?? 0) as num;
                              final bZ = (b['zIndex'] ?? 0) as num;
                              return aZ.compareTo(bZ);
                            });

                            return Stack(
                              children: sortedElements
                                  .map((el) => CanvasElementRenderer(
                                      canvasSize: Size(originalWidth, originalHeight),
                                      scaleFactor: scaleFactor,
                                      isExporting: isExporting,
                                    ).render(el))
                                  .toList(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
