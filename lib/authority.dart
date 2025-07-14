export 'src/authority_none.dart' // Stub implementation
    if (dart.library.io) 'src/authority_win.dart' // dart:io implementation
    if (dart.library.js_interop) 'src/authority_web.dart'; // package:web implementation
