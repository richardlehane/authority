import 'authority_none.dart' // Stub implementation
    if (dart.library.io) 'authority_win.dart' // dart:io implementation
    if (dart.library.js_interop) 'authority_web.dart'; // package:web implementation
import 'package:xml/xml.dart' show XmlElement;
import 'package:fluent_ui/fluent_ui.dart' show TreeViewItem;

const String _blank = '''
<?xml version="1.0" encoding="UTF-8"?>
<Authority xmlns="http://www.records.nsw.gov.au/schemas/RDA">
	<Term itemno="1.0.0" type="function">
    <Term itemno="1.1.0" type="activity">
      <Class itemno="1.1.1" />
		</Term>
	</Term>
</Authority>
''';

enum NodeType { classType, termType }

enum DocumentView {
  editView,
  sourceView;

  @override
  String toString() {
    switch (this) {
      case DocumentView.editView:
        return "edit";
      case DocumentView.sourceView:
        return "source";
    }
  }
}

/// Model representing a document and its structure
class DocumentModel {
  String title;
  String path;
  List<TreeViewItem>? treeItems;
  int selectedItemIndex;
  DocumentView view = DocumentView.editView;
  XmlDocument? document;

  DocumentModel({
    required this.title,
    this.path = "",
    this.treeItems,
    this.document,
    this.selectedItemIndex = 0,
  });

  /// Create a new empty document model with default structure
  factory DocumentModel.empty({String title = 'Untitled'}) {
    final doc = XmlDocument.parse(blank);
    return DocumentModel(
      title: title,
      treeItems: addChildren(termsClasses(doc.rootElement), Counter(0)),
      document: doc,
    );
  }

  factory DocumentModel.load(PlatformFile f) {
    if (f.bytes == null) {
      return DocumentModel.empty(title: f.name);
    }
    final doc = XmlDocument.parse(String.fromCharCodes(f.bytes!));
    return DocumentModel(
      title: f.name,
      treeItems: addChildren(termsClasses(doc.rootElement), Counter(0)),
      document: doc,
    );
  }

  @override
  String toString() {
    if (document != null) {
      return document!.toXmlString(pretty: true, indent: '\t');
    }
    return "";
  }

  void refreshTree() {
    treeItems = addChildren(
      termsClasses(document!.rootElement),
      Counter(selectedItemIndex),
    );
  }

  XmlElement? currentNode() {
    return nth(document, selectedItemIndex);
  }

  void drop(int n) {
    XmlElement? el = nth(document, n);
    if (el == null) {
      return;
    }
    el.remove();
    n = (n == 0) ? 0 : n - 1;
    selectedItemIndex = n;
    refreshTree();
  }

  void addChild(int n, NodeType nt) {
    XmlElement? el = nth(document, n);
    if (el == null) {
      return;
    }
    el.children.add(
      XmlElement(XmlName((nt == NodeType.termType) ? "Term" : "Class")),
    );
    // update selectedItemIndex by walking the treemenu
    final TreeViewItem? it = treeNth(n, treeItems);
    if (it != null) {
      selectedItemIndex = n + treeDescendants(it) + 1;
    }
    refreshTree();
  }

  void addSibling(int n, NodeType nt) {
    XmlElement? el = nth(document, n);
    if (el == null) {
      return;
    }
    el.parentElement!.children.insert(
      pos(el) + 1,
      XmlElement(XmlName((nt == NodeType.termType) ? "Term" : "Class")),
    );

    // update selectedItemIndex by walking the treemenu
    final TreeViewItem? it = treeNth(n, treeItems);
    if (it != null) {
      selectedItemIndex = n + treeDescendants(it) + 1;
    }
    refreshTree();
  }
}

class Counter {
  int count = -1;
  int selected = 0;

  Counter(this.selected);

  int next() {
    count++;
    return count;
  }

  bool isSelected() {
    return selected == count;
  }
}

List<TreeViewItem> addChildren(List<XmlElement> list, Counter ctr) {
  return list.map((item) {
    final NodeType nt =
        (item.name.local == 'Term') ? NodeType.termType : NodeType.classType;
    final int index = ctr.next();
    final bool selected = ctr.isSelected();
    return TreeViewItem(
      leading:
          (nt == NodeType.termType)
              ? Icon(FluentIcons.fabric_folder)
              : Icon(FluentIcons.page),
      content: Text(title(item)),
      value: (nt, index),
      children: addChildren(termsClasses(item), ctr),
      selected: selected,
    );
  }).toList();
}

TreeViewItem? treeNth(int n, List<TreeViewItem>? list) {
  if (list == null) {
    return null;
  }
  TreeViewItem? prev;
  for (final element in list) {
    if (element.value.$2 == n) {
      return element;
    }
    if (element.value.$2 > n) {
      if (prev != null) {
        final TreeViewItem? el = treeNth(n, prev.children);
        if (el != null) {
          return el;
        }
      } else {
        return null;
      }
    }
    prev = element;
  }
  return null;
}

int treeDescendants(TreeViewItem item) {
  int tally = item.children.length;
  for (final element in item.children) {
    tally += treeDescendants(element);
  }
  return tally;
}

