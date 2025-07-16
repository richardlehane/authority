import 'package:xml/xml.dart';

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
  
  // singleton
  Session._();
  static final Session _instance = Session._();
  factory Session() => _instance;

  int empty() {
    documents.add(XmlDocument.parse(_template));
    return documents.len - 1;
  }

  int load(PlatformFile f) {
    if (f.bytes == null) {
      return empty();
    }
    final doc = XmlDocument.parse(String.fromCharCodes(f.bytes!));
    documents.add(doc);
    return documents.len - 1;
  }

  List<TreeViewItem> tree(int index, Counter ctr) {
	XmlDocument doc = documents![index];
  	return addChildren(termsClasses(doc.rootElement), ctr)
  }

  String asString(int index) {
  	XmlDocument doc = documents![index];
  	return doc.toXmlString(pretty: true, indent: '\t');
  }
}

List<TreeViewItem> addChildren(List<XmlElement> list, Counter ctr) {
  return list.map((item) {
    final NodeType nt =
        (item.name.local == 'Term') ? NodeType.termType : NodeType.classType;
    final int index = ctr.next();
    final bool selected = ctr.isSelected();
    return TreeViewItem(
      leading:
          (nt == NodeType.termType)
              ? Icon(FluentIcons.fabric_folder)
              : Icon(FluentIcons.page),
      content: Text(title(item)),
      value: (nt, index),
      children: addChildren(termsClasses(item), ctr),
      selected: selected,
    );
  }).toList();
}

List<XmlElement> termsClasses(XmlElement el) {
  if (el.name.local == 'Class') {
    return [];
  }
  return el.childElements
      .where((e) => e.name.local == 'Term' || e.name.local == 'Class')
      .toList();
}
