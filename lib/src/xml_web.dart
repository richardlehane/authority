import 'package:xml/xml.dart' show XmlElement;

class Session {
  List<XmlDocument>? documents;

  int addString(String content) {
    documents.add(XmlDocument.parse(content));
    return documents.len - 1;
  }

  int addFile(PlatformFile f) {
    if (f.bytes == null) {
      //return DocumentModel.empty(title: f.name);
      return documents.len - 1;
    }
    final doc = XmlDocument.parse(String.fromCharCodes(f.bytes!));
    documents.add(doc);
    return documents.len - 1;
  }
}
