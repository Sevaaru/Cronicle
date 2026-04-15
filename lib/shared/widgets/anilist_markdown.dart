import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';
import 'package:cronicle/shared/widgets/remote_network_image.dart';

class AnilistMarkdown extends StatelessWidget {
  const AnilistMarkdown(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = style ?? TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.5);
    final nodes = _parse(text);
    return _NodesColumn(nodes: nodes, baseStyle: base);
  }
}

class _NodesColumn extends StatelessWidget {
  const _NodesColumn({required this.nodes, required this.baseStyle});
  final List<_Node> nodes;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final widgets = <Widget>[];
    List<_Inline> buf = [];

    void flush([TextAlign tAlign = TextAlign.start]) {
      if (buf.isEmpty) return;
      widgets.add(Text.rich(
        TextSpan(children: buf.map((s) => s.toSpan(baseStyle, cs)).toList()),
        textAlign: tAlign,
      ));
      buf = [];
    }

    for (final n in nodes) {
      switch (n) {
        case _Text():
          buf.add(_Inline(text: n.text, bold: n.bold, italic: n.italic, strike: n.strike));
        case _Link():
          buf.add(_Inline(text: n.label, url: n.url));
        case _Break():
          buf.add(const _Inline(text: '\n'));
        case _Spoiler():
          flush();
          widgets.add(_SpoilerWidget(content: n.content, baseStyle: baseStyle));
        case _Image():
          flush();
          widgets.add(_ImgWidget(url: n.url, width: n.width));
        case _Center():
          flush();
          widgets.add(Center(child: _NodesColumn(nodes: n.children, baseStyle: baseStyle)));
        case _Header():
          flush();
          final sz = switch (n.level) { 1 => 22.0, 2 => 18.0, 3 => 16.0, _ => 14.0 };
          final hStyle = baseStyle.copyWith(fontSize: sz, fontWeight: FontWeight.bold, color: cs.onSurface);
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: _NodesColumn(nodes: n.children, baseStyle: hStyle),
          ));
        case _Quote():
          flush();
          widgets.add(Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: cs.primary, width: 3)),
              color: cs.surfaceContainerHighest.withAlpha(80),
            ),
            child: Text(n.text, style: baseStyle.copyWith(fontStyle: FontStyle.italic)),
          ));
        case _Hr():
          flush();
          widgets.add(Divider(height: 20, thickness: 1, color: cs.outlineVariant));
      }
    }
    flush();

    if (widgets.isEmpty) return const SizedBox.shrink();
    if (widgets.length == 1) return widgets.first;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: widgets);
  }
}

class _Inline {
  const _Inline({this.text = '', this.bold = false, this.italic = false, this.strike = false, this.url});
  final String text;
  final bool bold;
  final bool italic;
  final bool strike;
  final String? url;

  InlineSpan toSpan(TextStyle base, ColorScheme cs) {
    var s = base;
    if (bold) s = s.copyWith(fontWeight: FontWeight.bold);
    if (italic) s = s.copyWith(fontStyle: FontStyle.italic);
    if (strike) s = s.copyWith(decoration: TextDecoration.lineThrough);
    if (url != null) s = s.copyWith(color: cs.primary, decoration: TextDecoration.underline, decorationColor: cs.primary);

    if (url != null) {
      return TextSpan(
        text: text,
        style: s,
        recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
      );
    }
    return TextSpan(text: text, style: s);
  }
}

