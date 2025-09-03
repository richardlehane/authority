import 'package:xml/xml.dart';
import 'package:fluent_ui/fluent_ui.dart' show TreeViewItem;
import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'node.dart' show NodeType, nodeFromString;
import 'tree.dart' show makeItem, Counter;

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

const String _ns = "http://www.records.nsw.gov.au/schemas/RDA";

class Session {
  List<XmlDocument> documents = [];
  List<XmlElement?> nodes = [];

  // singleton
  Session._();
  static final Session _instance = Session._();
  factory Session() => _instance;

  int _init(XmlDocument doc) {
    documents.add(doc);
    nodes.add(nth(doc, 0, NodeType.termType));
    return documents.length - 1;
  }

  int empty() {
    XmlDocument doc = XmlDocument.parse(_template);
    return _init(doc);
  }

  int load(PlatformFile f) {
    // todo: error handling
    if (f.bytes == null) {
      return empty();
    }
    final doc = XmlDocument.parse(String.fromCharCodes(f.bytes!));
    return _init(doc);
  }

  List<TreeViewItem> tree(int index, Counter ctr) {
    ctr.next(NodeType.rootType);
    List<TreeViewItem> ret = [
      makeItem(0, NodeType.rootType, ctr.isSelected(), null, "Details", []),
      makeItem(
        0,
        NodeType.none,
        false,
        null,
        "Context",
        _addContext(documents[index].rootElement, ctr),
      ),
    ];
    ret.addAll(_addChildren(termsClasses(documents[index].rootElement), ctr));
    return ret;
  }

  String asString(int index) =>
      documents[index].toXmlString(pretty: true, indent: '\t');

  void setCurrent(int index, int n, NodeType nt) {
    // todo: authority/ context nodes
    nodes[index] = nth(documents[index], n, nt);
  }

  // tree operations
  void dropNode(int index, int n, NodeType nt) {
    XmlElement? el = nth(documents[index], n, nt);
    if (el == null) return;
    el.remove();
  }

  void addContext(int index) {
    XmlElement root = documents[index].rootElement;
    (int, int) p = insertPos(root, "Context");
    root.children.insert(p.$1, XmlElement(XmlName("Context")));
    return;
  }

  void addChild(int index, int n, NodeType nt) {
    XmlElement? el = nth(documents[index], n, nt);
    if (el == null) return;
    el.children.add(XmlElement(XmlName(nt.toString())));
  }

  void addSibling(int index, int n, NodeType nt) {
    XmlElement? el = nth(documents[index], n, nt);
    if (el == null) return;
    el.parentElement!.children.insert(
      _pos(el) + 1,
      XmlElement(XmlName(nt.toString())),
    );
  }

  void moveUp(int index, int n, NodeType nt) {
    XmlElement? el = nth(documents[index], n, nt);
    if (el == null) return;
    XmlElement? prev = el.previousElementSibling;
    if (prev == null || !nt.like(nodeFromString(prev.localName))) return;
    el.remove();
    prev.parentElement!.children.insert(_pos(prev), el);
  }

  void moveDown(int index, int n, NodeType nt) {
    XmlElement? el = nth(documents[index], n, nt);
    if (el == null) return;
    XmlElement? next = el.nextElementSibling;
    if (next == null || !nt.like(nodeFromString(next.localName))) return;
    el.remove();
    next.parentElement!.children.insert(_pos(next) + 1, el);
  }

  // find the index of the sibling node within its parent by counting previous siblings
  int _pos(XmlNode el) {
    int ret = 0;
    while (el.previousSibling != null) {
      ret++;
      el = el.previousSibling!;
    }
    return ret;
  }

  // todo: move up/ move down

  // node operations
  NodeType getType(int index) {
    XmlElement? el = nodes[index];
    if (el == null) return NodeType.rootType;
    return nodeFromString(el.localName);
  }

  String? getElement(int index, String name) {
    XmlElement? el = nodes[index];
    if (el == null) return null;
    XmlElement? t = el.getElement(name);
    return (t != null) ? t.innerText : null;
  }

  String? getAttribute(int index, String name) {
    XmlElement? el = nodes[index];
    if (el == null) return null;
    String? a = el.getAttribute(name, namespace: _ns);
    return (a != null) ? a : null;
  }

