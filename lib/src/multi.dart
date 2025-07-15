class MultiImpl {
  int len(String name) {
    return 0;
  }

  // e.g. append("Disposal", "Disposal")
  int append(String name, String el) {
    return 0;
  }

  // knows if el or attr
  String get(String name, int idx, String tok) {
    return "";
  }

  void set(String name, int idx, String tok, String val) {
    return;
  }

  List<XmlElement>? getParagraphs(String name, int idx, String el) {
    return null;
  }

  void setParagraphs(String name, int idx, String el, List<XmlElement>? val) {
    return;
  }

  // for TermTitleRef or other repeating fields
  int fieldLen(String name, int idx, String tok) {
    return 0;
  }

  String getField(String name, int idx, String tok, int fidx) {
    return "";
  }

  void setField(String name, int idx, String tok, int fidx, String val) {}

  void moveUp(String name, int idx) {}
  void moveDown(String name, int idx) {}
  void drop(String name, int idx) {}
}
