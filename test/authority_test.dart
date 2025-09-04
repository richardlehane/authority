import 'package:authority/authority.dart';
import 'package:test/test.dart';
import 'package:fluent_ui/fluent_ui.dart' show TreeViewItem;

void main() {
  Document doc = Document.empty();
  test('create empty document', () {
    expect(doc.title, "Untitled");
  });
  test('set current node', () {
    doc.setCurrent(2, NodeType.classType);
    expect(doc.current().typ(), NodeType.classType);
  });
  test('update attribute', () {
    CurrentNode curr = doc.current();
    curr.set("itemno", "5.0.1");
    expect(doc.current().get("itemno"), "5.0.1");
  });
  test('delete attribute', () {
    CurrentNode curr = doc.current();
    curr.set("itemno", null);
    expect(doc.current().get("itemno"), null);
  });
  test('create attribute', () {
    CurrentNode curr = doc.current();
    curr.set("itemno", "1.1.1");
    expect(doc.current().get("itemno"), "1.1.1");
  });
  test('create sibling', () {
    doc.addSibling(2, NodeType.classType);
    doc.setCurrent(3, NodeType.classType);
    expect(doc.current().get("itemno"), null);
  });
  test('move up', () {
    doc.moveUp(3, NodeType.classType);
    doc.setCurrent(3, NodeType.classType);
    expect(doc.current().get("itemno"), "1.1.1");
  });
  test('equality', () {
    List<TreeViewItem> a = [
      makeItem(0, NodeType.classType, false, null, null, []),
    ];
    List<TreeViewItem> b = [
      makeItem(0, NodeType.classType, false, null, null, []),
    ];
    expect(treesEqual(a, b), true);
  });
}
