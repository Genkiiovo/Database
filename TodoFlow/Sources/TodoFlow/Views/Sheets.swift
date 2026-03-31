import SwiftUI

// ─────────────────────────────────────────────
// MARK: - AddCourseSheet
// ─────────────────────────────────────────────

struct AddCourseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    @State private var name        = ""
    @State private var code        = ""
    @State private var professor   = ""
    @State private var colorHex    = "3B82F6"
    @State private var folderPath  = ""
    @State private var eLearningId = ""

    private let presetColors = [
        "3B82F6", "10B981", "F59E0B", "EF4444",
        "8B5CF6", "EC4899", "06B6D4", "84CC16",
    ]

    var body: some View {
        SheetContainer(title: "添加课程", onCancel: dismiss.callAsFunction) {
            Button("添加") {
                var c = Course(name: name, code: code, professor: professor, colorHex: colorHex)
                if !folderPath.isEmpty  { c.folderPath = folderPath }
                if let id = Int(eLearningId) { c.eLearningCourseId = id }
                store.addCourse(c)
                dismiss()
            }
            .disabled(name.isEmpty || code.isEmpty)
            .buttonStyle(.borderedProminent).tint(Theme.accent)
        } content: {
            VStack(spacing: 14) {
                SheetField(label: "课程名称", placeholder: "例：数据结构", text: $name)
                SheetField(label: "课程代码", placeholder: "例：CS101", text: $code)
                SheetField(label: "任课教师", placeholder: "例：张教授", text: $professor)

                // Color picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("颜色").font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                    HStack(spacing: 10) {
                        ForEach(presetColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle().stroke(colorHex == hex ? Theme.textPrimary : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture { colorHex = hex }
                        }
                    }
                }

                SheetField(label: "本地文件夹路径（留空则默认 ~/Desktop/<课程名>）", placeholder: "/Users/you/Desktop/数据结构", text: $folderPath)
                SheetField(label: "eLearning Moodle 课程 ID（可选）", placeholder: "例：12345", text: $eLearningId)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - EditCourseSheet
// ─────────────────────────────────────────────

struct EditCourseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    let course: Course

    @State private var name        = ""
    @State private var code        = ""
    @State private var professor   = ""
    @State private var colorHex    = ""
    @State private var folderPath  = ""
    @State private var eLearningId = ""

    private let presetColors = [
        "3B82F6", "10B981", "F59E0B", "EF4444",
        "8B5CF6", "EC4899", "06B6D4", "84CC16",
    ]

    var body: some View {
        SheetContainer(title: "编辑课程", onCancel: dismiss.callAsFunction) {
            HStack(spacing: 8) {
                Button("删除课程", role: .destructive) {
                    store.deleteCourse(course)
                    dismiss()
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("保存") {
                    var c = course
                    c.name = name; c.code = code; c.professor = professor; c.colorHex = colorHex
                    c.folderPath = folderPath.isEmpty ? nil : folderPath
                    c.eLearningCourseId = Int(eLearningId)
                    store.updateCourse(c)
                    dismiss()
                }
                .disabled(name.isEmpty || code.isEmpty)
                .buttonStyle(.borderedProminent).tint(Theme.accent)
            }
        } content: {
            VStack(spacing: 14) {
                SheetField(label: "课程名称", placeholder: "例：数据结构", text: $name)
                SheetField(label: "课程代码", placeholder: "例：CS101", text: $code)
                SheetField(label: "任课教师", placeholder: "例：张教授", text: $professor)

                VStack(alignment: .leading, spacing: 6) {
                    Text("颜色").font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                    HStack(spacing: 10) {
                        ForEach(presetColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 24, height: 24)
                                .overlay(Circle().stroke(colorHex == hex ? Theme.textPrimary : Color.clear, lineWidth: 2))
                                .onTapGesture { colorHex = hex }
                        }
                    }
                }

                SheetField(label: "本地文件夹路径", placeholder: "/Users/you/Desktop/数据结构", text: $folderPath)
                SheetField(label: "eLearning Moodle 课程 ID（可选）", placeholder: "例：12345", text: $eLearningId)
            }
        }
        .onAppear {
            name        = course.name
            code        = course.code
            professor   = course.professor
            colorHex    = course.colorHex
            folderPath  = course.folderPath ?? ""
            eLearningId = course.eLearningCourseId.map(String.init) ?? ""
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - AddAssignmentSheet
// ─────────────────────────────────────────────

struct AddAssignmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    let courseId: UUID

    @State private var title   = ""
    @State private var dueDate = Date()
    @State private var notes   = ""

    var body: some View {
        SheetContainer(title: "添加作业 / DDL", onCancel: dismiss.callAsFunction) {
            Button("添加") {
                let a = Assignment(title: title, dueDate: dueDate, courseId: courseId, notes: notes)
                store.addAssignment(a)
                dismiss()
            }
            .disabled(title.isEmpty)
            .buttonStyle(.borderedProminent).tint(Theme.accent)
        } content: {
            VStack(spacing: 14) {
                SheetField(label: "作业标题", placeholder: "例：第三章习题集", text: $title)

                VStack(alignment: .leading, spacing: 6) {
                    Text("截止日期").font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                    DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("备注（可选）").font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                    TextEditor(text: $notes)
                        .font(Theme.bodyFont)
                        .frame(height: 60)
                        .padding(8)
                        .background(Theme.inputBg)
                        .cornerRadius(8)
                        .scrollContentBackground(.hidden)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - AddActivitySheet
// ─────────────────────────────────────────────

struct AddActivitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    @State private var title       = ""
    @State private var description = ""
    @State private var category    = Activity.Category.project
    @State private var startDate   = Date()
    @State private var hasEndDate  = false
    @State private var endDate     = Date()

    var body: some View {
        SheetContainer(title: "添加活动 / 项目", onCancel: dismiss.callAsFunction) {
            Button("添加") {
                let a = Activity(
                    title: title,
                    startDate: startDate,
                    endDate: hasEndDate ? endDate : nil,
                    description: description,
                    category: category
                )
                store.addActivity(a)
                dismiss()
            }
            .disabled(title.isEmpty)
            .buttonStyle(.borderedProminent).tint(Theme.accent)
        } content: {
            VStack(spacing: 14) {
                SheetField(label: "标题", placeholder: "例：学生会策划会议", text: $title)

                VStack(alignment: .leading, spacing: 6) {
                    Text("类型").font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                    Picker("", selection: $category) {
                        ForEach(Activity.Category.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("开始日期").font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                    DatePicker("", selection: $startDate, displayedComponents: [.date])
                        .labelsHidden()
                }

                Toggle("设置截止 / 结束日期", isOn: $hasEndDate)
                if hasEndDate {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("结束日期").font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: [.date])
                            .labelsHidden()
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("描述（可选）").font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                    TextEditor(text: $description)
                        .font(Theme.bodyFont)
                        .frame(height: 60)
                        .padding(8)
                        .background(Theme.inputBg)
                        .cornerRadius(8)
                        .scrollContentBackground(.hidden)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - AddStickyNoteSheet
// ─────────────────────────────────────────────

struct AddStickyNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    let activityId: UUID

    @State private var content   = ""
    @State private var noteColor = StickyNote.StickyColor.yellow

    var body: some View {
        SheetContainer(title: "添加便利贴", onCancel: dismiss.callAsFunction) {
            Button("添加") {
                let n = StickyNote(content: content, colorName: noteColor, activityId: activityId)
                store.addStickyNote(n, to: activityId)
                dismiss()
            }
            .disabled(content.isEmpty)
            .buttonStyle(.borderedProminent).tint(Theme.accent)
        } content: {
            VStack(spacing: 14) {
                // Color selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("颜色").font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                    HStack(spacing: 10) {
                        ForEach(StickyNote.StickyColor.allCases, id: \.self) { c in
                            ZStack {
                                Circle().fill(Theme.stickyColor(c)).frame(width: 30, height: 30)
                                if c == noteColor {
                                    Circle().stroke(Theme.textPrimary.opacity(0.4), lineWidth: 2).frame(width: 30, height: 30)
                                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                                }
                            }
                            .onTapGesture { noteColor = c }
                        }
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text("内容").font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.stickyColor(noteColor))
                        if content.isEmpty {
                            Text("写下你的想法、会议记录、提醒…")
                                .font(Theme.bodyFont).foregroundColor(.gray.opacity(0.5))
                                .padding(10)
                        }
                        TextEditor(text: $content)
                            .font(Theme.bodyFont)
                            .frame(minHeight: 100)
                            .padding(6)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                    .frame(minHeight: 110)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Shared sheet scaffolding
// ─────────────────────────────────────────────

struct SheetContainer<Content: View, Trailing: View>: View {
    let title: String
    let onCancel: () -> Void
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Navigation-style header
            HStack {
                Button("取消", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text(title)
                    .font(Theme.headlineFont).foregroundColor(Theme.textPrimary)
                Spacer()
                trailing()
            }
            .padding(20)

            Divider()

            ScrollView {
                content()
                    .padding(20)
            }
        }
        .frame(minWidth: 460, maxWidth: 520)
        .background(Theme.background)
    }
}

struct SheetField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(Theme.captionFont).foregroundColor(Theme.textSecondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(Theme.bodyFont)
                .padding(10)
                .background(Theme.inputBg)
                .cornerRadius(8)
        }
    }
}
