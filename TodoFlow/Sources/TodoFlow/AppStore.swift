import Foundation
import SwiftUI

// MARK: - AppStore

@MainActor
final class AppStore: ObservableObject {

    @Published var courses: [Course] = []
    @Published var activities: [Activity] = []

    // MARK: Init

    init() {
        load()
    }

    // MARK: - Persistence

    private var saveURL: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TodoFlow", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("data.json")
    }

    private struct Snapshot: Codable {
        var courses: [Course]
        var activities: [Activity]
    }

    func save() {
        let snap = Snapshot(courses: courses, activities: activities)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: saveURL, options: .atomic)
        }
    }

    func load() {
        guard
            let data = try? Data(contentsOf: saveURL),
            let snap = try? JSONDecoder().decode(Snapshot.self, from: data)
        else {
            insertSampleData()
            return
        }
        courses    = snap.courses
        activities = snap.activities
    }

    // MARK: - Course CRUD

    func addCourse(_ c: Course)    { courses.append(c); save() }
    func updateCourse(_ c: Course) { if let i = courses.firstIndex(where: { $0.id == c.id }) { courses[i] = c; save() } }
    func deleteCourse(_ c: Course) { courses.removeAll { $0.id == c.id }; save() }

    // MARK: - Assignment CRUD

    func addAssignment(_ a: Assignment) {
        guard let i = courses.firstIndex(where: { $0.id == a.courseId }) else { return }
        courses[i].assignments.append(a)
        save()
    }

    func toggleAssignment(_ a: Assignment) {
        for i in courses.indices {
            if let j = courses[i].assignments.firstIndex(where: { $0.id == a.id }) {
                courses[i].assignments[j].isCompleted.toggle()
                save()
                return
            }
        }
    }

    func updateAssignment(_ a: Assignment) {
        for i in courses.indices {
            if let j = courses[i].assignments.firstIndex(where: { $0.id == a.id }) {
                courses[i].assignments[j] = a
                save()
                return
            }
        }
    }

    func deleteAssignment(_ a: Assignment) {
        for i in courses.indices { courses[i].assignments.removeAll { $0.id == a.id } }
        save()
    }

    // MARK: - Activity CRUD

    func addActivity(_ a: Activity)    { activities.append(a); save() }
    func updateActivity(_ a: Activity) { if let i = activities.firstIndex(where: { $0.id == a.id }) { activities[i] = a; save() } }
    func deleteActivity(_ a: Activity) { activities.removeAll { $0.id == a.id }; save() }

    // MARK: - Sticky Note CRUD

    func addStickyNote(_ note: StickyNote, to activityId: UUID) {
        guard let i = activities.firstIndex(where: { $0.id == activityId }) else { return }
        activities[i].stickyNotes.append(note)
        save()
    }

    func updateStickyNote(_ note: StickyNote, in activityId: UUID) {
        guard let i = activities.firstIndex(where: { $0.id == activityId }),
              let j = activities[i].stickyNotes.firstIndex(where: { $0.id == note.id }) else { return }
        activities[i].stickyNotes[j] = note
        save()
    }

    func deleteStickyNote(_ noteId: UUID, from activityId: UUID) {
        guard let i = activities.firstIndex(where: { $0.id == activityId }) else { return }
        activities[i].stickyNotes.removeAll { $0.id == noteId }
        save()
    }

    // MARK: - Calendar feed

    var calendarEvents: [CalendarEvent] {
        var events: [CalendarEvent] = []
        for course in courses {
            for a in course.assignments where !a.isCompleted {
                events.append(CalendarEvent(
                    title: a.title,
                    date: a.dueDate,
                    courseId: course.id,
                    colorHex: course.colorHex
                ))
            }
        }
        for act in activities {
            events.append(CalendarEvent(
                title: act.title,
                date: act.startDate,
                courseId: nil,
                colorHex: act.category.colorHex
            ))
        }
        return events.sorted { $0.date < $1.date }
    }

    var upcomingCount: Int {
        let horizon = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return courses.reduce(0) { sum, c in
            sum + c.assignments.filter { !$0.isCompleted && $0.dueDate >= Date() && $0.dueDate <= horizon }.count
        }
    }

    // MARK: - Sample data

    private func insertSampleData() {
        let cal = Calendar.current
        let now = Date()
        func days(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: now)! }

        var cs = Course(name: "数据结构", code: "CS101", professor: "张教授", colorHex: "3B82F6")
        cs.assignments = [
            Assignment(title: "作业一：链表实现", dueDate: days(3),  courseId: cs.id),
            Assignment(title: "期中项目提交",     dueDate: days(14), courseId: cs.id),
        ]

        var eng = Course(name: "学术英语写作", code: "ENG201", professor: "Smith 教授", colorHex: "10B981")
        eng.assignments = [
            Assignment(title: "Essay Draft 1", dueDate: days(5),  courseId: eng.id),
            Assignment(title: "Final Essay",   dueDate: days(21), courseId: eng.id),
        ]

        var econ = Course(name: "微观经济学", code: "ECON101", professor: "李教授", colorHex: "F59E0B")
        econ.assignments = [
            Assignment(title: "第三章习题集", dueDate: days(7), courseId: econ.id),
        ]

        courses = [cs, eng, econ]

        activities = [
            Activity(
                title: "学生会策划会议",
                startDate: days(2),
                description: "讨论五四晚会安排",
                category: .meeting
            ),
            Activity(
                title: "NLP 科研训练项目",
                startDate: days(-7),
                endDate: days(60),
                description: "基于大模型的情感分析研究",
                category: .research
            ),
        ]
        save()
    }
}
