import 'package:fluent_ui/fluent_ui.dart' show TreeViewItem;
import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'xml_web.dart' show Session;
import 'node.dart' show CurrentNode, NodeType;
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
  Ref selected;
  View view = View.edit;

  Document({
    required this.title,
    this.path = null,
    this.treeItems,
    this.sessionIndex = 0,
    this.selected = (NodeType.rootType, 0),
  });

  /// Create a new empty document model with default structure
  factory Document.empty({String title = 'Untitled'}) {
    Session sess = Session();
    final sessionIndex = sess.empty();
    return Document(
      title: title,
      treeItems: treeFrom(sess.tree(sessionIndex, Counter())),
      sessionIndex: sessionIndex,
    );
  }

  factory Document.load(PlatformFile f) {
    Session sess = Session();
    final sessionIndex = sess.load(f);
    return Document(
      title: f.name,
      // path: f.path, ???
      treeItems: treeFrom(sess.tree(sessionIndex, Counter())),
      sessionIndex: sessionIndex,
    );
  }

  @override
  String toString() {
    return Session().asString(sessionIndex);
  }

  void refreshTree() {
    treeItems = treeFrom(Session().tree(sessionIndex, Counter(selected)));
  }

  CurrentNode current() {
    return CurrentNode(sessionIndex, selected);
  }

  void setCurrent(Ref ref) {
    Session().setCurrent(sessionIndex, ref);
  }

  void dropNode(Ref ref) {
    Session().dropNode(sessionIndex, ref);
    selected = (ref.$2 == 0)
        ? (ref.$1 == NodeType.contextType)
              ? (NodeType.rootType, 0)
              : (ref.$1, 0)
        : (ref.$1, ref.$2 - 1);
    treeItems = mutate(treeItems!, TreeOp.drop, ref, ctr: Counter(selected));
  }

  void addChild(Ref ref, NodeType nt) {
    Session().addChild(sessionIndex, ref, nt);
    // update selectedItemIndex by walking the treemenu TODO: fix
    // final TreeViewItem? it = treeNth(ref, treeItems);
    // if (it != null) selected = (nt, ref.$2 + treeDescendants(it) + 1);
    // refreshTree();
    treeItems = mutate(treeItems!, TreeOp.child, ref, ctr: Counter());
    selected = getSelected(treeItems!) ?? (NodeType.rootType, 0);
  }

  void addSibling(Ref ref, NodeType nt) {
    Session().addSibling(sessionIndex, ref, nt);
    treeItems = mutate(treeItems!, TreeOp.sibling, ref, ctr: Counter());
    selected = getSelected(treeItems!) ?? (NodeType.rootType, 0);
  }

  void moveUp(Ref ref) {
    Session().moveUp(sessionIndex, ref);
    treeItems = mutate(treeItems!, TreeOp.up, ref, ctr: Counter(selected));
  }

  void moveDown(Ref ref) {
    Session().moveDown(sessionIndex, ref);
    treeItems = mutate(treeItems!, TreeOp.down, ref, ctr: Counter(selected));
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
