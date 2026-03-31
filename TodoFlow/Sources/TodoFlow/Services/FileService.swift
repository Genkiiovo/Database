import Foundation
import AppKit

// MARK: - FileService
// Scans a local folder and auto-categorises files by name / extension.

enum FileService {

    // MARK: - Public API

    static func defaultFolderPath(for courseName: String) -> String {
        let desktop = FileManager.default
            .urls(for: .desktopDirectory, in: .userDomainMask)[0]
        return desktop.appendingPathComponent(courseName).path
    }

    static func folderExists(at path: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }

    static func files(at path: String) -> [LocalFile] {
        let url = URL(fileURLWithPath: path)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents.compactMap { fileURL -> LocalFile? in
            guard
                let res = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                res.isRegularFile == true
            else { return nil }

            let name  = fileURL.lastPathComponent
            let ext   = fileURL.pathExtension.lowercased()
            let mDate = res.contentModificationDate ?? Date()

            return LocalFile(
                name:         name,
                path:         fileURL.path,
                category:     categorise(name: name, ext: ext),
                dateModified: mDate,
                fileExtension: ext
            )
        }
        .sorted { $0.dateModified > $1.dateModified }
    }

    static func open(_ file: LocalFile) {
        NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
    }

    static func openFolder(at path: String) {
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    // MARK: - Icons

    static func fileIcon(_ ext: String) -> String {
        switch ext {
        case "pdf":              return "doc.richtext"
        case "ppt", "pptx":     return "rectangle.on.rectangle"
        case "doc", "docx":     return "doc.text"
        case "xls", "xlsx":     return "tablecells"
        case "mp4", "mov", "avi", "mkv": return "play.rectangle.fill"
        case "zip", "rar", "7z": return "archivebox"
        case "png", "jpg", "jpeg", "heic": return "photo"
        case "key":              return "rectangle.on.rectangle.angled"
        case "pages":            return "doc.text.fill"
        default:                 return "doc"
        }
    }

    static func categoryIcon(_ cat: LocalFile.FileCategory) -> String {
        switch cat {
        case .courseware:  return "rectangle.on.rectangle"
        case .reading:     return "book"
        case .lecture:     return "play.rectangle"
        case .submission:  return "paperclip"
        case .other:       return "doc"
        }
    }

    static func categoryColor(_ cat: LocalFile.FileCategory) -> String {
        switch cat {
        case .courseware:  return "3B82F6"   // blue
        case .reading:     return "8B5CF6"   // violet
        case .lecture:     return "EC4899"   // pink
        case .submission:  return "F59E0B"   // amber
        case .other:       return "6B7280"   // gray
        }
    }

    // MARK: - Categorisation logic

    private static func categorise(name: String, ext: String) -> LocalFile.FileCategory {
        let lower = name.lowercased()

        // Video → lecture recording
        if ["mp4", "mov", "avi", "mkv", "m4v", "wmv"].contains(ext) {
            return .lecture
        }

        // Submission keywords
        if lower.contains("submit") || lower.contains("作业") ||
           lower.contains("hw") || lower.contains("homework") ||
           lower.contains("assignment") || lower.contains("submission") {
            return .submission
        }

        // Slides / Courseware keywords
        if lower.contains("slide") || lower.contains("lec") ||
           lower.contains("week") || lower.contains("chapter") ||
           lower.contains("课件") || lower.contains("讲义") ||
           ext == "pptx" || ext == "ppt" || ext == "key" {
            return .courseware
        }

        // Reading material keywords
        if lower.contains("reading") || lower.contains("paper") ||
           lower.contains("article") || lower.contains("阅读") ||
           lower.contains("文献") || lower.contains("论文") {
            return .reading
        }

        // PDF: courseware if slide-like name, else reading
        if ext == "pdf" {
            if lower.contains("lec") || lower.contains("slide") ||
               lower.contains("课件") || lower.contains("week") {
                return .courseware
            }
            return .reading
        }

        return .other
    }
}
