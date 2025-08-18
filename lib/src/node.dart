import 'xml_web.dart';
import 'package:xml/xml.dart' show XmlElement;
import "render.dart";

enum NodeType {
  rootType,
  contextType,
  classType,
  termType;

  @override
  String toString() {
    switch (this) {
      case NodeType.rootType:
        return "Authority";
      case NodeType.contextType:
        return "Context";
      case NodeType.classType:
        return "Class";
      case NodeType.termType:
        return "Term";
    }
  }
}

NodeType nodeFromString(String name) {
  switch (name) {
    case "Authority":
      return NodeType.rootType;
    case "Context":
      return NodeType.contextType;
    case "Class":
      return NodeType.classType;
    case "Term":
      return NodeType.termType;
  }
  return NodeType.rootType;
}

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

  String? get(String name) {
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
    return Session().multiLen(reference.$1, name);
  }

  int multiAdd(String name, String el) {
    return Session().multiAdd(reference.$1, name, el);
  }

  void multiDrop(String name, int idx) {} // todo

  void multiUp(String name, int idx) {} // todo

  void multiDown(String name, int idx) {} // todo

  // todo: set attribute
  void multiSet(String name, int idx, String? sub, String? val) {
    return Session().multiSet(reference.$1, name, idx, sub, val);
  }

  // todo: get attribute
  String? multiGet(String name, int idx, String? sub) {
    return Session().multiGet(reference.$1, name, idx, sub);
  }

  List<XmlElement>? multiGetParagraphs(String name, int idx, String? sub) {
    return Session().multiGetParagraphs(reference.$1, name, idx, sub);
  }

  void multiSetParagraphs(
    String name,
    int idx,
    String? sub,
    List<XmlElement>? val,
  ) {
    return Session().multiSetParagraphs(reference.$1, name, idx, sub, val);
  }

  // todo
  // these are for repeating elements within multi element e.g. TermReference in SeeReference
  int fieldsLen(String name, int idx, String sub) {
    return 0; //todo
  }

  String? fieldsGet(String name, int idx, String? sub, int fidx) {
    return null; // todo
  }

  void fieldsSet(
    String name,
    int idx,
    String? sub,
    int fidx,
    String? val,
  ) {} //todo
}
