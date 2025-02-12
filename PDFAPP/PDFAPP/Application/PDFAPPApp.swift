//
//  PDFAPPApp.swift
//  PDFAPP
//
//  Created by Вячеслав Вовк on 12.02.2025.
//

import SwiftUI

@main
struct PDFAPPApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            PDFScreen()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
