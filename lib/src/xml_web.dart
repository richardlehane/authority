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
  List<XmlDocument> documents;
  
  // singleton
  Session._();
  static final Session _instance = Session._();
  factory Session() => _instance;

  int empty() {
    documents.add(XmlDocument.parse(_template));
    return documents.length - 1;
  }

  int load(PlatformFile f) {
    if (f.bytes == null) {
      return empty();
    }
    final doc = XmlDocument.parse(String.fromCharCodes(f.bytes!));
    documents.add(doc);
    return documents.length - 1;
  }

  List<TreeViewItem> tree(int index, Counter ctr) => documents[index].addChildren(termsClasses(doc.rootElement), ctr);
  String asString(int index) => documents[index].toXmlString(pretty: true, indent: '\t');
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

String title(XmlElement el) {
  String? itemno = el.getAttribute("itemno");
  XmlElement? t =
      (el.name.local == 'Class')
          ? el.getElement('ClassTitle')
          : el.getElement('TermTitle');
  return (itemno != null)
      ? (t != null)
          ? "$itemno ${t.innerText}"
          : itemno
      : (t != null)
      ? t.innerText
      : '';
}

XmlElement? nth(XmlDocument? doc, int n) {
  int idx = -1;
  XmlElement? descend(XmlElement el) {
    for (XmlElement child in el.childElements.where(
      (e) => e.name.local == 'Term' || e.name.local == 'Class',
    )) {
      idx++;
      if (idx == n) {
        return child;
      }
      if (child.name.local == 'Term') {
        var ret = descend(child);
        if (ret != null) {
          return ret;
        }
      }
    }
    return null;
  }

  if (doc == null) {
    return null;
  }
  return descend(doc.rootElement);
}
