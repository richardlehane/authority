import 'package:authority/authority.dart';
import 'package:test/test.dart';

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
    curr.mark("itemno");
    curr.set("itemno", "5.0.1");
    expect(doc.current().get("itemno"), "5.0.1");
  });
  test('delete attribute', () {
    CurrentNode curr = doc.current();
    curr.mark("itemno");
    curr.set("itemno", null);
    expect(doc.current().get("itemno"), null);
  });
  test('create attribute', () {
    CurrentNode curr = doc.current();
    curr.mark("itemno");
    curr.set("itemno", "1.1.1");
    expect(doc.current().get("itemno"), "1.1.1");
  });
}
