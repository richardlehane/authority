import 'package:fluent_ui/fluent_ui.dart'
    show TextSpan, TextStyle, FontWeight, FontStyle, TextDecoration, Colors;
import 'package:xml/xml.dart'
    show XmlElement, XmlNode, XmlNodeType, XmlStringExtension;
import 'package:intl/intl.dart' show DateFormat;
import 'node.dart' show StatusType, StatusKind;

DateTime? parseDate(String? val) {
  if (val == null) return null;
  try {
    return DateTime.parse(val);
  } catch (e) {
    return null;
  }
}

final DateFormat format = DateFormat("d MMM yyyy");

String? formatDate(DateTime? dt) {
  if (dt == null) return null;
  return format.format(dt);
}

TextSpan? _id(String? control, String? content) {
  if (control == null && content == null) return null;
  if (control == null) return _toSpan(0, content!);
  if (content == null) return _toSpan(0, control);
  return _toSpan(0, "${control} ${content}");
}

mixin Render {
  String? multiGet(String name, int idx, String? sub);
  StatusType multiStatusType(int idx);
  List<XmlElement>? multiGetParagraphs(String name, int idx, String? sub);
  int termsRefLen(String name, int idx);
  String? termsRefGet(String name, int idx, int tidx);

  List<TextSpan> ids(int index) {
    String? control = multiGet("ID", index, "control");
    String? content = multiGet("ID", index, null);
    if (control == null && content == null) return [];
    return [_id(control, content)!];
  }

  List<TextSpan> linkedto(int index) {
    String? typ = multiGet("LinkedTo", index, "type");
    String? content = multiGet("LinkedTo", index, null);
    if (typ != null && content != null)
      return [_toSpan(1, typ), _toSpan(0, ": ${content}")];
    if (typ != null) return [_toSpan(1, typ)];
    if (content != null) return [_toSpan(0, content)];
    return [];
  }

  List<TextSpan> source(int index) {
    String? url = multiGet("Source", index, "url");
    String? content = multiGet("Source", index, null);
    if (url != null && content != null)
      return [
        _toSpan(2, content),
        _toSpan(0, " ("),
        _toSpan(3, url),
        _toSpan(0, ")"),
      ];
    if (url != null) return [_toSpan(3, url)];
    if (content != null) return [_toSpan(2, content)];
    return [];
  }

  List<TextSpan> comment(int index) {
    List<TextSpan> comment = [];
    String? author = multiGet("Comment", index, "author");
    List<XmlElement>? content = multiGetParagraphs("Comment", index, null);

    if (author != null) comment.add(_toSpan(1, '${author}: '));
    if (content != null) comment.addAll(_renderParas(content));
    return comment;
  }

  List<TextSpan> seereference(int index) {
    List<TextSpan> seeref = [_toSpan(0, "See")];
    String? control = multiGet("SeeReference", index, "control");
    String? content = multiGet("SeeReference", index, "IDRef");
    if (control != null || content != null)
      seeref.addAll([_toSpan(0, " "), _id(control, content)!]);
    String? title = multiGet("SeeReference", index, "AuthorityTitleRef");
    if (title != null) seeref.add(_toSpan(2, " ${title}"));
    int num = termsRefLen("SeeReference", index);
    List<String> terms = List.filled(num, "", growable: true);
    int tidx = 0;
    for (; num > 0; num--) {
      terms[tidx] = termsRefGet("SeeReference", index, tidx) ?? "";
      tidx++;
    }
    String? itemno = multiGet("SeeReference", index, "ItemNoRef");
    if (itemno != null) terms.add(itemno);
    if (terms.length > 0) seeref.add(_toSpan(1, " ${terms.join(" - ")}"));
    String? seetext = multiGet("SeeReference", index, "SeeText");
    if (seetext != null) seeref.add(_toSpan(0, " ${seetext}"));

    return seeref;
  }

  List<TextSpan> status(int index) {
    StatusType st = multiStatusType(index);
    switch (st.kind()) {
      case StatusKind.date:
        return status_date(st, index);
      default:
        return [];
    }
  }

  List<TextSpan> status_date(StatusType st, int index) {
    String? date = formatDate(parseDate(multiGet(st.toElement(), index, null)));
    if (date == null) return [_toSpan(0, st.toString())];
    return [_toSpan(0, "${st.toString()} $date")];
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
