import 'package:fluent_ui/fluent_ui.dart' show TreeViewItem;
import 'xml_web.dart' show Session;
import 'node' show CurrentNode, NodeType;

enum View {
  edit,
  source;

  @override
  String toString() {
    switch (this) {
      case View.edit:
        return "edit";
      case View.source:
        return "source";
    }
  }
}

class Document {
  String title;
  String path;
  List<TreeViewItem>? treeItems;
  int selectedItemIndex;
  int sessionIndex;
  View view = View.edit;

  Document({
    required this.title,
    this.path = "",
    this.treeItems,
    this.selectedItemIndex = 0,
    this.sessionIndex = 0,
  });

  /// Create a new empty document model with default structure
  factory Document.empty({String title = 'Untitled'}) {
    Session sess = Session();
    final sessionIndex = sess.empty();
    return DocumentModel(
      title: title,
      treeItems: sess.tree(sessionIndex, Counter(0)),
      sessionIndex: sessionIndex,
    );
  }

  factory Document.load(PlatformFile f) {
    Session sess = Session();
    final sessionIndex = sess.load(f);
    return DocumentModel(
      title: f.name,
      // path: f.path, ???
      treeItems: sess.tree(sessionIndex, Counter(0)),
      sessionIndex: sessionIndex,
    );
  }

  @override
  String toString() {
    return Session().asString(sessionIndex);
  }

  void refreshTree() {
    treeItems = Session().tree(sessionIndex, Counter(selectedItemIndex));
  }

  CurrentNode current() {
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