  void setElement(int index, String name, String? value) {
    XmlElement? el = nodes[index];
    if (el == null) return;
    XmlElement? t = el.getElement(name);
    // delete
    if (value == null) {
      if (t != null) el.children.remove(t);
      return;
    }
    // update
    if (t != null) {
      t.innerText = value;
      return;
    }
    // insert
    t = XmlElement(XmlName(name), [], [XmlText(value)], false);
    (int, int) p = insertPos(el, name);
    el.children.insert(p.$1, t);
    return;
  }

  void setAttribute(int index, String name, String? value) {
    XmlElement? el = nodes[index];
    if (el == null) return;
    el.setAttribute(name, value, namespace: _ns);
    return;
  }

  List<XmlElement>? getParagraphs(int index, String name) {
    XmlElement? el = nodes[index];
    if (el == null) return null;
    XmlElement? parent = el.getElement(name);
    if (parent == null) return null;
    return parent.findElements("Paragraph").toList();
  }

  // todo: delete empty parent??
  void setParagraphs(int index, String name, List<XmlElement>? paras) {
    XmlElement? el = nodes[index];
    if (el == null) return;
    XmlElement? parent = el.getElement(name);
    if (parent == null) {
      if (paras == null) return;
      // inserting
      parent = XmlElement(XmlName(name), [], paras, false);
      (int, int) p = insertPos(el, name);
      el.children.insert(p.$1, parent);
      return;
    }
    parent.children.removeWhere(
      (para) =>
          para.nodeType == XmlNodeType.ELEMENT &&
          (para as XmlElement).localName == "Paragraph",
    );
    if (paras == null) {
      // todo: check if parent is empty now, if so remove it too
      return;
    }
    parent.children.insertAll(0, paras);
  }

  // multi operations
  int multiLen(int index, String name) {
    XmlElement? el = nodes[index];
    if (el == null) return 0;
    if (name == "Status") {
      el = el.getElement("Status");
      if (el == null) return 0;
      return el.childElements.length;
    }
    if (name == "SeeReference") {
      el = (el.name.local == "Term")
          ? el.getElement("TermDescription")
          : el.getElement("ClassDescription");
      if (el == null) return 0;
    }
    return el.findElements(name).length;
  }

  int multiAdd(int index, String name, String? sub) {
    XmlElement? el = nodes[index];
    if (el == null) return 0;
    // todo: special case Status and SeeReference - SeeReference uses the sub parameter
    XmlElement t = XmlElement(XmlName(name), [], [], false);
    (int, int) p = insertPos(el, name);
    el.children.insert(p.$1, t);
    return p.$2; // todo
  }

  void multiSet(int index, String name, int idx, String? sub, String? val) {
    XmlElement? el = nodes[index];
    if (el == null) return;
    // todo: Status and SeeReference
    el = el.findElements(name).elementAt(idx);
    if (sub == "unit") {
      XmlElement? t = el.getElement("RetentionPeriod");
      String? a = (val == "") ? null : val;
      if (t == null) {
        t = XmlElement(XmlName("RetentionPeriod"), [], [], false);
        (int, int) p = insertPos(el, "RetentionPeriod");
        el.children.insert(p.$1, t);
      }
      t.setAttribute("unit", a, namespace: _ns);
      return;
    }
    if (sub != null) {
      XmlElement? t = el.getElement(sub);
      // delete
      if (val == null) {
        if (t != null) el.children.remove(t);
        return;
      }
      // update
      if (t != null) {
        t.innerText = val;
        return;
      }
      // insert
      t = XmlElement(XmlName(sub), [], [XmlText(val)], false);
      (int, int) p = insertPos(el, sub);
      el.children.insert(p.$1, t);
      return;
    }
    if (val == null) return; // can't drop multi with null value
    el.innerText = val;
    return;
  }

  String? multiGet(int index, String name, int idx, String? sub) {
    XmlElement? el = nodes[index];
    if (el == null) return null;
    el = el.findElements(name).elementAt(idx);
    if (sub == null) return el.innerText; // handle simple case - e.g. LinkedTo
    if (sub == "unit") {
      XmlElement? t = el.getElement("RetentionPeriod");
      if (t == null) return null;
      String? a = t.getAttribute(sub, namespace: _ns);
      return (a != null) ? a : null;
    }
    XmlElement? t = el.getElement(sub);
    if (t == null) return null;
    return t.innerText.isEmpty ? null : t.innerText;
  }

