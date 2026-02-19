import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path/path.dart' as path;

class DocumentService {
  Future<String> extractText(String filePath) async {
    final ext = path.extension(filePath).toLowerCase();
    
    switch (ext) {
      case '.pdf':
        return _extractPdfText(filePath);
      case '.txt':
        return _extractTxtText(filePath);
      default:
        throw Exception('Unsupported file format: $ext');
    }
  }

  Future<String> _extractPdfText(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    
    final text = extractor.extractText();
    document.dispose();
    
    return text;
  }

  Future<String> _extractTxtText(String filePath) async {
    final file = File(filePath);
    return file.readAsString();
  }

  Future<String> summarizeDocument(String content, {int maxLength = 3000}) async {
    final truncated = content.length > maxLength * 2 
        ? '${content.substring(0, maxLength * 2)}...' 
        : content;
    return '''Please summarize the following document:

$truncated

Provide a concise summary of the key points.''';
  }
}
