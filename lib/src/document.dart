import 'package:fluent_ui/fluent_ui.dart' show TreeViewItem;
import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'xml_web.dart' show Session;
import 'node.dart' show CurrentNode, NodeType;
import 'counter.dart';
import 'tree.dart';

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
  String? path;
  List<TreeViewItem>? treeItems;
  int sessionIndex;
  int selectedItemIndex;
  NodeType selectedType;
  View view = View.edit;

  Document({
    required this.title,
    this.path = null,
    this.treeItems,
    this.sessionIndex = 0,
    this.selectedItemIndex = 0,
    this.selectedType = NodeType.rootType,
  });

  /// Create a new empty document model with default structure
  factory Document.empty({String title = 'Untitled'}) {
    Session sess = Session();
    final sessionIndex = sess.empty();
    return Document(
      title: title,
      treeItems: sess.tree(sessionIndex, Counter(0, NodeType.termType)),
      sessionIndex: sessionIndex,
    );
  }

  factory Document.load(PlatformFile f) {
    Session sess = Session();
    final sessionIndex = sess.load(f);
    return Document(
      title: f.name,
      // path: f.path, ???
      treeItems: sess.tree(sessionIndex, Counter(0, NodeType.termType)),
      sessionIndex: sessionIndex,
    );
  }

  @override
  String toString() {
    return Session().asString(sessionIndex);
  }

  void refreshTree() {
    treeItems = Session().tree(
      sessionIndex,
      Counter(selectedItemIndex, selectedType),
    );
  }

  CurrentNode current() {
    return CurrentNode((sessionIndex, selectedItemIndex, selectedType));
  }

  void setCurrent(int index, NodeType nt) {
    selectedItemIndex = index;
    Session().setCurrent(sessionIndex, index, nt);
  }

  void dropNode(int n, NodeType nt) {
    Session().dropNode(sessionIndex, n, nt);
    n = (n == 0) ? 0 : n - 1;
    selectedItemIndex = n;
    prune(n, nt, treeItems, TreeOp.drop);
  }

  void addContext([int? n]) {
    if (n == null) {
      Session().addContext(sessionIndex);
      selectedItemIndex =
          treeItems![1].children.length - 1; // live dangerously!
    } else {
      Session().addSibling(sessionIndex, n, NodeType.contextType);
      selectedItemIndex = n + 1;
    }
    selectedType = NodeType.contextType;
    refreshTree();
  }

  void addChild(int n, NodeType nt) {
    Session().addChild(sessionIndex, n, nt);
    // update selectedItemIndex by walking the treemenu
    final TreeViewItem? it = treeNth(n, nt, treeItems);
    if (it != null) {
      selectedItemIndex = n + treeDescendants(it) + 1;
      selectedType = nt;
    }
    refreshTree();
  }

  void addSibling(int n, NodeType nt) {
    Session().addSibling(sessionIndex, n, nt);
    // update selectedItemIndex by walking the treemenu
    final TreeViewItem? it = treeNth(n, nt, treeItems);
    if (it != null) {
      selectedItemIndex = n + treeDescendants(it) + 1;
      selectedType = nt;
    }
    refreshTree();
  }

  void moveUp(int n, NodeType nt) {
    Session().moveUp(sessionIndex, n, nt);
    refreshTree();
  }

  void moveDown(int n, NodeType nt) {
    Session().moveDown(sessionIndex, n, nt);
    refreshTree();
  }
}

// todo: make this a reset, that sets selected to false for all but the current selection & renumbers the nodes.
void clearSelected(List<TreeViewItem>? list) {
  if (list == null) return;
  for (final element in list) {
    element.selected = false;
    clearSelected(element.children);
  }
}