  List<XmlElement>? multiGetParagraphs(
    int index,
    String name,
    int idx,
    String? sub,
  ) {
    XmlElement? el = nodes[index];
    if (el == null) return null;
    el = el.findElements(name).elementAt(idx);
    if (sub != null) {
      el = el.getElement(sub);
      if (el == null) return null;
    }
    List<XmlElement> l = el.findElements("Paragraph").toList();
    return l.isEmpty ? null : l;
  }

  // todo: delete empty parent??
  void multiSetParagraphs(
    int index,
    String name,
    int idx,
    String? sub,
    List<XmlElement>? val,
  ) {
    XmlElement? el = nodes[index];
    if (el == null) return null;
    el = el.findElements(name).elementAt(idx);
    XmlElement parent = el;
    if (sub != null) {
      el = el.getElement(sub);
    }
    if (el == null) {
      if (val == null) return;
      // inserting
      el = XmlElement(XmlName(sub!), [], val, false);
      (int, int) p = insertPos(parent, sub);
      parent.children.insert(p.$1, el);
      return;
    }
    el.children.removeWhere(
      (para) =>
          para.nodeType == XmlNodeType.ELEMENT &&
          (para as XmlElement).localName == "Paragraph",
    );
    // delete
    if (val == null) {
      if (el.children.isEmpty) el.remove();
      return;
    }
    el.children.insertAll(0, val); // update
  }
}

List<TreeViewItem> _addContext(XmlElement root, Counter ctr) {
  return root.findElements("Context").map((item) {
    final int index = ctr.next(NodeType.contextType);
    final bool selected = ctr.isSelected();
    return makeItem(
      index,
      NodeType.contextType,
      selected,
      null,
      item.getElement("ContextTitle")?.innerText,
      [],
    );
  }).toList();
}

List<TreeViewItem> _addChildren(List<XmlElement> list, Counter ctr) {
  return list.map((item) {
    final NodeType nt = (item.name.local == 'Term')
        ? NodeType.termType
        : NodeType.classType;
    final int index = ctr.next(nt);
    final bool selected = ctr.isSelected();
    return makeItem(
      index,
      nt,
      selected,
      item.getAttribute("itemno"),
      nt == NodeType.termType
          ? item.getAttribute('TermTitle')
          : item.getElement('ClassTitle')?.innerText,
      _addChildren(termsClasses(item), ctr),
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

XmlElement? nth(XmlDocument? doc, int n, NodeType nt) {
  switch (nt) {
    case NodeType.none:
      return null;
    case NodeType.rootType:
      return doc?.rootElement;
    case NodeType.contextType:
      return nthContext(doc, n);
    default:
      return nthTermClass(doc, n);
  }
}

XmlElement? nthContext(XmlDocument? doc, int n) {
  return doc?.rootElement.findElements("Context").elementAt(n);
}

XmlElement? nthTermClass(XmlDocument? doc, int n) {
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
// after contexts, Term or Class elements can be nested
const authorityElements = [
  "ID",
  "AuthorityTitle",
  "Scope",
  "DateRange",
  "Status",
  "LinkedTo",
  "Comment",
  "Context",
];

const contextElements = ["ContextTitle", "ContextContent", "Comment"];

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

// Also, after Comments Term or Class elements can be nested
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

const disposalElements = [
  "DisposalCondition",
  "RetentionPeriod",
  "DisposalTrigger",
  "DisposalAction",
  "TransferTo",
  "CustomAction",
  "CustomCustody",
];

// determine where to insert a new element
(int, int) insertPos(XmlElement el, String name) {
  int pos = 0;
  int multi = 0;
  List<String> prev = switch (el.localName) {
    "Authority" => authorityElements,
    "Context" => contextElements,
    "Term" => termElements,
    "Class" => classElements,
    "Disposal" => disposalElements,
    _ => [],
  };
  prev = prev.sublist(0, prev.indexOf(name) + 1);
  for (var n in el.children) {
    if (n.nodeType != XmlNodeType.ELEMENT) {
      pos++;
      continue;
    }
    if (prev.contains((n as XmlElement).localName)) {
      if (n.localName == name) multi++;
      pos++;
      continue;
    }
    break;
  }
  return (pos, multi);
}
