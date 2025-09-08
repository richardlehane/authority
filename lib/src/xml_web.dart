import 'package:xml/xml.dart';
import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'node.dart' show NodeType, nodeFromString;
import 'tree.dart' show TreeNode, Counter, Ref;

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

bool _isAttr(String name) => name[0] == name[0].toLowerCase();

class Session {
  List<XmlDocument> documents = [];
  List<XmlElement?> nodes = [];

  // singleton
  Session._();
  static final Session _instance = Session._();
  factory Session() => _instance;

  int _init(XmlDocument doc) {
    documents.add(doc);
    nodes.add(_nth(doc, (NodeType.termType, 0)));
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

  List<TreeNode> tree(int index, Counter ctr) {
    ctr.next(NodeType.rootType);
    List<TreeNode> ret = [
      TreeNode((NodeType.rootType, 0), null, "Details", []),
      TreeNode(
        (NodeType.none, 0),
        null,
        "Context",
        _addContext(documents[index].rootElement, ctr),
      ),
    ];
    ret.addAll(_addChildren(_termsClasses(documents[index].rootElement), ctr));
    return ret;
  }

  String asString(int index) =>
      documents[index].toXmlString(pretty: true, indent: '\t');

  void setCurrent(int index, Ref ref) {
    // todo: authority/ context nodes
    nodes[index] = _nth(documents[index], ref);
  }

  // tree operations
  void dropNode(int index, Ref ref) {
    XmlElement? el = _nth(documents[index], ref);
    if (el == null) return;
    el.remove();
  }

  void addChild(int index, Ref ref, NodeType nt) {
    XmlElement? el = _nth(documents[index], ref);
    if (el == null) return;
    if (nt == NodeType.contextType) {
      (int, int) p = _insertPos(el, "Context");
      el.children.insert(p.$1, XmlElement(XmlName("Context")));
      return;
    }
    el.children.add(XmlElement(XmlName(nt.toString())));
  }

  void addSibling(int index, Ref ref, NodeType nt) {
    XmlElement? el = _nth(documents[index], ref);
    if (el == null) return;
    el.parentElement!.children.insert(
      _pos(el) + 1,
      XmlElement(XmlName(nt.toString())),
    );
  }

  bool moveUp(int index, Ref ref) {
    XmlElement? el = _nth(documents[index], ref);
    if (el == null) return false;
    XmlElement? prev = el.previousElementSibling;
    if (prev == null || !ref.$1.like(nodeFromString(prev.localName)))
      return false;
    el.remove();
    prev.parentElement!.children.insert(_pos(prev), el);
    return true;
  }

  bool moveDown(int index, Ref ref) {
    XmlElement? el = _nth(documents[index], ref);
    if (el == null) return false;
    XmlElement? next = el.nextElementSibling;
    if (next == null || !ref.$1.like(nodeFromString(next.localName)))
      return false;
    el.remove();
    next.parentElement!.children.insert(_pos(next) + 1, el);
    return true;
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

  // node operations
  NodeType getType(int index) {
    XmlElement? el = nodes[index];
    if (el == null) return NodeType.rootType;
    return nodeFromString(el.localName);
  }

  String? get(int index, String name) {
    XmlElement? el = nodes[index];
    if (el == null) return null;
    if (_isAttr(name)) {
      String? a = el.getAttribute(name, namespace: _ns);
      return (a != null) ? a : null;
    }
    XmlElement? t = el.getElement(name);
    return (t != null) ? t.innerText : null;
  }

  void set(int index, String name, String? value) {
    XmlElement? el = nodes[index];
    if (el == null) return;
    if (_isAttr(name)) {
      el.setAttribute(name, value, namespace: _ns);
      return;
    }
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
    (int, int) p = _insertPos(el, name);
    el.children.insert(p.$1, t);
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
      (int, int) p = _insertPos(el, name);
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
    (int, int) p = _insertPos(el, name);
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
        (int, int) p = _insertPos(el, "RetentionPeriod");
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
      (int, int) p = _insertPos(el, sub);
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
      (int, int) p = _insertPos(parent, sub);
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

  int fieldsLen(int index, String name, int idx, String sub) {
    XmlElement? el = nodes[index];
    if (el == null) return 0;
    el = el.findElements(name).elementAt(idx);
    return el.findElements(sub).length;
  }

  String? fieldsGet(int index, String name, int idx, String sub, int fidx) {
    XmlElement? el = nodes[index];
    if (el == null) return null;
    el = el.findElements(name).elementAt(idx);
    el = el.findElements(sub).elementAt(fidx);
    return el.innerText.isEmpty ? null : el.innerText;
  }

  void fieldsAdd(int index, String name, int idx, String sub) {
    XmlElement? el = nodes[index];
    if (el == null) return null;
    el = el.findElements(name).elementAt(idx);
    // todo: insert in right spot
    return;
  }
}

List<TreeNode> _addContext(XmlElement root, Counter ctr) {
  return root.findElements("Context").map((item) {
    final int index = ctr.next(NodeType.contextType);
    return TreeNode(
      (NodeType.contextType, index),
      null,
      item.getElement("ContextTitle")?.innerText,
      [],
    );
  }).toList();
}

List<TreeNode> _addChildren(List<XmlElement> list, Counter ctr) {
  return list.map((item) {
    final NodeType nt = (item.name.local == 'Term')
        ? NodeType.termType
        : NodeType.classType;
    final int index = ctr.next(nt);
    return TreeNode(
      (nt, index),
      item.getAttribute("itemno"),
      nt == NodeType.termType
          ? item.getAttribute('TermTitle')
          : item.getElement('ClassTitle')?.innerText,
      _addChildren(_termsClasses(item), ctr),
    );
  }).toList();
}

List<XmlElement> _termsClasses(XmlElement el) {
  if (el.name.local == 'Class') {
    return [];
  }
  return el.childElements
      .where((e) => e.name.local == 'Term' || e.name.local == 'Class')
      .toList();
}

XmlElement? _nth(XmlDocument? doc, Ref ref) {
  switch (ref.$1) {
    case NodeType.none:
      return null;
    case NodeType.rootType:
      return doc?.rootElement;
    case NodeType.contextType:
      return doc?.rootElement.findElements("Context").elementAt(ref.$2);
    default:
      return _nthTermClass(doc, ref.$2);
  }
}

XmlElement? _nthTermClass(XmlDocument? doc, int n) {
  int idx = -1;
  XmlElement? descend(XmlElement el) {
    for (XmlElement child in el.childElements.where(
      (e) => e.name.local == 'Term' || e.name.local == 'Class',
    )) {
      idx++;
      if (idx == n) return child;
      if (child.name.local == 'Term') {
        var ret = descend(child);
        if (ret != null) return ret;
      }
    }
    return null;
  }

  if (doc == null) return null;
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
(int, int) _insertPos(XmlElement el, String name) {
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
