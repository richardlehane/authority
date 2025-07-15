import 'package:xml/xml.dart' show XmlElement;

const String _template = '''
<?xml version="1.0" encoding="UTF-8"?>
<Authority xmlns="http://www.records.nsw.gov.au/schemas/RDA">
	<Term itemno="1.0.0" type="function">
    <Term itemno="1.1.0" type="activity">
      <Class itemno="1.1.1" />
		</Term>
	</Term>
</Authority>
''';

class Session {
  List<XmlDocument>? documents;

  int empty() {
    documents.add(XmlDocument.parse(_template));
    return documents.len - 1;
  }

  int load(PlatformFile f) {
    if (f.bytes == null) {
      //return DocumentModel.empty(title: f.name);
      return documents.len - 1;
    }
    final doc = XmlDocument.parse(String.fromCharCodes(f.bytes!));
    documents.add(doc);
    return documents.len - 1;
  }
}
