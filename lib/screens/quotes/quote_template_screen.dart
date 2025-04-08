import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/services/quote_service.dart';

class QuoteTemplateScreen extends StatefulWidget {
  final String quoteId;

  const QuoteTemplateScreen({super.key, required this.quoteId});

  @override
  State<QuoteTemplateScreen> createState() => _QuoteTemplateScreenState();
}

class _QuoteTemplateScreenState extends State<QuoteTemplateScreen> {
  final QuoteService _quoteService = GetIt.instance<QuoteService>();
  Quote? _quote;
  bool _isLoading = true;
  String _selectedTemplate = 'standard'; // Opciones: 'standard', 'detailed', 'simple'
  bool _showLogo = true;
  bool _showHeader = true;
  bool _showFooter = true;
  String _headerText = 'Electro Workshop - Presupuesto';
  String _footerText = 'Gracias por confiar en nosotros. Este presupuesto es válido por 30 días.';
  Color _primaryColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quote = await _quoteService.getQuoteById(widget.quoteId);
      setState(() {
        _quote = quote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar el presupuesto: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _printQuote() async {
    if (_quote == null) return;

    final pdf = await _generatePdf();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _shareQuote() async {
    if (_quote == null) return;

    final pdf = await _generatePdf();
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'presupuesto_${_quote!.id}.pdf',
    );
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    // Cargar fuentes
    final regularFont = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    // Cargar logo (en una app real, esto sería un asset o una imagen de la empresa)
    final ByteData logoData = await rootBundle.load('assets/images/parts.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final logo = pw.MemoryImage(logoBytes);

    // Convertir el color primario a PdfColor
    final pdfPrimaryColor = PdfColor(
      _primaryColor.red / 255,
      _primaryColor.green / 255,
      _primaryColor.blue / 255,
    );

    // Generar el PDF según la plantilla seleccionada
    if (_selectedTemplate == 'standard') {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: _showHeader
              ? (pw.Context context) => pw.Container(
                    alignment: pw.Alignment.center,
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    child: pw.Text(
                      _headerText,
                      style: pw.TextStyle(font: boldFont, fontSize: 24, color: pdfPrimaryColor),
                    ),
                  )
              : null,
          footer: _showFooter
              ? (pw.Context context) => pw.Container(
                    alignment: pw.Alignment.center,
                    margin: const pw.EdgeInsets.only(top: 20),
                    child: pw.Text(
                      _footerText,
                      style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey700),
                    ),
                  )
              : null,
          build: (pw.Context context) => [
            // Logo y datos de la empresa
            if (_showLogo)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logo, width: 100, height: 100),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Electro Workshop S.L.',
                          style: pw.TextStyle(font: boldFont, fontSize: 16)),
                      pw.Text('C/ Ejemplo 123, 28001 Madrid',
                          style: pw.TextStyle(font: regularFont, fontSize: 12)),
                      pw.Text('Tel: +34 912 345 678',
                          style: pw.TextStyle(font: regularFont, fontSize: 12)),
                      pw.Text('Email: info@electroworkshop.es',
                          style: pw.TextStyle(font: regularFont, fontSize: 12)),
                      pw.Text('CIF: B12345678',
                          style: pw.TextStyle(font: regularFont, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            pw.SizedBox(height: 20),

            // Información del presupuesto
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: pdfPrimaryColor.shade(50),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PRESUPUESTO',
                          style: pw.TextStyle(font: boldFont, fontSize: 20, color: pdfPrimaryColor)),
                      pw.Text('Nº: ${_quote!.id}',
                          style: pw.TextStyle(font: boldFont, fontSize: 14)),
                      pw.Text('Fecha: ${dateFormat.format(_quote!.createdAt)}',
                          style: pw.TextStyle(font: regularFont, fontSize: 12)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: _getStatusPdfColor(_quote!.status as QuoteStatus),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      _getStatusText(_quote!.status as QuoteStatus),
                      style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.white),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Información del cliente y dispositivo
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pdfPrimaryColor.shade(200)),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DATOS DEL CLIENTE',
                      style: pw.TextStyle(font: boldFont, fontSize: 14, color: pdfPrimaryColor)),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildPdfInfoRow('Nombre', _quote!.repairOrder!.customer!.name, regularFont, boldFont),
                            _buildPdfInfoRow('Teléfono', _quote!.repairOrder!.customer!.phone, regularFont, boldFont),
                            _buildPdfInfoRow('Email', _quote!.repairOrder!.customer!.email ?? 'N/A', regularFont, boldFont),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('DISPOSITIVOS',
                                style: pw.TextStyle(font: boldFont, fontSize: 12, color: pdfPrimaryColor)),
                            pw.SizedBox(height: 5),
                            // Display multiple devices from repair order items
                            if (_quote!.repairOrder?.items != null && _quote!.repairOrder!.items.isNotEmpty)
                              ...List.generate(_quote!.repairOrder!.items.length, (index) {
                                final device = _quote!.repairOrder!.items[index];
                                return pw.Text(
                                  '• ${device.deviceType ?? 'N/A'} ${device.brand ?? ''} ${device.model ?? ''}',
                                  style: pw.TextStyle(font: regularFont, fontSize: 10),
                                );
                              })
                            else
                              pw.Text('No hay dispositivos disponibles',
                                  style: pw.TextStyle(font: regularFont, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Detalles del presupuesto
            pw.Text('DETALLES DEL PRESUPUESTO',
                style: pw.TextStyle(font: boldFont, fontSize: 14, color: pdfPrimaryColor)),
            pw.SizedBox(height: 10),

            // Tabla de ítems
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Encabezado de la tabla
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: pdfPrimaryColor.shade(200)),
                  children: [
                    _buildTableHeader('Descripción', boldFont),
                    _buildTableHeader('Cant.', boldFont),
                    _buildTableHeader('Precio', boldFont),
                    _buildTableHeader('Total', boldFont),
                  ],
                ),
                // Filas de ítems
                ..._quote!.items.map((item) => pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: item.isLabor ? pdfPrimaryColor.shade(50) : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell(item.description, regularFont),
                        _buildTableCell(item.quantity.toString(), regularFont, alignment: pw.Alignment.center),
                        _buildTableCell(currencyFormat.format(item.price), regularFont, alignment: pw.Alignment.centerRight),
                        _buildTableCell(currencyFormat.format(item.total), regularFont, alignment: pw.Alignment.centerRight),
                      ],
                    )),
              ],
            ),
            pw.SizedBox(height: 20),

            // Resumen de precios
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Divider(color: PdfColors.grey300),
                  _buildPdfPriceRow(
                    'TOTAL',
                    currencyFormat.format(_quote!.totalAmount),
                    boldFont,
                    boldFont,
                    fontSize: 14,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pdfPrimaryColor.shade(200)),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('CONDICIONES',
                      style: pw.TextStyle(font: boldFont, fontSize: 12, color: pdfPrimaryColor)),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    '1. Este presupuesto es válido hasta la fecha indicada.\n'
                    '2. Los precios incluyen IVA.\n'
                    '3. El tiempo estimado de reparación es de 3-7 días laborables.\n'
                    '4. La garantía de la reparación es de 3 meses.\n'
                    '5. El pago se realizará al 50% para iniciar la reparación y el restante al recoger el dispositivo.\n',
                    style: pw.TextStyle(font: regularFont, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_selectedTemplate == 'detailed') {
      // Implementación de la plantilla detallada
      // Similar a la estándar pero con más detalles y otro diseño
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: _showHeader
              ? (pw.Context context) => pw.Container(
                    alignment: pw.Alignment.center,
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    child: pw.Text(
                      _headerText,
                      style: pw.TextStyle(font: boldFont, fontSize: 24, color: pdfPrimaryColor),
                    ),
                  )
              : null,
          footer: _showFooter
              ? (pw.Context context) => pw.Container(
                    alignment: pw.Alignment.center,
                    margin: const pw.EdgeInsets.only(top: 20),
                    child: pw.Text(
                      _footerText,
                      style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey700),
                    ),
                  )
              : null,
          build: (pw.Context context) => [
            // Contenido similar al estándar pero con más detalles
            // y un diseño diferente
            if (_showLogo)
              pw.Center(
                child: pw.Image(logo, width: 150, height: 150),
              ),
            pw.SizedBox(height: 20),
            
            pw.Center(
              child: pw.Text(
                'PRESUPUESTO DETALLADO',
                style: pw.TextStyle(font: boldFont, fontSize: 24, color: pdfPrimaryColor),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Nº: ${_quote!.id} - Fecha: ${dateFormat.format(_quote!.createdAt)}',
                style: pw.TextStyle(font: regularFont, fontSize: 14),
              ),
            ),
            pw.SizedBox(height: 30),
            
            // Información de la empresa
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: pdfPrimaryColor.shade(50),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DATOS DE LA EMPRESA',
                      style: pw.TextStyle(font: boldFont, fontSize: 16, color: pdfPrimaryColor)),
                  pw.SizedBox(height: 10),
                  _buildPdfInfoRow('Nombre', 'Electro Workshop S.L.', regularFont, boldFont),
                  _buildPdfInfoRow('Dirección', 'C/ Ejemplo 123, 28001 Madrid', regularFont, boldFont),
                  _buildPdfInfoRow('Teléfono', '+34 912 345 678', regularFont, boldFont),
                  _buildPdfInfoRow('Email', 'info@electroworkshop.es', regularFont, boldFont),
                  _buildPdfInfoRow('CIF', 'B12345678', regularFont, boldFont),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Información del cliente y dispositivo
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DATOS DEL CLIENTE',
                      style: pw.TextStyle(font: boldFont, fontSize: 16, color: pdfPrimaryColor)),
                  pw.SizedBox(height: 10),
                  _buildPdfInfoRow('Nombre', _quote!.customer?.name ?? 'N/A', regularFont, boldFont),
                  _buildPdfInfoRow('Teléfono', _quote!.customer?.phone ?? 'N/A', regularFont, boldFont),
                  _buildPdfInfoRow('Email', _quote!.customer?.email ?? 'N/A', regularFont, boldFont),
                  _buildPdfInfoRow('Dirección', _quote!.customer?.address ?? 'N/A', regularFont, boldFont),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Información del dispositivo
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DATOS DE DISPOSITIVOS',
                      style: pw.TextStyle(font: boldFont, fontSize: 16, color: pdfPrimaryColor)),
                  pw.SizedBox(height: 10),
                  
                  // Display multiple devices from repair order items
                  if (_quote!.repairOrder?.items != null && _quote!.repairOrder!.items.isNotEmpty)
                    ...List.generate(_quote!.repairOrder!.items.length, (index) {
                      final device = _quote!.repairOrder!.items[index];
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (index > 0) pw.SizedBox(height: 10),
                          pw.Text(
                            'Dispositivo ${index + 1}:',
                            style: pw.TextStyle(font: boldFont, fontSize: 12, color: pdfPrimaryColor),
                          ),
                          _buildPdfInfoRow('Tipo', device.deviceType ?? 'N/A', regularFont, boldFont),
                          _buildPdfInfoRow('Marca', device.brand ?? 'N/A', regularFont, boldFont),
                          _buildPdfInfoRow('Modelo', device.model ?? 'N/A', regularFont, boldFont),
                          _buildPdfInfoRow('Nº Serie', device.serialNumber ?? 'N/A', regularFont, boldFont),
                          if (device.problemDescription != null && device.problemDescription.isNotEmpty)
                            _buildPdfInfoRow('Problema', device.problemDescription, regularFont, boldFont),
                        ],
                      );
                    })
                  else
                    pw.Text('No hay dispositivos disponibles',
                        style: pw.TextStyle(font: regularFont, fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Detalles del presupuesto
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: pdfPrimaryColor.shade(50),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DETALLES DEL PRESUPUESTO',
                      style: pw.TextStyle(font: boldFont, fontSize: 16, color: pdfPrimaryColor)),
                  pw.SizedBox(height: 10),
                  
                  // Tabla de ítems
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(4),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      // Encabezado de la tabla
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: pdfPrimaryColor),
                        children: [
                          _buildTableHeader('Descripción', boldFont, textColor: PdfColors.white),
                          _buildTableHeader('Cant.', boldFont, textColor: PdfColors.white),
                          _buildTableHeader('Precio', boldFont, textColor: PdfColors.white),
                          _buildTableHeader('Total', boldFont, textColor: PdfColors.white),
                        ],
                      ),
                      // Filas de ítems
                      ..._quote!.items.map((item) => pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: item.isLabor ? pdfPrimaryColor.shade(50) : PdfColors.white,
                            ),
                            children: [
                              _buildTableCell(item.description, regularFont),
                              _buildTableCell(item.quantity.toString(), regularFont, alignment: pw.Alignment.center),
                              _buildTableCell(currencyFormat.format(item.price), regularFont, alignment: pw.Alignment.centerRight),
                              _buildTableCell(currencyFormat.format(item.total), regularFont, alignment: pw.Alignment.centerRight),
                            ],
                          )),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Resumen de precios
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        
                        pw.Divider(color: PdfColors.grey300),
                        _buildPdfPriceRow(
                          'TOTAL',
                          currencyFormat.format(_quote!.totalAmount),
                          boldFont,
                          boldFont,
                          fontSize: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            // Condiciones y firma
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pdfPrimaryColor),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('CONDICIONES Y TÉRMINOS',
                      style: pw.TextStyle(font: boldFont, fontSize: 14, color: pdfPrimaryColor)),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '3. El tiempo estimado de reparación es de 3-5 días laborables una vez aprobado el presupuesto.\n'
                    '4. La garantía de la reparación es de 3 meses.\n'
                    '5. El pago se realizará un 50% para iniciar y el resto al recoger el dispositivo.\n'
                    '6. La aprobación de este presupuesto implica la aceptación de estas condiciones.\n',
                    style: pw.TextStyle(font: regularFont, fontSize: 10),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Firma del técnico:',
                              style: pw.TextStyle(font: boldFont, fontSize: 10)),
                          pw.SizedBox(height: 40),
                          pw.Container(
                            width: 150,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Firma del cliente:',
                              style: pw.TextStyle(font: boldFont, fontSize: 10)),
                          pw.SizedBox(height: 40),
                          pw.Container(
                            width: 150,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_selectedTemplate == 'simple') {
      // Implementación de la plantilla simple
      // Una versión más minimalista y directa
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: _showHeader
              ? (pw.Context context) => pw.Container(
                    alignment: pw.Alignment.center,
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    child: pw.Text(
                      _headerText,
                      style: pw.TextStyle(font: boldFont, fontSize: 20, color: pdfPrimaryColor),
                    ),
                  )
              : null,
          footer: _showFooter
              ? (pw.Context context) => pw.Container(
                    alignment: pw.Alignment.center,
                    margin: const pw.EdgeInsets.only(top: 20),
                    child: pw.Text(
                      _footerText,
                      style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey700),
                    ),
                  )
              : null,
          build: (pw.Context context) => [
            // Encabezado simple con información básica
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: pdfPrimaryColor.shade(50),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (_showLogo) pw.Image(logo, width: 50, height: 50),
                      pw.SizedBox(height: 10),
                      pw.Text('PRESUPUESTO',
                          style: pw.TextStyle(font: boldFont, fontSize: 18, color: pdfPrimaryColor)),
                      pw.Text('Nº: ${_quote!.id}',
                          style: pw.TextStyle(font: boldFont, fontSize: 12)),
                      pw.Text('Fecha: ${dateFormat.format(_quote!.createdAt)}',
                          style: pw.TextStyle(font: regularFont, fontSize: 10)),
                      
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Electrónica Pimentel',
                          style: pw.TextStyle(font: boldFont, fontSize: 14)),
                      pw.Text('Tel: +51 928 520 320',
                          style: pw.TextStyle(font: regularFont, fontSize: 10)),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const pw.EdgeInsets.only(top: 5),
                        decoration: pw.BoxDecoration(
                          color: _getStatusPdfColor(_quote!.status as QuoteStatus),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          _getStatusText(_quote!.status as QuoteStatus),
                          style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Información básica del cliente y dispositivo
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CLIENTE',
                            style: pw.TextStyle(font: boldFont, fontSize: 12, color: pdfPrimaryColor)),
                        pw.SizedBox(height: 5),
                        pw.Text(_quote!.customer!.name,
                            style: pw.TextStyle(font: regularFont, fontSize: 10)),
                        pw.Text(_quote!.customer!.phone,
                            style: pw.TextStyle(font: regularFont, fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DISPOSITIVOS',
                            style: pw.TextStyle(font: boldFont, fontSize: 12, color: pdfPrimaryColor)),
                        pw.SizedBox(height: 5),
                        // Display multiple devices
                        if (_quote!.repairOrder?.items != null && _quote!.repairOrder!.items.isNotEmpty)
                          ...List.generate(_quote!.repairOrder!.items.length, (index) {
                            final device = _quote!.repairOrder!.items[index];
                            return pw.Text(
                              '• ${device.deviceType ?? 'N/A'} ${device.brand ?? ''} ${device.model ?? ''}',
                              style: pw.TextStyle(font: regularFont, fontSize: 10),
                            );
                          })
                        else
                          pw.Text('No hay dispositivos disponibles',
                              style: pw.TextStyle(font: regularFont, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tabla simplificada de ítems
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                // Encabezado de la tabla
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: pdfPrimaryColor.shade(200)),
                  children: [
                    _buildTableHeader('Descripción', boldFont),
                    _buildTableHeader('Cant.', boldFont),
                    _buildTableHeader('Importe', boldFont),
                  ],
                ),
                // Filas de ítems
                ..._quote!.items.map((item) => pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: item.isLabor ? pdfPrimaryColor.shade(50) : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell(item.description, regularFont),
                        _buildTableCell(item.quantity.toString(), regularFont, alignment: pw.Alignment.center),
                        _buildTableCell(currencyFormat.format(item.total), regularFont, alignment: pw.Alignment.centerRight),
                      ],
                    )),
              ],
            ),
            pw.SizedBox(height: 20),

            // Resumen de precios simplificado
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Divider(color: PdfColors.grey300),
                  _buildPdfPriceRow(
                    'TOTAL',
                    currencyFormat.format(_quote!.totalAmount),
                    boldFont,
                    boldFont,
                    fontSize: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
        
      );
    }
