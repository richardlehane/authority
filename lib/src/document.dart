import 'dart:async';
import 'dart:io';
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
  int mutation;
  Ref selected;
  View view = View.edit;

  Document({
    required this.title,
    this.path = null,
    this.treeItems,
    this.sessionIndex = 0,
    this.mutation = 0,
    this.selected = (NodeType.rootType, 0),
  });

  /// Create a new empty document model with default structure
  factory Document.empty({String title = 'Untitled'}) {
    Session sess = Session();
    final sessionIndex = sess.empty();
    return Document(
      title: title,
      treeItems: treeFrom(sess.tree(sessionIndex, Counter()), (
        NodeType.termType,
        0,
      )),
      sessionIndex: sessionIndex,
    );
  }

  factory Document.load(PlatformFile f) {
    Session sess = Session();
    final sessionIndex = sess.load(f);
    return Document(
      title: f.name,
      path: f.path,
      treeItems: treeFrom(sess.tree(sessionIndex, Counter()), (
        NodeType.termType,
        0,
      )),
      sessionIndex: sessionIndex,
    );
  }

  @override
  String toString() {
    return Session().asString(sessionIndex);
  }

  Future<File> save() {
    if (path == null) {
      throw Exception("no path!");
    }
    return File(path!).writeAsString(toString(), flush: true);
  }

  Future<File> saveAs(String p) {
    path = p;
    return save();
  }

  CurrentNode current() {
    return CurrentNode(sessionIndex, mutation, selected);
  }

  void setCurrent(Ref ref) {
    selected = ref;
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
    mutation++;
  }

  void addChild(Ref ref, NodeType nt) {
    Session().addChild(sessionIndex, ref, nt);
    treeItems = mutate(
      treeItems!,
      TreeOp.child,
      (nt == NodeType.contextType) ? (NodeType.none, 0) : ref,
      ctr: Counter(),
      nt: nt,
    );
    mutation++;
    setCurrent(getSelected(treeItems!) ?? (NodeType.rootType, 0));
  }

  void addSibling(Ref ref, NodeType nt) {
    Session().addSibling(sessionIndex, ref, nt);
    treeItems = mutate(treeItems!, TreeOp.sibling, ref, ctr: Counter(), nt: nt);
    mutation++;
    setCurrent(getSelected(treeItems!) ?? (NodeType.rootType, 0));
  }

  void moveUp(Ref ref) {
    Session().moveUp(sessionIndex, ref);
    treeItems = mutate(treeItems!, TreeOp.up, ref, ctr: Counter(selected));
    mutation++;
  }

  void moveDown(Ref ref) {
    Session().moveDown(sessionIndex, ref);
    treeItems = mutate(treeItems!, TreeOp.down, ref, ctr: Counter(selected));
    mutation++;
  }

  void relabel(Ref ref, String? itemno, String? title) {
    treeItems = mutate(
      treeItems!,
      TreeOp.relabel,
      ref,
      itemno: itemno,
      title: title,
    );
  }
}
