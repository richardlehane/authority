import 'package:fluent_ui/fluent_ui.dart'
    show TextSpan, TextStyle, FontWeight, FontStyle, TextDecoration, Colors;
import 'package:xml/xml.dart'
    show XmlElement, XmlNode, XmlNodeType, XmlStringExtension;

mixin Render {
  String? multiGet(String name, int idx, String? sub);
  List<XmlElement>? multiGetParagraphs(String name, int idx, String? sub);

  List<TextSpan> comment(int index) {
    List<TextSpan> comment = [];
    String? author = multiGet("Comment", index, "author");
    List<XmlElement>? content = multiGetParagraphs("Comment", index, null);

    if (author != null) comment.add(_toSpan(1, '${author}: '));
    if (content != null) comment.addAll(_renderParas(content));
    return comment;
  }

  List<TextSpan> disposal(int index) {
    List<TextSpan> action = [];

    String? condition = multiGet("Disposal", index, "DisposalCondition");
    String? retentionPeriod = multiGet("Disposal", index, "RetentionPeriod");
    String? retentionUnit = multiGet("Disposal", index, "unit");
    String? trigger = multiGet("Disposal", index, "DisposalTrigger");
    String? disposalAction = multiGet("Disposal", index, "DisposalAction");
    String? transferTo = multiGet("Disposal", index, "TransferTo");
    if (transferTo != null) transferTo = " to ${transferTo}";
    List<XmlElement>? customAction = multiGetParagraphs(
      "Disposal",
      index,
      "CustomAction",
    );

    String retention(String? period, String? unit, String? trigger) {
      if (period == null && trigger == null) return "";
      if (period == null) return "until ${trigger}";
      if (unit == null) unit = "years"; // should not reach
      String ret = (unit == "1")
          ? "${period} ${unit.substring(0, unit.length - 1)}"
          : "${period} ${unit}";
      if (trigger == null) return "minimum of ${ret}";
      return "minimum of ${ret} after ${trigger}";
    }

    String ret = retention(retentionPeriod, retentionUnit, trigger);
    switch (disposalAction) {
      case null:
        break;
      case "Required as State archives":
        action.add(_toSpan(0, disposalAction));
      case "Destroy":
        action.add(
          _toSpan(0, (ret.isEmpty) ? "Destroy" : "Retain ${ret}, then destroy"),
        );
      case "Transfer":
        action.add(
          _toSpan(
            0,
            (ret.isEmpty)
                ? "Transfer${transferTo}"
                : "Retain ${ret}, then transfer${transferTo}",
          ),
        );
      default: // "Retain in agency"
        action.add(_toSpan(0, disposalAction));
    }
    if (customAction != null) {
      if (action.isNotEmpty) action.add(_toSpan(0, '\n'));
      action.addAll(_renderParas(customAction));
    }
    if (condition != null) {
      action.insert(0, _toSpan(1, '${condition}:\n'));
    }
    return action;
  }
}

const bullet = "\u2022";
List<TextSpan> _renderParas(List<XmlElement> paragraphs) {
  StringBuffer buf = StringBuffer();
  List<TextSpan> ret = [];

  int _getStyle(XmlNode node) {
    if (node.nodeType != XmlNodeType.ELEMENT) return 0;
    switch ((node as XmlElement).name.local) {
      case "List":
        return -1;
      case "Emphasis":
        return 1;
      case "Source":
        if (node.getAttribute("url") == null) return 2;
        return 3;
    }
    return 0;
  }

  void _commitNode(XmlNode node, int style) {
    String txt = (node.nodeType == XmlNodeType.TEXT)
        ? node.value!
        : node.innerText;
    if (txt.trim().isEmpty) return; // kill blank text nodes
    if (style == 0) {
      buf.write(txt);
      return;
    }
    if (buf.length > 0) {
      ret.add(_toSpan(0, buf.toString()));
      buf.clear();
    }
    ret.add(_toSpan(style, txt));
    return;
  }

  bool first = true;
  for (var para in paragraphs) {
    if (first) {
      first = false;
    } else {
      buf.write("\n");
    }
    bool nl = true;
    for (var child in para.children) {
      int style = _getStyle(child);
      if (style < 0) {
        for (var item in child.children) {
          if (!nl) {
            buf.write("\n");
          }
          buf.write("$bullet ");
          for (var node in item.children) {
            style = _getStyle(node);
            _commitNode(node, style);
            nl = false;
          }
        }
      } else {
        _commitNode(child, style);
        nl = false;
      }
    }
  }
  if (buf.length > 0) {
    ret.add(_toSpan(0, buf.toString()));
  }
  return ret;
}

// Create textspans with style
TextSpan _toSpan(int style, String text) {
  switch (style) {
    case 0:
      return TextSpan(text: text);
    case 1:
      return TextSpan(
        style: TextStyle(fontWeight: FontWeight.bold),
        text: text,
      );
    case 2:
      return TextSpan(
        style: TextStyle(fontStyle: FontStyle.italic),
        text: text,
      );
    default:
      return TextSpan(
        style: TextStyle(
          decoration: TextDecoration.underline,
          color: Colors.blue,
        ),
        text: text,
      );
  }
}
