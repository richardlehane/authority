import 'xml_web.dart';
import 'package:xml/xml.dart' show XmlElement;

enum NodeType { classType, termType }

bool _isAttr(String name) => name[0] == name[0].toLowerCase();

class CurrentNode {
  (int, int) reference;
  Map<String, bool> updates = {};

  CurrentNode(this.reference);

  void mark(String name) {
    updates[name] = true;
  }

  String get(String name) {
    if (_isAttr(name)) {
      return Session().getAttribute(reference.$1, name);
    }
    return Session().getElement(reference.$1, name);
  }

  void set(String name, String value) {
    final changed = updates[name] ?? false;
    if (!changed) return;
    updates[name] = false;
    if (_isAttr(name)) {
      return Session().setAttribute(reference.$1, name, value);
    }
    return Session().setElement(reference.$1, name, value);
  }

  List<XmlElement>? getParagraphs(String name) {
    return Session().getParagraphs(reference.$1, name);
  }

  void setParagraphs(String name, List<XmlElement> paras) {
    return Session().setParagraphs(reference.$1, name, paras);
  }

  int mLen(String name) {
    return Session().mLen(reference.$1, name);
  }

  int mAdd(String name, String el) {
    return Session().mAdd(reference.$1, name, el);
  }

  void mDrop(String name, int idx) {} // todo

  void mUp(String name, int idx) {} // todo

  void mDown(String name, int idx) {} // todo

  void mSet(String name, int idx, String tok, String val) {
    return Session().mSet(reference.$1, name, idx, tok, val);
  }

  String mGet(String name, int idx, String tok) {
    return "";
  }

  List<XmlElement>? mGetParagraphs(String name, int idx, String el) {
    return null;
  }

  void mSetParagraphs(String name, int idx, String el, List<XmlElement>? val) {}

  int fLen(String name, int idx, String tok) {
    return 0;
  }

  String fGet(String name, int idx, String tok, int fidx) {
    return "";
  }

  void fSet(String name, int idx, String tok, int fidx, String val) {}
}
