import 'web_helper_stub.dart'
    if (dart.library.html) 'web_helper_web.dart' as loader;

void downloadFileWeb(List<int> bytes, String fileName, String mimeType) {
  loader.downloadFileWeb(bytes, fileName, mimeType);
}

