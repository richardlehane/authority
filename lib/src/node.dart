import 'xml_web.dart';
import 'package:xml/xml.dart' show XmlElement;

enum NodeType { classType, termType }

bool _isAttr(String name) => name[0] == name[0].toLowerCase();

class CurrentNode {
  NodeType typ;
  (int, int) reference;
  Map<String, bool> updates = {};

  CurrentNode(this.typ, this.reference);

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
}