String title(XmlElement el) {
  String? itemno = el.getAttribute("itemno");
  XmlElement? t =
      (el.name.local == 'Class')
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

List<XmlElement> termsClasses(XmlElement el) {
  if (el.name.local == 'Class') {
    return [];
  }
  return el.childElements
      .where((e) => e.name.local == 'Term' || e.name.local == 'Class')
      .toList();
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

int pos(XmlNode el) {
  int ret = 0;
  while (el.previousSibling != null) {
    ret++;
    el = el.previousSibling!;
  }
  return ret;
}

class DocState {
  int current;
  List<DocumentModel> documents;

  DocState({required this.current, required this.documents});
}

@Riverpod(keepAlive: true)
class Documents extends _$Documents {
  @override
  DocState build() {
    return DocState(current: 0, documents: [DocumentModel.empty()]);
  }

  DocumentModel current() {
    return state.documents[state.current];
  }

  void load(PlatformFile f) {
    state.documents.add(DocumentModel.load(f));
    state.current = state.documents.length - 1;
    ref.notifyListeners();
  }

  void newDocument() {
    state.documents.add(DocumentModel.empty());
    state.current = state.documents.length - 1;
    ref.notifyListeners();
  }

  void drop(int index) {
    if (state.documents.length > 1) {
      if (state.current == state.documents.length - 1) {
        state.current -= 1;
      }
      state.documents.removeAt(index);
      ref.notifyListeners();
    }
  }

  void paneChanged(int pane) {
    state.current = pane;
    ref.notifyListeners();
  }

  void selectionChanged(int index) {
    state.documents[state.current].selectedItemIndex = index;
    ref.notifyListeners();
  }

  void viewChanged(String view) {
    switch (view) {
      case "source":
        state.documents[state.current].view = DocumentView.sourceView;
      default:
        state.documents[state.current].view = DocumentView.editView;
    }
    ref.notifyListeners();
  }

  void addChild(int n, NodeType nt) {
    state.documents[state.current].addChild(n, nt);
    ref.notifyListeners();
  }

  void addSibling(int n, NodeType nt) {
    state.documents[state.current].addSibling(n, nt);
    ref.notifyListeners();
  }

  void dropElement(int n) {
    state.documents[state.current].drop(n);
    ref.notifyListeners();
  }

  void refresh() {
    state.documents[state.current].refreshTree();
    ref.notifyListeners();
  }
}

// CURRENT NODE

class CurrNode {
  CurrNode(this.typ, this.el, this.reference);
  NodeType typ;
  XmlElement? el;
  (int, int) reference;
  Map<String, bool> updates = {};

  void mark(String name) {
    updates[name] = true;
  }

  String getElement(String name) {
    if (el == null) return "";
    XmlElement? t = el!.getElement(name);
    if (t != null) {
      return t.innerText;
    }
    return "";
  }

  void setElement(String name, String value) {
    if (el == null) return;
    final changed = updates[name] ?? false;
    if (!changed) return;
    updates[name] = false;
    XmlElement? t = el!.getElement(name);
    // delete
    if (value == "") {
      if (t != null) el!.children.remove(t);
      return;
    }
    // update
    if (t != null) {
      t.innerText = value;
      return;
    }
    // insert
    t = XmlElement(XmlName(name), [], [XmlText(value)], false);
    int p = insertPos(el!, typ, name);
    el!.children.insert(p, t);
    return;
  }

  String getAttribute(String name) {
    if (el == null) return "";
    String? a = el!.getAttribute(
      name,
      namespace: "http://www.records.nsw.gov.au/schemas/RDA",
    );
    return (a != null) ? a : "";
  }

  void setAttribute(String name, String value) {
    if (el == null) return;
    final changed = updates[name] ?? false;
    if (!changed) return;
    updates[name] = false;
    String? a = (value == "") ? null : value;
    el!.setAttribute(
      name,
      a,
      namespace: "http://www.records.nsw.gov.au/schemas/RDA",
    );
    return;
  }

  List<XmlElement>? getParagraphs(String name) {
    if (el == null) return null;
    XmlElement? parent = el!.getElement(name);
    if (parent == null) return null;
    return parent.findElements("Paragraph").toList();
  }

  void setParagraphs(String name, List<XmlElement> paras) {
    if (el == null) return;
    XmlElement? parent = el!.getElement(name);
    if (parent == null) {
      // inserting
      parent = XmlElement(XmlName(name), [], paras, false);
      int p = insertPos(el!, typ, name);
      el!.children.insert(p, parent);
      return;
    }
    parent.children.removeWhere(
      (para) =>
          para.nodeType == XmlNodeType.ELEMENT &&
          (para as XmlElement).name.local == "Paragraph",
    );
    parent.children.insertAll(0, paras);
  }
}

@riverpod
class Node extends _$Node {
  @override
  CurrNode build() {
    final documents = ref.watch(documentsProvider);
    XmlElement? curr = documents.documents[documents.current].currentNode();
    NodeType nt = NodeType.classType;
    if (curr != null) {
      if (curr.name.local == "Term") {
        nt = NodeType.termType;
      }
      return CurrNode(nt, curr, (
        documents.current,
        documents.documents[documents.current].selectedItemIndex,
      ));
    }
    return CurrNode(nt, null, (
      documents.current,
      documents.documents[documents.current].selectedItemIndex,
    ));
  }
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
