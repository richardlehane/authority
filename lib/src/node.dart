import 'xml_web.dart';
import 'package:xml/xml.dart' show XmlElement;
import "render.dart";

enum NodeType { rootType, contextType, classType, termType }

bool _isAttr(String name) => name[0] == name[0].toLowerCase();

class CurrentNode with Render {
  (int, int, NodeType) reference;
  Map<String, bool> updates = {};

  CurrentNode(this.reference);

  NodeType typ() {
    return Session().getType(reference.$1);
  }

  void mark(String name) {
    updates[name] = true;
  }

  String get(String? name) {
    if (_isAttr(name)) {
      return Session().getAttribute(reference.$1, name);
    }
    return Session().getElement(reference.$1, name);
  }

  void set(String name, String? value) {
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

  void setParagraphs(String name, List<XmlElement>? paras) {
    return Session().setParagraphs(reference.$1, name, paras);
  }

  int multiLen(String name) {
    return Session().mLen(reference.$1, name);
  }

  int multiAdd(String name, String el) {
    return Session().mAdd(reference.$1, name, el);
  }

  void multiDrop(String name, int idx) {} // todo

  void multiUp(String name, int idx) {} // todo

  void multiDown(String name, int idx) {} // todo

  // todo: set attribute
  void multiSet(String name, int idx, String? tok, String? val) {
    return Session().mSet(reference.$1, name, idx, tok, val);
  }

  // todo: get attribute
  String multiGet(String name, int idx, String? tok) {
    return Session().mGet(reference.$1, name, idx, tok);
  }

  List<XmlElement>? multiGetParagraphs(String name, int idx, String el) {
    return Session().mGetParagraphs(reference.$1, name, idx, el);
  }

  void mSetParagraphs(String name, int idx, String el, List<XmlElement> val) {
    return Session().mSetParagraphs(reference.$1, name, idx, el, val);
  }

  // todo
  // these are for repeating elements within multi element e.g. TermReference in SeeReference
  int fLen(String name, int idx, String tok) {
    return 0; //todo
  }

  String fGet(String name, int idx, String tok, int fidx) {
    return ""; // todo
  }

  void fSet(String name, int idx, String tok, int fidx, String val) {} //todo
}
