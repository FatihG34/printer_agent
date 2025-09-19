package com.alpidiprinteragent.alpidiprinteragent.service;

import java.io.ByteArrayInputStream;
import java.net.URI;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import javax.print.Doc;
import javax.print.DocFlavor;
import javax.print.DocPrintJob;
import javax.print.PrintService;
import javax.print.PrintServiceLookup;
import javax.print.SimpleDoc;
import javax.print.attribute.Attribute;
import javax.print.attribute.HashPrintRequestAttributeSet;
import javax.print.attribute.PrintRequestAttributeSet;
import javax.print.attribute.PrintServiceAttributeSet;
import javax.print.attribute.standard.PrinterLocation;
import javax.print.attribute.standard.PrinterURI;
import org.springframework.stereotype.Service;

@Service
public class PrinterService {
  public List<String> getPrinters() {
    PrintService[] services = PrintServiceLookup.lookupPrintServices(null, null);
    return Arrays.stream(services).map(PrintService::getName).collect(Collectors.toList());
  }

  public void printPdf(String printerName, byte[] pdfData) throws Exception {
    PrintService[] services = PrintServiceLookup.lookupPrintServices(null, null);

    PrintService selectedPrinter =
        Arrays.stream(services)
            .filter(p -> p.getName().equalsIgnoreCase(printerName))
            .findFirst()
            .orElseThrow(() -> new Exception("Printer not found: " + printerName));

    DocFlavor flavor = DocFlavor.INPUT_STREAM.AUTOSENSE;
    DocPrintJob job = selectedPrinter.createPrintJob();

    try (ByteArrayInputStream bais = new ByteArrayInputStream(pdfData)) {
      Doc doc = new SimpleDoc(bais, flavor, null);
      PrintRequestAttributeSet attrs = new HashPrintRequestAttributeSet();
      job.print(doc, attrs);
    }
  }

  public static class PrinterDetails {
    private String name;
    private String location;
    private URI uri;
    private String allAttributes;

    public PrinterDetails(String name, String location, URI uri, String allAttributes) {
      this.name = name;
      this.location = location;
      this.uri = uri;
      this.allAttributes = allAttributes;
    }

    // Getter metotları
    public String getName() {
      return name;
    }

    public String getLocation() {
      return location;
    }

    public URI getUri() {
      return uri;
    }

    public String getAllAttributes() {
      return allAttributes;
    }
  }

  public List<PrinterDetails> getPrintersDetails() {
    PrintService[] services = PrintServiceLookup.lookupPrintServices(null, null);

    return Arrays.stream(services)
        .map(
            p -> {
              String printerLocation = "Not specified";
              URI printerUri = null;
              StringBuilder attrs = new StringBuilder();

              PrintServiceAttributeSet attributeSet = p.getAttributes();
              if (attributeSet != null) {
                // Yazıcının fiziksel konumunu almaya çalış
                PrinterLocation locationAttribute =
                    (PrinterLocation) attributeSet.get(PrinterLocation.class);
                if (locationAttribute != null) {
                  printerLocation = locationAttribute.getValue();
                }

                // Yazıcının URI'ını (ağ adresini) almaya çalış
                PrinterURI uriAttribute = (PrinterURI) attributeSet.get(PrinterURI.class);
                if (uriAttribute != null) {
                  printerUri = uriAttribute.getURI();
                }

                // Diğer tüm öznitelikleri birleştir
                for (Attribute attribute : attributeSet.toArray()) {
                  attrs
                      .append(attribute.getName())
                      .append(": ")
                      .append(attribute.toString())
                      .append(", ");
                }
              }
              String attributeString =
                  attrs.length() > 0
                      ? attrs.substring(0, attrs.length() - 2)
                      : "No attributes found";

              return new PrinterDetails(p.getName(), printerLocation, printerUri, attributeString);
            })
        .collect(Collectors.toList());
  }
}