return pdf;
}

String _getStatusText(QuoteStatus status) {
  switch (status) {
    case QuoteStatus.PENDING:
      return 'Pendiente';
    case QuoteStatus.APPROVED:
      return 'Aprobado';
    case QuoteStatus.REJECTED:
      return 'Rechazado';
    case QuoteStatus.EXPIRED:
      return 'Expirado';
    default:
      return 'Desconocido';
  }
}

PdfColor _getStatusPdfColor(QuoteStatus status) {
  switch (status) {
    // ignore: constant_pattern_never_matches_value_type
    case QuoteStatus.PENDING:
      return PdfColors.orange;
    case QuoteStatus.APPROVED:
      return PdfColors.green;
    case QuoteStatus.REJECTED:
      return PdfColors.red;
    case QuoteStatus.EXPIRED:
      return PdfColors.purple;
    default:
      return PdfColors.grey;
  }
}

pw.Widget _buildPdfInfoRow(String label, String value, pw.Font regularFont, pw.Font boldFont) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(font: boldFont, fontSize: 10),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: regularFont, fontSize: 10),
          ),
        ),],
      ),
    );
  }

pw.Widget _buildTableHeader(String text, pw.Font font, {PdfColor textColor = PdfColors.black}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Text(
      text,
      style: pw.TextStyle(font: font, fontSize: 10, color: textColor),
      textAlign: pw.TextAlign.center,
    ),
  );
}

