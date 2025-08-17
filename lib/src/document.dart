import 'package:fluent_ui/fluent_ui.dart' show TreeViewItem;
import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'xml_web.dart' show Session;
import 'node.dart' show CurrentNode, NodeType;
import 'counter.dart';

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
    return Document(
      title: title,
      treeItems: sess.tree(sessionIndex, Counter(0)),
      sessionIndex: sessionIndex,
    );
  }

  factory Document.load(PlatformFile f) {
    Session sess = Session();
    final sessionIndex = sess.load(f);
    return Document(
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
    return CurrentNode((sessionIndex, selectedItemIndex));
  }

  void setCurrent(int index) {
    selectedItemIndex = index;
    Session().setCurrent(sessionIndex, index);
  }

  void dropNode(int n) {
    Session().dropNode(sessionIndex, n);
    n = (n == 0) ? 0 : n - 1;
    selectedItemIndex = n;
    refreshTree();
  }

  void addChild(int n, NodeType nt) {
    Session().addChild(sessionIndex, n, nt);
    // update selectedItemIndex by walking the treemenu
    final TreeViewItem? it = treeNth(n, treeItems);
    if (it != null) {
      selectedItemIndex = n + treeDescendants(it) + 1;
    }
    refreshTree();
  }

  void addSibling(int n, NodeType nt) {
    Session().addSibling(sessionIndex, n, nt);
    // update selectedItemIndex by walking the treemenu
    final TreeViewItem? it = treeNth(n, treeItems);
    if (it != null) {
      selectedItemIndex = n + treeDescendants(it) + 1;
    }
    refreshTree();
  }

  // todo: move up / move down
  // todo: authority and context nodes
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
