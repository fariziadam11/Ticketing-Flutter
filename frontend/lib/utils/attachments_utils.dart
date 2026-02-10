import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

/// Helper untuk mengubah list [PlatformFile] menjadi list [http.MultipartFile]
/// dengan nama field `attachments` (sesuai backend & web frontend).
Future<List<http.MultipartFile>> buildAttachmentMultipartFiles(
  List<PlatformFile> files,
) async {
  final List<http.MultipartFile> multipartFiles = [];

  for (final file in files) {
    if (file.path != null) {
      multipartFiles.add(
        await http.MultipartFile.fromPath(
          'attachments',
          file.path!,
          filename: file.name,
        ),
      );
    } else if (file.bytes != null) {
      multipartFiles.add(
        http.MultipartFile.fromBytes(
          'attachments',
          file.bytes!,
          filename: file.name,
        ),
      );
    }
  }

  return multipartFiles;
}


