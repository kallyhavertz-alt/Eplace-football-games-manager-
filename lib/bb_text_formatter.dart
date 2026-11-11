import 'package:flutter/material.dart';

/// 🎨 Global Logic for BBCode-style formatting [b], [r], [g]
class BBTextFormatter {
  static Widget parseToRichText(
    BuildContext context, 
    String input, {
    double fontSize = 13.0, 
    double height = 1.3, 
    TextAlign textAlign = TextAlign.start,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
    Color? color,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultColor = color ?? (isDark ? Colors.white70 : Colors.black87);
    
    final Color blueColor = isDark ? Colors.lightBlueAccent : const Color(0xFF0D47A1);
    final Color redColor = isDark ? Colors.redAccent : const Color(0xFFC62828);
    final Color greenColor = isDark ? Colors.greenAccent : const Color(0xFF2E7D32);

    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'\[([brg])\](.*?)\[\/\1\]|([^\[]+)', dotAll: true);
    final Iterable<Match> matches = regExp.allMatches(input);

    for (final Match match in matches) {
      if (match.group(3) != null) {
        spans.add(TextSpan(text: match.group(3), style: TextStyle(color: defaultColor, fontSize: fontSize, height: height)));
      } else {
        final String? tag = match.group(1);
        final String textContent = match.group(2) ?? '';
        Color targetColor = defaultColor;
        FontWeight weight = FontWeight.normal;

        if (tag == 'b') { targetColor = blueColor; weight = FontWeight.bold; }
        else if (tag == 'r') { targetColor = redColor; weight = FontWeight.bold; }
        else if (tag == 'g') { targetColor = greenColor; weight = FontWeight.bold; }

        spans.add(TextSpan(
          text: textContent, 
          style: TextStyle(color: targetColor, fontWeight: weight, fontSize: fontSize, height: height)
        ));
      }
    }
    
    if (spans.isEmpty && input.isNotEmpty) {
       return Text(
         input, 
         style: TextStyle(color: defaultColor, fontSize: fontSize, height: height), 
         textAlign: textAlign,
         maxLines: maxLines,
         overflow: overflow,
       );
    }
    
    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(children: spans)
    );
  }
}

/// 🎨 Optimized Text Widget with Read More support
class BBText extends StatefulWidget {
  final String text;
  final int charLimit;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;

  const BBText({
    Key? key, 
    required this.text, 
    this.charLimit = 40,
    this.fontSize = 13.0,
    this.color,
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  /// 🛠️ Helper to strip tags for plain text sharing
  static String removeTags(String input) {
    return input.replaceAll(RegExp(r'\[\/?([brg])\]'), '');
  }

  @override
  State<BBText> createState() => _BBTextState();
}

class _BBTextState extends State<BBText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String displayStr = widget.text;
    
    // If text is short enough, just render normally
    if (displayStr.length <= widget.charLimit) {
      return BBTextFormatter.parseToRichText(
        context, 
        displayStr, 
        fontSize: widget.fontSize, 
        color: widget.color,
        textAlign: widget.textAlign,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BBTextFormatter.parseToRichText(
          context, 
          _isExpanded ? displayStr : "${displayStr.substring(0, widget.charLimit)}...",
          fontSize: widget.fontSize,
          color: widget.color,
          textAlign: widget.textAlign,
        ),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _isExpanded ? "Read less" : "Read more",
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 🎨 Custom Controller that parses [b], [r], [g] tags into inline native UI colors while typing!
class VividEditingController extends TextEditingController {
  final BuildContext context;
  VividEditingController({required this.context, String? text}) : super(text: text);

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultColor = style?.color ?? (isDark ? Colors.white70 : Colors.black87);

    final Color blueColor = isDark ? Colors.lightBlueAccent : const Color(0xFF0D47A1);
    final Color redColor = isDark ? Colors.redAccent : const Color(0xFFC62828);
    final Color greenColor = isDark ? Colors.greenAccent : const Color(0xFF2E7D32);

    final List<TextSpan> children = [];
    final RegExp regExp = RegExp(r'(\[[brg]\])|(\[\/[brg]\])|([^\[]+)', dotAll: true);
    final Iterable<Match> matches = regExp.allMatches(text);

    for (final Match match in matches) {
      if (match.group(1) != null) {
        children.add(TextSpan(
          text: match.group(1),
          style: style?.copyWith(color: Colors.transparent, fontSize: 0.1) ?? 
                 const TextStyle(color: Colors.transparent, fontSize: 0.1),
        ));
      } else if (match.group(2) != null) {
        children.add(TextSpan(
          text: match.group(2),
          style: style?.copyWith(color: Colors.transparent, fontSize: 0.1) ?? 
                 const TextStyle(color: Colors.transparent, fontSize: 0.1),
        ));
      } else {
        final String partText = match.group(3)!;
        final int partStart = match.start;
        final String textBefore = text.substring(0, partStart);
        
        final int lastOpenB = textBefore.lastIndexOf('[b]');
        final int lastCloseB = textBefore.lastIndexOf('[/b]');
        final int lastOpenR = textBefore.lastIndexOf('[r]');
        final int lastCloseR = textBefore.lastIndexOf('[/r]');
        final int lastOpenG = textBefore.lastIndexOf('[g]');
        final int lastCloseG = textBefore.lastIndexOf('[/g]');

        Color targetColor = defaultColor;
        FontWeight weight = FontWeight.normal;

        if (lastOpenB > lastCloseB) { targetColor = blueColor; weight = FontWeight.bold; }
        else if (lastOpenR > lastCloseR) { targetColor = redColor; weight = FontWeight.bold; }
        else if (lastOpenG > lastCloseG) { targetColor = greenColor; weight = FontWeight.bold; }

        children.add(TextSpan(
          text: partText,
          style: style?.copyWith(color: targetColor, fontWeight: weight) ??
                 TextStyle(color: targetColor, fontWeight: weight),
        ));
      }
    }
    return TextSpan(style: style, children: children.isEmpty ? [TextSpan(text: text)] : children);
  }
}
