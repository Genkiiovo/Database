import Foundation

// MARK: - Course

struct Course: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var code: String
    var professor: String
    var colorHex: String
    var folderPath: String?          // override; default = ~/Desktop/<name>
    var eLearningCourseId: Int?      // Moodle course ID
    var assignments: [Assignment] = []
    var createdAt: Date = Date()
}

// MARK: - Assignment

struct Assignment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var dueDate: Date
    var courseId: UUID
    var isCompleted: Bool = false
    var notes: String = ""
    var source: Source = .manual

    enum Source: String, Codable {
        case manual
        case elearning
    }
}

// MARK: - Activity

struct Activity: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var startDate: Date
    var endDate: Date?
    var description: String = ""
    var category: Category = .project
    var stickyNotes: [StickyNote] = []
    var createdAt: Date = Date()

    enum Category: String, Codable, CaseIterable {
        case project  = "项目"
        case meeting  = "会议"
        case event    = "活动"
        case research = "研究"
        case other    = "其他"

        var icon: String {
            switch self {
            case .project:  return "target"
            case .meeting:  return "person.2"
            case .event:    return "calendar.badge.plus"
            case .research: return "magnifyingglass"
            case .other:    return "star"
            }
        }

        var colorHex: String {
            switch self {
            case .project:  return "3B82F6"
            case .meeting:  return "8B5CF6"
            case .event:    return "F59E0B"
            case .research: return "10B981"
            case .other:    return "6B7280"
            }
        }
    }
}

// MARK: - StickyNote

struct StickyNote: Identifiable, Codable {
    var id: UUID = UUID()
    var content: String
    var colorName: StickyColor = .yellow
    var createdAt: Date = Date()
    var activityId: UUID

    enum StickyColor: String, Codable, CaseIterable {
        case yellow = "yellow"
        case pink   = "pink"
        case blue   = "blue"
        case green  = "green"
        case purple = "purple"
    }
}

// MARK: - Local File (not Codable – rebuilt at runtime)

struct LocalFile: Identifiable {
    var id: String { path }
    var name: String
    var path: String
    var category: FileCategory
    var dateModified: Date
    var fileExtension: String

    enum FileCategory: String, CaseIterable {
        case courseware = "课件"
        case reading    = "阅读材料"
        case lecture    = "讲解视频"
        case submission = "作业提交"
        case other      = "其他"
    }
}

// MARK: - eLearning Resource

struct ELearningResource: Identifiable, Codable {
    var id: String
    var courseId: Int
    var courseName: String
    var name: String
    var modType: String    // assign / resource / url / folder / quiz …
    var url: String
    var addedTimestamp: Date
    var isNew: Bool = false

    var typeIcon: String {
        switch modType {
        case "resource": return "doc.fill"
        case "url":      return "link"
        case "assign":   return "pencil.and.list.clipboard"
        case "forum":    return "bubble.left.and.bubble.right"
        case "quiz":     return "questionmark.circle.fill"
        case "folder":   return "folder.fill"
        default:         return "doc"
        }
    }
}

// MARK: - Calendar Event (computed, not persisted)

struct CalendarEvent: Identifiable {
    var id: String { "\(title)-\(date.timeIntervalSince1970)-\(courseId?.uuidString ?? "act")" }
    var title: String
    var date: Date
    var courseId: UUID?
    var colorHex: String
}
