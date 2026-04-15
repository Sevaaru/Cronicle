import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';

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
          buf.add(const _Inline(text: '[Spoiler]', italic: true));
        case _Image():
          flush();
          widgets.add(_ImgWidget(url: n.url, width: n.width));
        case _Center():
          flush();
          widgets.add(Center(child: _NodesColumn(nodes: n.children, baseStyle: baseStyle)));
        case _Header():
          flush();
          final sz = switch (n.level) { 1 => 22.0, 2 => 18.0, 3 => 16.0, _ => 14.0 };
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text(n.text, style: baseStyle.copyWith(fontSize: sz, fontWeight: FontWeight.bold, color: cs.onSurface)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => showFullscreenImage(context, url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            width: width,
            fit: BoxFit.contain,
            placeholder: (_, _) => SizedBox(
              width: width ?? 200, height: 80,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, _, _) => const Icon(Icons.broken_image, size: 32),
          ),
        ),
      ),
    );
  }
}

// --- AST ---

sealed class _Node {}
class _Text extends _Node { _Text(this.text, {this.bold = false, this.italic = false, this.strike = false}); final String text; final bool bold, italic, strike; }
class _Link extends _Node { _Link(this.label, this.url); final String label, url; }
class _Image extends _Node { _Image(this.url, {this.width}); final String url; final double? width; }
class _Center extends _Node { _Center(this.children); final List<_Node> children; }
class _Spoiler extends _Node {}
class _Break extends _Node {}
class _Hr extends _Node {}
class _Header extends _Node { _Header(this.text, this.level); final String text; final int level; }
class _Quote extends _Node { _Quote(this.text); final String text; }

// --- Parser ---

List<_Node> _parse(String raw) {
  var text = raw
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");

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
      flushBuf(); nodes.add(_Header(hm.group(2)!.trim(), hm.group(1)!.length)); i++; continue;
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

    if (line.trim() == '~~~') {
      flushBuf();
      final cl = <String>[];
      i++;
      while (i < lines.length && lines[i].trim() != '~~~') { cl.add(lines[i]); i++; }
      if (i < lines.length) i++;
      nodes.add(_Center(_parse(cl.join('\n'))));
      continue;
    }

    // <center>...</center> or <p align="center">...</p>
    final centerOpenRx = RegExp(r'<(?:center|p\s+align="center")>', caseSensitive: false);
    final centerCloseRx = RegExp(r'</(?:center|p)>', caseSensitive: false);
    if (centerOpenRx.hasMatch(line)) {
      flushBuf();
      final cl = <String>[line.replaceAll(RegExp(r'</?(?:center|p\s+align="center"|p)>', caseSensitive: false), '')];
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
    (RegExp(r'img(\d+)\((https?://[^\)]+)\)'), 'img'),
    (RegExp(r'!\[([^\]]*)\]\((https?://[^\)]+)\)'), 'mdImg'),
    (RegExp(r'<img[^>]+src="(https?://[^"]+)"[^>]*/?>'), 'htmlImg'),
    (RegExp(r'youtube\((?:https?://(?:www\.)?youtube\.com/watch\?v=)?([a-zA-Z0-9_-]+)\)'), 'youtube'),
    (RegExp(r'webm\((https?://[^\)]+)\)'), 'webm'),
    (RegExp(r'~!(.+?)!~', dotAll: true), 'spoiler'),
    (RegExp(r'\[([^\]]+)\]\((https?://[^\)]+)\)'), 'link'),
    (RegExp(r'<a[^>]+href="(https?://[^"]+)"[^>]*>([^<]+)</a>'), 'htmlLink'),
    (RegExp(r'<(?:b|strong)>(.*?)</(?:b|strong)>', dotAll: true), 'htmlBold'),
    (RegExp(r'<(?:i|em)>(.*?)</(?:i|em)>', dotAll: true), 'htmlItalic'),
    (RegExp(r'<(?:s|del|strike)>(.*?)</(?:s|del|strike)>', dotAll: true), 'htmlStrike'),
    (RegExp(r'(\*\*|__)(.+?)\1'), 'bold'),
    (RegExp(r'~~(.+?)~~'), 'strike'),
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
      case 'img': nodes.add(_Image(best.group(2)!, width: double.tryParse(best.group(1)!)));
      case 'mdImg': nodes.add(_Image(best.group(2)!));
      case 'htmlImg': nodes.add(_Image(best.group(1)!));
      case 'youtube': nodes.add(_Link('▶ YouTube', 'https://www.youtube.com/watch?v=${best.group(1)!}'));
      case 'webm': nodes.add(_Link('▶ Video', best.group(1)!));
      case 'spoiler': nodes.add(_Spoiler());
      case 'link': nodes.add(_Link(best.group(1)!, best.group(2)!));
      case 'htmlLink': nodes.add(_Link(best.group(2)!, best.group(1)!));
      case 'htmlBold': nodes.add(_Text(best.group(1)!, bold: true));
      case 'htmlItalic': nodes.add(_Text(best.group(1)!, italic: true));
      case 'htmlStrike': nodes.add(_Text(best.group(1)!, strike: true));
      case 'bold': nodes.add(_Text(best.group(2)!, bold: true));
      case 'strike': nodes.add(_Text(best.group(1)!, strike: true));
    }
    s = s.substring(best.end);
  }
}

void _addPlainText(String raw, List<_Node> nodes) {
  final cleaned = raw.replaceAll(RegExp(r'<[^>]+>'), '');
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
