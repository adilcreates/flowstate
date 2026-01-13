//
//  PDFGenerator.swift
//  Flowstate
//
//  PDF export functionality
//

import Foundation
import AppKit
import PDFKit
import UniformTypeIdentifiers

class PDFGenerator {
    private let fontSize: CGFloat
    private let fontName: String
    private let lineHeight: CGFloat

    init(fontSize: CGFloat = 18, fontName: String = "Lato-Regular", lineHeight: CGFloat = 10) {
        self.fontSize = fontSize
        self.fontName = fontName
        self.lineHeight = lineHeight
    }

    // MARK: - Export

    /// Export a note to PDF with save dialog
    func exportNote(_ note: Note) {
        let suggestedFilename = extractTitleFromContent(note.content, date: note.displayDate) + ".pdf"

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.pdf]
        savePanel.nameFieldStringValue = suggestedFilename
        savePanel.isExtensionHidden = false

        if savePanel.runModal() == .OK, let url = savePanel.url {
            if let pdfData = createPDF(from: note.content) {
                do {
                    try pdfData.write(to: url)
                    print("Successfully exported PDF to: \(url.path)")
                } catch {
                    print("Error writing PDF: \(error)")
                }
            }
        }
    }

    // MARK: - PDF Creation

    func createPDF(from text: String) -> Data? {
        // Letter size page dimensions
        let pageWidth: CGFloat = 612.0  // 8.5 x 72
        let pageHeight: CGFloat = 792.0 // 11 x 72
        let margin: CGFloat = 72.0      // 1-inch margins

        // Calculate content area
        let contentRect = CGRect(
            x: margin,
            y: margin,
            width: pageWidth - (margin * 2),
            height: pageHeight - (margin * 2)
        )

        // Create PDF data container
        let pdfData = NSMutableData()

        // Configure text formatting attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineHeight

        let font = NSFont(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0),
            .paragraphStyle: paragraphStyle
        ]

        // Trim the initial newlines before creating the PDF
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Create the attributed string with formatting
        let attributedString = NSAttributedString(string: trimmedText, attributes: textAttributes)

        // Create a Core Text framesetter for text layout
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)

        // Create a PDF context with the data consumer
        guard let pdfContext = CGContext(consumer: CGDataConsumer(data: pdfData as CFMutableData)!, mediaBox: nil, nil) else {
            print("Failed to create PDF context")
            return nil
        }

        // Track position within text
        var currentRange = CFRange(location: 0, length: 0)
        var pageIndex = 0

        // Create a path for the text frame
        let framePath = CGMutablePath()
        framePath.addRect(contentRect)

        // Continue creating pages until all text is processed
        while currentRange.location < attributedString.length {
            // Begin a new PDF page
            pdfContext.beginPage(mediaBox: nil)

            // Fill the page with white background
            pdfContext.setFillColor(NSColor.white.cgColor)
            pdfContext.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

            // Create a frame for this page's text
            let frame = CTFramesetterCreateFrame(
                framesetter,
                currentRange,
                framePath,
                nil
            )

            // Draw the text frame
            CTFrameDraw(frame, pdfContext)

            // Get the range of text that was actually displayed in this frame
            let visibleRange = CTFrameGetVisibleStringRange(frame)

            // Move to the next block of text for the next page
            currentRange.location += visibleRange.length

            // Finish the page
            pdfContext.endPage()
            pageIndex += 1

            // Safety check - don't allow infinite loops
            if pageIndex > 1000 {
                print("Safety limit reached - stopping PDF generation")
                break
            }
        }

        // Finalize the PDF document
        pdfContext.closePDF()

        return pdfData as Data
    }

    // MARK: - Helpers

    /// Extract a title from entry content for PDF filename
    func extractTitleFromContent(_ content: String, date: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedContent.isEmpty {
            return "Entry \(date)"
        }

        // Split content into words
        let words = trimmedContent
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { word in
                word.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:\"'()[]{}<>"))
                    .lowercased()
            }
            .filter { !$0.isEmpty }

        // Use first 4 words if available
        if words.count >= 4 {
            return "\(words[0])-\(words[1])-\(words[2])-\(words[3])"
        }

        if !words.isEmpty {
            return words.joined(separator: "-")
        }

        return "Entry \(date)"
    }
}
