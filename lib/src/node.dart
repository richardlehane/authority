import 'xml_web.dart';
import 'package:xml/xml.dart' show XmlElement;
import "render.dart";
import 'tree.dart' show Ref;

enum NodeType {
  rootType,
  contextType,
  classType,
  termType,
  none;

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
      case NodeType.none:
        return "None";
    }
  }

  bool like(NodeType nt) {
    switch (this) {
      case NodeType.termType:
      case NodeType.classType:
        if (nt == NodeType.termType || nt == NodeType.classType) return true;
        return false;
      default:
        return nt == this;
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

class CurrentNode with Render {
  int session;
  Ref ref;
  CurrentNode(this.session, this.ref);

  NodeType typ() {
    return Session().getType(session);
  }

  String? get(String name) {
    return Session().get(session, name);
  }

  void set(String name, String? value) {
    return Session().set(session, name, value);
  }

  List<XmlElement>? getParagraphs(String name) {
    return Session().getParagraphs(session, name);
  }

  void setParagraphs(String name, List<XmlElement>? paras) {
    return Session().setParagraphs(session, name, paras);
  }

  int multiLen(String name) {
    return Session().multiLen(session, name);
  }

  int multiAdd(String name, String? sub) {
    return Session().multiAdd(session, name, sub);
  }

  void multiDrop(String name, int idx) {} // todo

  void multiUp(String name, int idx) {} // todo

  void multiDown(String name, int idx) {} // todo

  // todo: set attribute
  void multiSet(String name, int idx, String? sub, String? val) {
    return Session().multiSet(session, name, idx, sub, val);
  }

  // todo: get attribute
  String? multiGet(String name, int idx, String? sub) {
    return Session().multiGet(session, name, idx, sub);
  }

  List<XmlElement>? multiGetParagraphs(String name, int idx, String? sub) {
    return Session().multiGetParagraphs(session, name, idx, sub);
  }

  void multiSetParagraphs(
    String name,
    int idx,
    String? sub,
    List<XmlElement>? val,
  ) {
    return Session().multiSetParagraphs(session, name, idx, sub, val);
  }

  // todo
  // these are for repeating elements within multi element e.g. TermReference in SeeReference
  int fieldsLen(String name, int idx, String sub) {
    return Session().fieldsLen(session, name, idx, sub);
  }

  String? fieldsGet(String name, int idx, String sub, int fidx) {
    return Session().fieldsGet(session, name, idx, sub, fidx);
  }

  void fieldsSet(
    String name,
    int idx,
    String? sub,
    int fidx,
    String? val,
  ) {} //todo
}
