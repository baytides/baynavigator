import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Service for exporting and printing saved programs
public final class ExportService: Sendable {
    public static let shared = ExportService()

    private init() {}

    // MARK: - CSV Export

    /// Export programs to CSV format
    public func exportToCSV(_ programs: [Program]) -> String? {
        guard !programs.isEmpty else { return nil }

        var lines: [String] = []

        // CSV Header
        lines.append("Name,Category,Description,Groups,Areas,Website,Phone,Email,Address,Cost,Last Updated")

        // CSV Rows
        for program in programs {
            let row = [
                escapeCsv(program.name),
                escapeCsv(program.category),
                escapeCsv(program.description),
                escapeCsv(program.groups.joined(separator: "; ")),
                escapeCsv(program.areas.joined(separator: "; ")),
                escapeCsv(program.website ?? ""),
                escapeCsv(program.phone ?? ""),
                escapeCsv(program.email ?? ""),
                escapeCsv(program.address ?? ""),
                escapeCsv(program.cost ?? ""),
                escapeCsv(program.lastUpdated)
            ].joined(separator: ",")

            lines.append(row)
        }

        return lines.joined(separator: "\n")
    }

    /// Save CSV to file and return the file URL
    public func saveCSVToFile(_ programs: [Program]) async throws -> URL {
        guard let csv = exportToCSV(programs) else {
            throw ExportError.noData
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .components(separatedBy: ".").first ?? "export"

        let fileName = "baynavigator_\(timestamp).csv"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)

        try csv.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    // MARK: - Clipboard

    /// Copy a single program's info to clipboard
    public func copyToClipboard(_ program: Program) {
        var text = """
        \(program.name)
        Category: \(program.category)

        \(program.description)

        """

        if !program.groups.isEmpty {
            text += "Eligibility: \(program.groups.joined(separator: ", "))\n"
        }
        if !program.areas.isEmpty {
            text += "Areas: \(program.areas.joined(separator: ", "))\n"
        }
        if let website = program.website, !website.isEmpty {
            text += "Website: \(website)\n"
        }
        if let phone = program.phone, !phone.isEmpty {
            text += "Phone: \(phone)\n"
        }
        if let email = program.email, !email.isEmpty {
            text += "Email: \(email)\n"
        }

        setPasteboardString(text)
    }

    /// Copy all saved programs summary to clipboard
    public func copyAllToClipboard(_ programs: [Program]) {
        guard !programs.isEmpty else { return }

        var text = """
        Bay Navigator - Saved Programs
        ========================================

        """

        for program in programs {
            text += """
            \(program.name)
              Category: \(program.category)
              \(program.description)
            """

            if let website = program.website, !website.isEmpty {
                text += "\n  Website: \(website)"
            }
            text += "\n\n"
        }

        setPasteboardString(text)
    }

    // MARK: - HTML/Print

    /// Generate printable HTML
    public func generatePrintableHTML(_ programs: [Program]) -> String {
        var programsHTML = ""

        for program in programs {
            var detailsHTML = ""

            if !program.areas.isEmpty {
                detailsHTML += """
                    <div class="detail"><strong>Areas:</strong> \(escapeHtml(program.areas.joined(separator: ", ")))</div>
                """
            }
            if let website = program.website, !website.isEmpty {
                detailsHTML += """
                    <div class="detail"><strong>Website:</strong> \(escapeHtml(website))</div>
                """
            }
            if let phone = program.phone, !phone.isEmpty {
                detailsHTML += """
                    <div class="detail"><strong>Phone:</strong> \(escapeHtml(phone))</div>
                """
            }
            if let email = program.email, !email.isEmpty {
                detailsHTML += """
                    <div class="detail"><strong>Email:</strong> \(escapeHtml(email))</div>
                """
            }

            var eligibilityHTML = ""
            if !program.groups.isEmpty {
                let tags = program.groups.map { "<span>\(escapeHtml(formatGroupName($0)))</span>" }.joined()
                eligibilityHTML = """
                    <div class="eligibility">\(tags)</div>
                """
            }

            programsHTML += """
              <div class="program">
                <div class="program-name">\(escapeHtml(program.name))</div>
                <span class="category">\(escapeHtml(program.category))</span>
                <p class="description">\(escapeHtml(program.description))</p>
                \(detailsHTML)
                \(eligibilityHTML)
              </div>
            """
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: Date())

        return """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Bay Navigator - Saved Programs</title>
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              max-width: 800px;
              margin: 0 auto;
              padding: 20px;
              color: #1e293b;
            }
            h1 {
              color: #0d9488;
              border-bottom: 2px solid #0d9488;
              padding-bottom: 10px;
            }
            .program {
              border: 1px solid #e2e8f0;
              border-radius: 8px;
              padding: 16px;
              margin-bottom: 16px;
              page-break-inside: avoid;
            }
            .program-name {
              font-size: 18px;
              font-weight: 600;
              color: #0f172a;
              margin-bottom: 4px;
            }
            .category {
              display: inline-block;
              background: #0d9488;
              color: white;
              padding: 2px 8px;
              border-radius: 4px;
              font-size: 12px;
              text-transform: uppercase;
              margin-bottom: 8px;
            }
            .description {
              color: #475569;
              margin-bottom: 12px;
            }
            .detail {
              font-size: 14px;
              color: #64748b;
              margin-bottom: 4px;
            }
            .detail strong {
              color: #334155;
            }
            .eligibility {
              display: flex;
              flex-wrap: wrap;
              gap: 4px;
              margin-top: 8px;
            }
            .eligibility span {
              background: #f1f5f9;
              padding: 2px 6px;
              border-radius: 4px;
              font-size: 12px;
            }
            .footer {
              margin-top: 30px;
              text-align: center;
              color: #94a3b8;
              font-size: 12px;
            }
            @media print {
              body { padding: 0; }
              .program { border: 1px solid #ccc; }
            }
          </style>
        </head>
        <body>
          <h1>Bay Navigator</h1>
          <p style="color: #64748b;">Saved Programs (\(programs.count))</p>
        \(programsHTML)
          <div class="footer">
            Generated from Bay Navigator App - \(dateString)
          </div>
        </body>
        </html>
        """
    }

    /// Save printable HTML and return file URL
    public func saveHTMLToFile(_ programs: [Program]) async throws -> URL {
        guard !programs.isEmpty else {
            throw ExportError.noData
        }

        let html = generatePrintableHTML(programs)

        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .components(separatedBy: ".").first ?? "print"

        let fileName = "baynavigator_print_\(timestamp).html"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)

        try html.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    /// Open HTML file for printing (platform-specific)
    @MainActor
    public func openForPrinting(_ fileURL: URL) {
        #if os(macOS)
        NSWorkspace.shared.open(fileURL)
        #elseif os(iOS) || os(visionOS)
        UIApplication.shared.open(fileURL)
        #endif
    }

    // MARK: - JSON Export

    /// Export programs to JSON format
    public func exportToJSON(_ programs: [Program]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(programs)
    }

    /// Save JSON to file and return the file URL
    public func saveJSONToFile(_ programs: [Program]) async throws -> URL {
        let data = try exportToJSON(programs)

        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .components(separatedBy: ".").first ?? "export"

        let fileName = "baynavigator_\(timestamp).json"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)

        try data.write(to: fileURL)

        return fileURL
    }