class _ImgWidget extends StatelessWidget {
  const _ImgWidget({required this.url, this.width});
  final String url;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => showFullscreenImage(context, url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: RemoteNetworkImage(
            key: ValueKey(url),
            imageUrl: url,
            width: width,
            fit: BoxFit.contain,
            error: GestureDetector(
              onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('Abrir imagen', style: TextStyle(fontSize: 12, color: cs.primary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpoilerWidget extends StatefulWidget {
  const _SpoilerWidget({required this.content, required this.baseStyle});
  final String content;
  final TextStyle baseStyle;

  @override
  State<_SpoilerWidget> createState() => _SpoilerWidgetState();
}

class _SpoilerWidgetState extends State<_SpoilerWidget> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!_revealed) {
      return GestureDetector(
        onTap: () => setState(() => _revealed = true),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_off, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Spoiler, toca para ver',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      );
    }
    final nodes = _parse(widget.content);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: _NodesColumn(nodes: nodes, baseStyle: widget.baseStyle),
    );
  }
}

// --- AST ---

sealed class _Node {}
class _Text extends _Node { _Text(this.text, {this.bold = false, this.italic = false, this.strike = false}); final String text; final bool bold, italic, strike; }
class _Link extends _Node { _Link(this.label, this.url); final String label, url; }
class _Image extends _Node { _Image(this.url, {this.width}); final String url; final double? width; }
class _Center extends _Node { _Center(this.children); final List<_Node> children; }
class _Spoiler extends _Node { _Spoiler(this.content); final String content; }
class _Break extends _Node {}
class _Hr extends _Node {}
class _Header extends _Node { _Header(this.children, this.level); final List<_Node> children; final int level; }
class _Quote extends _Node { _Quote(this.text); final String text; }

// --- Parser ---

List<_Node> _parse(String raw) {
  var text = raw
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      // Convert <h1>..<h6> HTML tags to markdown headers
      .replaceAllMapped(RegExp(r'<h([1-6])[^>]*>(.*?)</h\1>', caseSensitive: false, dotAll: true),
          (m) => '${'#' * int.parse(m.group(1)!)} ${m.group(2)}')
      .replaceAllMapped(RegExp(r'<a\s*>(.*?)</a>', dotAll: true), (m) => m.group(1) ?? '')
      .replaceAllMapped(RegExp(r'<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', dotAll: true),
          (m) => '[${m.group(2)}](${m.group(1)})')
      .replaceAll(RegExp(r'<(?:span|div|font|u)[^>]*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'</(?:span|div|font|u)>', caseSensitive: false), '');

  // Rejoin URLs broken across lines inside img(), youtube(), webm(), ![](), []()
  text = text.replaceAllMapped(
    RegExp(r'(img\d+\(https?://|!\[[^\]]*\]\(https?://|\[[^\]]*\]\(https?://|youtube\(|webm\()([^)]*)\)',
        caseSensitive: false, dotAll: true),
    (m) => '${m.group(1)}${m.group(2)!.replaceAll(RegExp(r'\s+'), '')})',
  );

  final nodes = <_Node>[];
  final lines = text.split('\n');
  final buf = StringBuffer();

  void flushBuf() {
    if (buf.isNotEmpty) {
      _parseInline(buf.toString(), nodes);
      buf.clear();
    }
  }

  int i = 0;
  while (i < lines.length) {
    final line = lines[i];

    if (RegExp(r'^\s*[-*]{3,}\s*$').hasMatch(line)) {
      flushBuf(); nodes.add(_Hr()); i++; continue;
    }

    final hm = RegExp(r'^(#{1,5})\s+(.+)$').firstMatch(line);
    if (hm != null) {
      flushBuf();
      final headerContent = hm.group(2)!.trim();
      final headerNodes = <_Node>[];
      _parseInline(headerContent, headerNodes);
      nodes.add(_Header(headerNodes, hm.group(1)!.length));
      i++; continue;
    }

    if (line.trimLeft().startsWith('>')) {
      flushBuf();
      final ql = <String>[];
      while (i < lines.length && lines[i].trimLeft().startsWith('>')) {
        ql.add(lines[i].trimLeft().replaceFirst(RegExp(r'^>+\s?'), ''));
        i++;
      }
      nodes.add(_Quote(ql.join('\n')));
      continue;
    }

    // ~~~ center blocks: handles all variants
    if (line.trimLeft().startsWith('~~~')) {
      flushBuf();
      final afterOpen = line.trimLeft().substring(3);

      // ~~~content~~~ all on one line
      if (afterOpen.trimRight().endsWith('~~~') && afterOpen.trim().length > 3) {
        final content = afterOpen.trimRight();
        nodes.add(_Center(_parse(content.substring(0, content.length - 3))));
        i++; continue;
      }

      // Multi-line: collect until closing ~~~
      final cl = <String>[];
      if (afterOpen.trim().isNotEmpty) cl.add(afterOpen);
      i++;
      while (i < lines.length) {
        final l = lines[i];
        final trimmed = l.trimRight();
        if (trimmed == '~~~') { i++; break; }
        if (trimmed.endsWith('~~~')) {
          cl.add(trimmed.substring(0, trimmed.length - 3));
          i++; break;
        }
        cl.add(l);
        i++;
      }
      nodes.add(_Center(_parse(cl.join('\n'))));
      continue;
    }

    // <center>...</center> or <p align="center">...</p>
    final centerOpenRx = RegExp(r'<(?:center|p\s+align="center")>', caseSensitive: false);
    final centerCloseRx = RegExp(r'</(?:center|p)>', caseSensitive: false);
    if (centerOpenRx.hasMatch(line)) {
      flushBuf();
      // Single-line center: <center>text</center>
      if (centerCloseRx.hasMatch(line)) {
        final inner = line
            .replaceAll(RegExp(r'</?(?:center|p\s+align="center"|p)>', caseSensitive: false), '');
        nodes.add(_Center(_parse(inner)));
        i++; continue;
      }
      final cl = <String>[line.replaceAll(centerOpenRx, '')];
      i++;
      while (i < lines.length && !centerCloseRx.hasMatch(lines[i])) {
        cl.add(lines[i]); i++;
      }
      if (i < lines.length) { cl.add(lines[i].replaceAll(centerCloseRx, '')); i++; }
      nodes.add(_Center(_parse(cl.join('\n'))));
      continue;
    }

    if (line.trim().isEmpty) {
      flushBuf(); nodes.add(_Break()); i++; continue;
    }

    buf.writeln(line);
    i++;
  }
  flushBuf();
  return nodes;
}

void _parseInline(String text, List<_Node> nodes) {
  var s = text.trim();
  if (s.isEmpty) return;

  final patterns = <(RegExp, String)>[
    // ~~~content~~~ inline center (must be before strikethrough)
    (RegExp(r'~~~(.+?)~~~'), 'inlineCenter'),
    (RegExp(r'img(\d+)\((https?://[^\)]+)\)', caseSensitive: false), 'img'),
    (RegExp(r'!\[([^\]]*)\]\((https?://[^\)]+)\)'), 'mdImg'),
    (RegExp(r'<img[^>]+src="(https?://[^"]+)"[^>]*/?>'), 'htmlImg'),
    (RegExp(r'youtube\((?:https?://(?:www\.)?youtube\.com/watch\?v=)?([a-zA-Z0-9_-]+)\)'), 'youtube'),
    (RegExp(r'webm\((https?://[^\)]+)\)'), 'webm'),
    (RegExp(r'~!(.+?)!~', dotAll: true), 'spoiler'),
    (RegExp(r'\[([^\]]+)\]\((https?://[^\)]+)\)'), 'link'),
    (RegExp(r'<a[^>]+href="(https?://[^"]+)"[^>]*>(.*?)</a>', dotAll: true), 'htmlLink'),
    (RegExp(r'<a[^>]*>(.*?)</a>', dotAll: true), 'htmlAnchorPlain'),
    (RegExp(r'<(?:b|strong)>(.*?)</(?:b|strong)>', dotAll: true), 'htmlBold'),
    (RegExp(r'<(?:i|em)>(.*?)</(?:i|em)>', dotAll: true), 'htmlItalic'),
    (RegExp(r'<(?:s|del|strike)>(.*?)</(?:s|del|strike)>', dotAll: true), 'htmlStrike'),
    (RegExp(r'(\*\*|__)(.+?)\1'), 'bold'),
    (RegExp(r'(?<![/\w])_([^_\n]+?)_(?![/\w])'), 'italic'),
    (RegExp(r'(?<!\w)\*([^*\n]+?)\*(?!\w)'), 'italicStar'),
    (RegExp(r'(?<!~)~~(?!~)(.+?)(?<!~)~~(?!~)'), 'strike'),
  ];

  while (s.isNotEmpty) {
    Match? best;
    String? type;

    for (final (rx, t) in patterns) {
      final m = rx.firstMatch(s);
      if (m != null && (best == null || m.start < best.start)) { best = m; type = t; }
    }

    if (best == null) { _addPlainText(s, nodes); break; }

    if (best.start > 0) _addPlainText(s.substring(0, best.start), nodes);

    switch (type) {
      case 'inlineCenter':
        final inner = <_Node>[];
        _parseInline(best.group(1)!, inner);
        nodes.add(_Center(inner));
      case 'img': nodes.add(_Image(best.group(2)!, width: double.tryParse(best.group(1)!)));
      case 'mdImg': nodes.add(_Image(best.group(2)!));
      case 'htmlImg': nodes.add(_Image(best.group(1)!));
      case 'youtube': nodes.add(_Link('▶ YouTube', 'https://www.youtube.com/watch?v=${best.group(1)!}'));
      case 'webm': nodes.add(_Link('▶ Video', best.group(1)!));
      case 'spoiler': nodes.add(_Spoiler(best.group(1)!));
      case 'link': nodes.add(_Link(best.group(1)!, best.group(2)!));
      case 'htmlLink': nodes.add(_Link(best.group(2)!, best.group(1)!));
      case 'htmlAnchorPlain': nodes.add(_Text(best.group(1)!));
      case 'htmlBold': nodes.add(_Text(best.group(1)!, bold: true));
      case 'htmlItalic': nodes.add(_Text(best.group(1)!, italic: true));
      case 'htmlStrike': nodes.add(_Text(best.group(1)!, strike: true));
      case 'bold': nodes.add(_Text(best.group(2)!, bold: true));
      case 'italic': nodes.add(_Text(best.group(1)!, italic: true));
      case 'italicStar': nodes.add(_Text(best.group(1)!, italic: true));
      case 'strike': nodes.add(_Text(best.group(1)!, strike: true));
    }
    s = s.substring(best.end);
  }
}

void _addPlainText(String raw, List<_Node> nodes) {
  // Strip remaining HTML tags but keep their inner text
  final cleaned = raw.replaceAll(RegExp(r'<[^>]*>'), '');
  if (cleaned.isEmpty) return;

  final urlRx = RegExp(r'(https?://[^\s<>\)\]]+)');
  var t = cleaned;
  while (true) {
    final m = urlRx.firstMatch(t);
    if (m == null) { if (t.isNotEmpty) nodes.add(_Text(t)); break; }
    if (m.start > 0) nodes.add(_Text(t.substring(0, m.start)));
    nodes.add(_Link(m.group(1)!, m.group(1)!));
    t = t.substring(m.end);
  }
}
