import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../config/currency_helper.dart';
import '../models/vente.dart';
import '../models/prescription.dart';

class LigneRecuData {
  final String medicamentNom;
  final int quantite;
  final double prixUnitaire;
  LigneRecuData({required this.medicamentNom, required this.quantite, required this.prixUnitaire});
  double get sousTotal => prixUnitaire * quantite;
}

class PdfService {
  static Future<Uint8List> generateSaleReceipt(Vente vente, {List<LigneRecuData>? lignesRecu}) async {
    final lignes = lignesRecu ?? vente.lignes.map((l) => LigneRecuData(
      medicamentNom: l.medicamentNom,
      quantite: l.quantite.toInt(),
      prixUnitaire: l.prixUnitaire,
    )).toList();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 297 * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.all(16),
        build: (context) => [
          pw.Center(child: pw.Text('TICKET DE CAISSE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 8),
          pw.Center(child: pw.Text('Vente #${vente.numero}', style: const pw.TextStyle(fontSize: 12))),
          pw.Center(child: pw.Text('Date: ${vente.dateVente}', style: const pw.TextStyle(fontSize: 10))),
          pw.Divider(),
          pw.SizedBox(height: 8),
          ...lignes.map((l) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text('${l.medicamentNom} x${l.quantite.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10))),
              pw.Text('${l.sousTotal.toStringAsFixed(0)} ${AppCurrency.symbol}', style: const pw.TextStyle(fontSize: 10)),
            ],
          )),
          pw.Divider(),
          pw.SizedBox(height: 8),
          _totalRow('Total', '${vente.montantTotal.toStringAsFixed(0)} ${AppCurrency.symbol}'),
          if (vente.remise > 0) _totalRow('Remise', '-${vente.remise.toStringAsFixed(0)} ${AppCurrency.symbol}'),
          _totalRow('Net à payer', '${vente.montantNet.toStringAsFixed(0)} ${AppCurrency.symbol}', bold: true),
          pw.SizedBox(height: 16),
          pw.Center(child: pw.Text('Merci de votre visite !', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> generatePrescription(Prescription p) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => pw.Column(children: [
          pw.Center(child: pw.Text('ORDONNANCE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('N°: ${p.numero}', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Date: ${p.datePrescription ?? ''}', style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),
          _info('Patient', p.clientNom ?? 'N/A'),
          _info('Médecin', p.medecinNom ?? 'N/A'),
          _info('Spécialité', p.medecinSpecialite ?? 'N/A'),
          _info('Validité', p.dateValidite ?? 'N/A'),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('Médicaments prescrits:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ...p.lignes.map((l) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ${l.medicamentNom}  (${l.quantite.toStringAsFixed(0)})', style: const pw.TextStyle(fontSize: 11)),
                if (l.posologie != null || l.duree != null)
                  pw.Text('  ${l.posologie ?? ''}${l.posologie != null && l.duree != null ? ' - ' : ''}${l.duree != null ? '${l.duree} jours' : ''}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ],
            ),
          )),
          if (p.notes != null && p.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _info('Notes', p.notes!),
          ],
          pw.SizedBox(height: 24),
          pw.Center(child: pw.Text('Cachet et signature du médecin', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
        ]),
      ),
    );
    return doc.save();
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _info(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static Future<void> preview(BuildContext context, Uint8List pdf, String title) async {
    await Printing.layoutPdf(onLayout: (_) => pdf);
  }

  static Future<void> saveAndOpen(Uint8List pdf, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdf);
    await OpenFile.open(file.path);
  }
}