pw.Widget _buildTableCell(String text, pw.Font font, {pw.Alignment alignment = pw.Alignment.centerLeft}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Align(
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
    ),
  );
}

pw.Widget _buildPdfPriceRow(String label, String value, pw.Font regularFont, pw.Font boldFont, {double fontSize = 10}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: regularFont, fontSize: fontSize),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(font: boldFont, fontSize: fontSize),
        ),
      ],
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantilla de Presupuesto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _isLoading ? null : _printQuote,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isLoading ? null : _shareQuote,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quote == null
              ? const Center(child: Text('No se encontró el presupuesto'))
              : Column(
                  children: [
                    Expanded(
                      child: PdfPreview(
                        build: (format) => _generatePdf().then((pdf) => pdf.save()),
                        allowPrinting: false,
                        allowSharing: false,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                      ),
                    ),
                    _buildOptionsPanel(),
                  ],
                ),
    );
  }

  Widget _buildOptionsPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Personalizar Plantilla',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restablecer'),
                  onPressed: () {
                    setState(() {
                      _selectedTemplate = 'standard';
                      _showLogo = true;
                      _showHeader = true;
                      _showFooter = true;
                      _headerText = 'Electro Workshop - Presupuesto';
                      _footerText = 'Gracias por confiar en nosotros. Este presupuesto es válido por 30 días.';
                      _primaryColor = Colors.blue;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sección de plantilla y color
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estilo General',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Plantilla',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.article_outlined),
                            ),
                            value: _selectedTemplate,
                            items: const [
                              DropdownMenuItem(value: 'standard', child: Text('Estándar')),
                              DropdownMenuItem(value: 'detailed', child: Text('Detallada')),
                              DropdownMenuItem(value: 'simple', child: Text('Simple')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedTemplate = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<Color>(
                            decoration: const InputDecoration(
                              labelText: 'Color Principal',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.color_lens),
                            ),
                            value: _primaryColor,
                            items: [
                              DropdownMenuItem(value: Colors.blue, child: _colorOption('Azul', Colors.blue)),
                              DropdownMenuItem(value: Colors.green, child: _colorOption('Verde', Colors.green)),
                              DropdownMenuItem(value: Colors.red, child: _colorOption('Rojo', Colors.red)),
                              DropdownMenuItem(value: Colors.purple, child: _colorOption('Morado', Colors.purple)),
                              DropdownMenuItem(value: Colors.orange, child: _colorOption('Naranja', Colors.orange)),
                              DropdownMenuItem(value: Colors.teal, child: _colorOption('Turquesa', Colors.teal)),
                              DropdownMenuItem(value: Colors.indigo, child: _colorOption('Índigo', Colors.indigo)),
                              DropdownMenuItem(value: Colors.brown, child: _colorOption('Marrón', Colors.brown)),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _primaryColor = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Sección de elementos a mostrar
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Elementos a Mostrar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 0.0,
                      children: [
                        SizedBox(
                          width: 180,
                          child: SwitchListTile(
                            title: const Text('Logo'),
                            subtitle: const Text('Mostrar logo de empresa'),
                            value: _showLogo,
                            onChanged: (value) {
                              setState(() {
                                _showLogo = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: SwitchListTile(
                            title: const Text('Encabezado'),
                            subtitle: const Text('Mostrar texto superior'),
                            value: _showHeader,
                            onChanged: (value) {
                              setState(() {
                                _showHeader = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: SwitchListTile(
                            title: const Text('Pie de página'),
                            subtitle: const Text('Mostrar texto inferior'),
                            value: _showFooter,
                            onChanged: (value) {
                              setState(() {
                                _showFooter = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Sección de textos personalizados
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Textos Personalizados',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_showHeader) ...[                      
                      TextFormField(
                        initialValue: _headerText,
                        decoration: const InputDecoration(
                          labelText: 'Texto del Encabezado',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _headerText = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_showFooter) ...[                      
                      TextFormField(
                        initialValue: _footerText,
                        decoration: const InputDecoration(
                          labelText: 'Texto del Pie de Página',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.format_align_center),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _footerText = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.preview),
                  label: const Text('Vista Previa'),
                  onPressed: () {
                    // La vista previa ya se actualiza automáticamente con setState
                    _showSuccessSnackBar('Vista previa actualizada');
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir'),
                  onPressed: _printQuote,
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                  onPressed: _shareQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorOption(String name, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(name),
      ],
    );
  }
}