    // MARK: - Private Helpers

    private func escapeCsv(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private func escapeHtml(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private func formatGroupName(_ groupId: String) -> String {
        groupId
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { word in
                guard let first = word.first else { return String(word) }
                return String(first).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }

    private func setPasteboardString(_ string: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #elseif os(iOS) || os(visionOS)
        UIPasteboard.general.string = string
        #endif
    }
}

// MARK: - Export Errors

public enum ExportError: Error, LocalizedError {
    case noData
    case fileWriteFailed
    case invalidFormat

    public var errorDescription: String? {
        switch self {
        case .noData:
            return "No programs to export"
        case .fileWriteFailed:
            return "Failed to write export file"
        case .invalidFormat:
            return "Invalid export format"
        }
    }
}

// MARK: - Export Format Options

public enum ExportFormat: String, CaseIterable, Identifiable, Sendable {
    case csv = "CSV"
    case json = "JSON"
    case html = "Print (HTML)"

    public var id: String { rawValue }

    public var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .html: return "html"
        }
    }

    public var description: String {
        switch self {
        case .csv: return "Spreadsheet format for Excel, Numbers, etc."
        case .json: return "Data format for developers"
        case .html: return "Printable document format"
        }
    }

    #if canImport(UniformTypeIdentifiers)
    @available(iOS 14.0, macOS 11.0, *)
    public var contentType: UTType {
        switch self {
        case .csv: return .commaSeparatedText
        case .json: return .json
        case .html: return .html
        }
    }
    #endif
}
