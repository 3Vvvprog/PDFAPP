//
//  PDFScreen.swift
//  PDFAPP
//
//  Created by Вячеслав Вовк on 12.02.2025.
//

import SwiftUI
import PhotosUI
import PDFKit

struct PDFScreen: View {
    @StateObject private var viewModel = PDFGeneratorViewModel()
    @State private var isImagePickerPresented = false
    @State private var isDocumentPickerPresented = false
    
    let pdfPageWidth: CGFloat = UIScreen.main.bounds.width
    let pdfPageHeight: CGFloat = UIScreen.main.bounds.width / 612 * 712
        
    var body: some View {
        NavigationView {
            VStack {
                // Список изображений
                ScrollView {
                    ForEach(viewModel.images.indices, id: \.self) { index in
                        Image(uiImage: viewModel.images[index])
                            .resizable()
                            .frame(width: pdfPageWidth, height: pdfPageHeight)
                            .onTapGesture {
                                // Удаление страницы
                                viewModel.removePage(at: index)
                            }
                    }
                }
                
                Spacer()
                
                // Кнопки действий
                HStack {
                    Button(action: {
                        isImagePickerPresented = true
                    }) {
                        Text("Добавить\nизображения")
                    }
                    
                    Button(action: {
                           isDocumentPickerPresented = true
                       }) {
                           Text("Добавить\nфайл")
                       }
                    
                    Button(action: {
                        guard let pdfData = viewModel.generatePDF() else { return }
                        viewModel.savePDF(data: pdfData)
                    }) {
                        Text("Сохранить\nPDF")
                    }
                    
                    Button(action: {
                        guard let pdfData = viewModel.generatePDF() else { return }
                        sharePDF(data: pdfData)
                    }) {
                        Text("Поделиться\nPDF")
                    }
                }
                .padding()
            }
            .navigationTitle("Генератор PDF")
            .sheet(isPresented: $isImagePickerPresented) {
                MultiImagePicker(images: $viewModel.images)
            }
            .sheet(isPresented: $isDocumentPickerPresented) {
                DocumentPicker(images: $viewModel.images)
            }
        }
    }
    
    // Метод для обмена PDF
    func sharePDF(data: Data) {
        let activityViewController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }
}

struct MultiImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0 // 0 означает "без ограничений"
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiImagePicker
        
        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            // Обработка выбранных изображений
            let group = DispatchGroup()
            for result in results {
                group.enter()
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.images.append(image)
                            }
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            .image,
            .pdf
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            if url.startAccessingSecurityScopedResource() {
                if let image = UIImage(contentsOfFile: url.path) {
                    // Если файл — изображение, добавляем его в массив
                    DispatchQueue.main.async {
                        self.parent.images.append(image)
                    }
                } else if url.pathExtension.lowercased() == "pdf" {
                    // Если файл — PDF, конвертируем его страницы в изображения
                    convertPDFToImages(from: url)
                }
                
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        private func convertPDFToImages(from url: URL) {
            if let document = PDFDocument(url: url) {
                for pageNumber in 0..<document.pageCount {
                    if let page = document.page(at: pageNumber) {
                        let bounds = page.bounds(for: .mediaBox)
                        
                        // Создаем рендерер с размерами страницы
                        let renderer = UIGraphicsImageRenderer(size: bounds.size)
                        
                        // Генерируем изображение
                        let image = renderer.image { ctx in
                            // Настраиваем контекст для правильной ориентации
                            ctx.cgContext.translateBy(x: 0, y: bounds.height)
                            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                            
                            // Рисуем фон белым цветом
                            UIColor.white.set()
                            ctx.cgContext.fill(bounds)
                            
                            // Рисуем страницу PDF
                            page.draw(with: .mediaBox, to: ctx.cgContext)
                        }
                        
                        DispatchQueue.main.async {
                            self.parent.images.append(image)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PDFScreen()
}
