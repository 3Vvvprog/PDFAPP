//
//  PDFGeneratorViewModel.swift
//  PDFAPP
//
//  Created by Вячеслав Вовк on 12.02.2025.
//


import SwiftUI
import PDFKit
import UniformTypeIdentifiers

class PDFGeneratorViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    @Published var pdfData: Data?
    
    // Метод для выбора изображений
    func selectImages() {
        // Этот метод будет вызван через UIkit для выбора изображений
        print("Выбор изображений...")
    }
    
    // Метод для создания PDF из массива изображений
    func generatePDF() -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "MyApp",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Generated PDF"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let bounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        
        return renderer.pdfData  { (context) in
            for image in images {
                context.beginPage()
                let imgRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
                image.draw(in: imgRect)
            }
        }
    }
    
    // Метод для сохранения PDF
    func savePDF(data: Data) {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileName = "generated_pdf_\(Date().timeIntervalSince1970).pdf"
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            print("PDF успешно сохранен по пути: \(fileURL)")
        } catch {
            print("Ошибка при сохранении PDF: \(error.localizedDescription)")
        }
    }
    
    // Метод для удаления страницы
    func removePage(at index: Int) {
        if index >= 0 && index < images.count {
            images.remove(at: index)
        }
    }
}
