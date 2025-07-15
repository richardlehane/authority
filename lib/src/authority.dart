import 'authority_none.dart' // Stub implementation
    if (dart.library.io) 'authority_win.dart' // dart:io implementation
    if (dart.library.js_interop) 'authority_web.dart'; // package:web implementation
import 'package:xml/xml.dart' show XmlElement;
import 'package:fluent_ui/fluent_ui.dart' show TreeViewItem;

const String _blank = '''
<?xml version="1.0" encoding="UTF-8"?>
<Authority xmlns="http://www.records.nsw.gov.au/schemas/RDA">
	<Term itemno="1.0.0" type="function">
    <Term itemno="1.1.0" type="activity">
      <Class itemno="1.1.1" />
		</Term>
	</Term>
</Authority>
''';

