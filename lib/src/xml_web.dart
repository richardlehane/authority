import 'package:xml/xml.dart';
import 'package:fluent_ui/fluent_ui.dart'
    show TreeViewItem, Text, FluentIcons, Icon;
import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'counter.dart';
import 'node.dart' show NodeType;

const String _template = '''
<?xml version="1.0" encoding="UTF-8"?>
<Authority xmlns="http://www.records.nsw.gov.au/schemas/RDA">
	<Term itemno="1.0.0" type="function">
    <Term itemno="1.1.0" type="activity">
      <Class itemno="1.1.1" />
		</Term>
	</Term>
</Authority>
''';

class Session {
  List<XmlDocument> documents = [];
  List<XmlElement?> nodes = [];

  // singleton
  Session._();
  static final Session _instance = Session._();
  factory Session() => _instance;

  int _init(XmlDocument doc) {
    documents.add(doc);
    nodes.add(nth(doc, 0));
    return documents.length - 1;
  }

  int empty() {
    XmlDocument doc = XmlDocument.parse(_template);
    return _init(doc);
  }

  int load(PlatformFile f) {
    if (f.bytes == null) {
      return empty();
    }
    final doc = XmlDocument.parse(String.fromCharCodes(f.bytes!));
    return _init(doc);
  }

  List<TreeViewItem> tree(int index, Counter ctr) =>
      addChildren(termsClasses(documents[index].rootElement), ctr);

  String asString(int index) =>
      documents[index].toXmlString(pretty: true, indent: '\t');

  void setCurrent(int index, int n) {
    nodes[index] = nth(documents[index], n);
  }

  // tree operations
  void remove(int index, int n) {
    XmlElement? el = nth(documents[index], n);
    if (el == null) {
      return;
    }
    el.remove();
  }

  // node operations
  String getElement(int index, String name) {
    XmlElement? el = nodes[index];
    if (el == null) return "";
    XmlElement? t = el.getElement(name);
    if (t != null) {
      return t.innerText;
    }
    return "";
  }

  String getAttribute(int index, String name) {
    XmlElement? el = nodes[index];
    if (el == null) return "";
    String? a = el.getAttribute(
      name,
      namespace: "http://www.records.nsw.gov.au/schemas/RDA",
    );
    return (a != null) ? a : "";
  }

  void setElement(int index, String name, String value) {
    XmlElement? el = nodes[index];
    if (el == null) return;
    XmlElement? t = el.getElement(name);
    // delete
    if (value == "") {
      if (t != null) el.children.remove(t);
      return;
    }
    // update
    if (t != null) {
      t.innerText = value;
      return;
    }
    // insert
    NodeType typ = (el.name.local == "Term")
        ? NodeType.termType
        : NodeType.classType;
    t = XmlElement(XmlName(name), [], [XmlText(value)], false);
    int p = insertPos(el, typ, name);
    el.children.insert(p, t);
    return;
  }

  void setAttribute(int index, String name, String value) {
    XmlElement? el = nodes[index];
    if (el == null) return;
    String? a = (value == "") ? null : value;
    el.setAttribute(
      name,
      a,
      namespace: "http://www.records.nsw.gov.au/schemas/RDA",
    );
    return;
  }

  List<XmlElement>? getParagraphs(int index, String name) {
    XmlElement? el = nodes[index];
    if (el == null) return null;
    XmlElement? parent = el.getElement(name);
    if (parent == null) return null;
    return parent.findElements("Paragraph").toList();
  }

  void setParagraphs(int index, String name, List<XmlElement> paras) {
    XmlElement? el = nodes[index];
    if (el == null) return;
    XmlElement? parent = el.getElement(name);
    if (parent == null) {
      // inserting
      parent = XmlElement(XmlName(name), [], paras, false);
      NodeType typ = (el.name.local == "Term")
          ? NodeType.termType
          : NodeType.classType;
      int p = insertPos(el, typ, name);
      el.children.insert(p, parent);
      return;
    }
    parent.children.removeWhere(
      (para) =>
          para.nodeType == XmlNodeType.ELEMENT &&
          (para as XmlElement).name.local == "Paragraph",
    );
    parent.children.insertAll(0, paras);
  }

  // multi operations
}

List<TreeViewItem> addChildren(List<XmlElement> list, Counter ctr) {
  return list.map((item) {
    final NodeType nt = (item.name.local == 'Term')
        ? NodeType.termType
        : NodeType.classType;
    final int index = ctr.next();
    final bool selected = ctr.isSelected();
    return TreeViewItem(
      leading: (nt == NodeType.termType)
          ? Icon(FluentIcons.fabric_folder)
          : Icon(FluentIcons.page),
      content: Text(title(item)),
      value: (nt, index),
      children: addChildren(termsClasses(item), ctr),
      selected: selected,
    );
  }).toList();
}

List<XmlElement> termsClasses(XmlElement el) {
  if (el.name.local == 'Class') {
    return [];
  }
  return el.childElements
      .where((e) => e.name.local == 'Term' || e.name.local == 'Class')
      .toList();
}

String title(XmlElement el) {
  String? itemno = el.getAttribute("itemno");
  XmlElement? t = (el.name.local == 'Class')
      ? el.getElement('ClassTitle')
      : el.getElement('TermTitle');
  return (itemno != null)
      ? (t != null)
            ? "$itemno ${t.innerText}"
            : itemno
      : (t != null)
      ? t.innerText
      : '';
}

XmlElement? nth(XmlDocument? doc, int n) {
  int idx = -1;
  XmlElement? descend(XmlElement el) {
    for (XmlElement child in el.childElements.where(
      (e) => e.name.local == 'Term' || e.name.local == 'Class',
    )) {
      idx++;
      if (idx == n) {
        return child;
      }
      if (child.name.local == 'Term') {
        var ret = descend(child);
        if (ret != null) {
          return ret;
        }
      }
    }
    return null;
  }

  if (doc == null) {
    return null;
  }
  return descend(doc.rootElement);
}

// Constants to maintain element order
// Also, after Comments Term or Class elements can be nested
const termElements = [
  "ID",
  "TermTitle",
  "TermDescription",
  "DateRange",
  "Status",
  "LinkedTo", // multiple
  "Comment", // multiple
];

const classElements = [
  "ID",
  "ClassTitle",
  "ClassDescription",
  "Disposal", // multiple
  "Justification",
  "DateRange",
  "Status",
  "LinkedTo", // multiple
  "Comment", // multiple
];

// determine where to insert a new element
int insertPos(XmlElement el, NodeType typ, String name) {
  int pos = 0;
  List<String> prev = (typ == NodeType.termType) ? termElements : classElements;
  prev = prev.sublist(0, prev.indexOf(name));
  for (var n in el.children) {
    if (n.nodeType != XmlNodeType.ELEMENT ||
        prev.contains((n as XmlElement).name.local)) {
      pos++;
      continue;
    }
    return pos;
  }
  return pos;
}
