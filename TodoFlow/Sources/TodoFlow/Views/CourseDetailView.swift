import SwiftUI

// MARK: - CourseDetailView  (full-page, no tabs)

struct CourseDetailView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var eLearning: ELearningService

    let course: Course

    @State private var showAddAssignment = false
    @State private var showEditCourse    = false

    private var live: Course { store.courses.first { $0.id == course.id } ?? course }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Course header ──────────────────────────────
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(hex: live.colorHex))
                        .frame(width: 5)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(live.code)
                            .font(Theme.englishBodyFont)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: live.colorHex))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(hex: live.colorHex).opacity(0.1))
                            .cornerRadius(5)
                        Text(live.name)
                            .font(Theme.titleFont)
                            .foregroundColor(Theme.textPrimary)
                        Text(live.professor)
                            .font(Theme.englishBodyFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(20)

                    Spacer()
                }
                .background(Color(hex: live.colorHex).opacity(0.05))

                // ── 作业 & DDL ─────────────────────────────────
                PageSectionHeader(title: "作业 & DDL", icon: "checklist")
                AssignmentsSection(course: live, showAddAssignment: $showAddAssignment)

                // ── 本地文件 ───────────────────────────────────
                PageSectionHeader(title: "本地文件", icon: "folder")
                FilesSection(course: live)

                // ── eLearning ──────────────────────────────────
                PageSectionHeader(title: "eLearning", icon: "link")
                ELearningSection(course: live)

                Spacer(minLength: 60)
            }
        }
        .background(Theme.background)
        .navigationTitle(live.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showEditCourse = true } label: {
                    Label("编辑课程", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showAddAssignment) {
            AddAssignmentSheet(courseId: live.id).environmentObject(store)
        }
        .sheet(isPresented: $showEditCourse) {
            EditCourseSheet(course: live).environmentObject(store)
        }
    }
}

// MARK: - Page Section Header

struct PageSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.accent)
            Text(title)
                .font(Font.custom("Songti SC", size: 20).weight(.semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 2)

        Rectangle()
            .fill(Theme.divider)
            .frame(height: 1.5)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
    }
}

// MARK: - Assignments Section

struct AssignmentsSection: View {
    let course: Course
    @Binding var showAddAssignment: Bool
    @EnvironmentObject var store: AppStore

    private var pending:   [Assignment] { course.assignments.filter { !$0.isCompleted }.sorted { $0.dueDate < $1.dueDate } }
    private var completed: [Assignment] { course.assignments.filter {  $0.isCompleted }.sorted { $0.dueDate > $1.dueDate } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("待完成 (\(pending.count))")
                    .font(Theme.headlineFont).foregroundColor(Theme.textPrimary)
                Spacer()
                Button { showAddAssignment = true } label: {
                    Label("添加", systemImage: "plus")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent)
            }
            .padding(.horizontal, 24).padding(.top, 12)

            if pending.isEmpty {
                EmptyPlaceholder(icon: "checkmark.circle", title: "没有待完成的作业", subtitle: "添加新作业或从 eLearning 同步")
            } else {
                VStack(spacing: 8) {
                    ForEach(pending) { a in
                        AssignmentRow(assignment: a).padding(.horizontal, 24)
                    }
                }
            }

            if !completed.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("已完成 (\(completed.count))")
                        .sectionHeader()
                        .padding(.horizontal, 24).padding(.top, 8)
                    ForEach(completed) { a in
                        AssignmentRow(assignment: a)
                            .padding(.horizontal, 24)
                            .opacity(0.5)
                    }
                }
            }
        }
    }
}

// MARK: - AssignmentRow

struct AssignmentRow: View {
    let assignment: Assignment
    @EnvironmentObject var store: AppStore

    private var days: Int { Calendar.current.dateComponents([.day], from: .now, to: assignment.dueDate).day ?? 0 }

    private var daysLabel: String {
        if days < 0  { return "已过期" }
        if days == 0 { return "今天截止" }
        return "\(days) 天后"
    }

    var body: some View {
        HStack(spacing: 12) {
            Button { store.toggleAssignment(assignment) } label: {
                Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(assignment.isCompleted ? Theme.success : Theme.textTertiary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.title)
                    .font(Theme.bodyFont).foregroundColor(Theme.textPrimary)
                    .strikethrough(assignment.isCompleted)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(assignment.dueDate, style: .date)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.urgencyColor(daysUntil: days))
                    if assignment.source == .elearning {
                        Label("eLearning", systemImage: "link")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
            }

            Spacer()

            Text(daysLabel)
                .font(Theme.captionFont)
                .foregroundColor(Theme.urgencyColor(daysUntil: days))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Theme.urgencyColor(daysUntil: days).opacity(0.1))
                .cornerRadius(6)
        }
        .padding(12)
        .cardStyle()
        .contextMenu {
            Button(role: .destructive) { store.deleteAssignment(assignment) } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// MARK: - Files Section

struct FilesSection: View {
    let course: Course

    @State private var files: [LocalFile] = []
    @State private var selectedCategory: LocalFile.FileCategory?

    private var folderPath: String {
        course.folderPath ?? FileService.defaultFolderPath(for: course.name)
    }

    private var filtered: [LocalFile] {
        guard let cat = selectedCategory else { return files }
        return files.filter { $0.category == cat }
    }

    private var groups: [LocalFile.FileCategory: [LocalFile]] {
        Dictionary(grouping: files, by: \.category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(folderPath)
                        .font(Theme.captionFont).foregroundColor(Theme.textTertiary)
                        .lineLimit(1).truncationMode(.middle)
                }
                Spacer()
                Button("刷新") { files = FileService.files(at: folderPath) }
                    .buttonStyle(.bordered)
                Button("打开文件夹") { FileService.openFolder(at: folderPath) }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24).padding(.top, 12)

            if !FileService.folderExists(at: folderPath) {
                EmptyPlaceholder(
                    icon: "folder.badge.questionmark",
                    title: "未找到文件夹",
                    subtitle: "请在桌面创建名为「\(course.name)」的文件夹"
                )
            } else if files.isEmpty {
                EmptyPlaceholder(
                    icon: "folder",
                    title: "文件夹为空",
                    subtitle: "将课程文件放入桌面「\(course.name)」文件夹"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "全部 (\(files.count))", isSelected: selectedCategory == nil)
                            .onTapGesture { selectedCategory = nil }
                        ForEach(LocalFile.FileCategory.allCases, id: \.self) { cat in
                            if let count = groups[cat]?.count, count > 0 {
                                FilterChip(
                                    label: "\(cat.rawValue) (\(count))",
                                    isSelected: selectedCategory == cat,
                                    colorHex: FileService.categoryColor(cat)
                                )
                                .onTapGesture { selectedCategory = selectedCategory == cat ? nil : cat }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                LazyVStack(spacing: 8) {
                    ForEach(filtered) { file in
                        FileRow(file: file).padding(.horizontal, 24)
                    }
                }
            }
        }
        .onAppear { files = FileService.files(at: folderPath) }
    }
}

struct FileRow: View {
    let file: LocalFile

    private var colorHex: String { FileService.categoryColor(file.category) }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: FileService.fileIcon(file.fileExtension))
                .font(.system(size: 18))
                .foregroundColor(Color(hex: colorHex))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(Theme.bodyFont).foregroundColor(Theme.textPrimary).lineLimit(1)
                Text(file.dateModified, style: .relative)
                    .font(Theme.captionFont).foregroundColor(Theme.textTertiary)
            }
            Spacer()
            Text(file.category.rawValue)
                .font(Theme.captionFont).foregroundColor(Color(hex: colorHex))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color(hex: colorHex).opacity(0.1))
                .cornerRadius(5)
        }
        .padding(12)
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture { FileService.open(file) }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var colorHex: String = "D97706"

    var body: some View {
        Text(label)
            .font(Theme.captionFont)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? Color(hex: colorHex) : Theme.textSecondary)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isSelected ? Color(hex: colorHex).opacity(0.1) : Theme.inputBg)
            .cornerRadius(20)
    }
}

// MARK: - eLearning Section

struct ELearningSection: View {
    let course: Course
    @EnvironmentObject var eLearning: ELearningService

    private var courseResources: [ELearningResource] {
        guard let cid = course.eLearningCourseId else { return [] }
        return eLearning.resources.filter { $0.courseId == cid }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Spacer()
                if eLearning.isLoading {
                    ProgressView().scaleEffect(0.7)
                } else if course.eLearningCourseId != nil {
                    Button("同步") { Task { await eLearning.syncAll() } }
                        .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 24).padding(.top, 12)

            if !eLearning.isLoggedIn {
                EmptyPlaceholder(icon: "lock", title: "未登录 eLearning", subtitle: "请在「设置」中登录 Fudan eLearning")
            } else if course.eLearningCourseId == nil {
                EmptyPlaceholder(
                    icon: "link.badge.plus",
                    title: "未关联 eLearning 课程",
                    subtitle: "编辑课程，填写对应的 Moodle 课程 ID"
                )
            } else if courseResources.isEmpty {
                EmptyPlaceholder(icon: "arrow.clockwise", title: "暂无内容", subtitle: "点击「同步」拉取最新内容")
            } else {
                let newItems = courseResources.filter(\.isNew)
                if !newItems.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("新增 (\(newItems.count))")
                            .sectionHeader().padding(.horizontal, 24)
                        ForEach(newItems) { r in
                            ELearningRow(resource: r).padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 4)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("全部 (\(courseResources.count))")
                        .sectionHeader().padding(.horizontal, 24)
                    ForEach(courseResources) { r in
                        ELearningRow(resource: r).padding(.horizontal, 24)
                    }
                }
            }

            Spacer(minLength: 40)
        }
    }
}

struct ELearningRow: View {
    let resource: ELearningResource
    @EnvironmentObject var eLearning: ELearningService

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: resource.typeIcon)
                .font(.system(size: 15))
                .foregroundColor(Theme.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(resource.name)
                        .font(Theme.bodyFont).foregroundColor(Theme.textPrimary).lineLimit(1)
                    if resource.isNew {
                        Text("新")
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Theme.danger).cornerRadius(3)
                    }
                }
                Text(resource.addedTimestamp, style: .date)
                    .font(Theme.captionFont).foregroundColor(Theme.textTertiary)
            }
            Spacer()
            Text(resource.modType)
                .font(Theme.captionFont).foregroundColor(Theme.textTertiary)
        }
        .padding(12)
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture {
            if resource.isNew { eLearning.markSeen(resource.id) }
            if let url = URL(string: resource.url), !resource.url.isEmpty {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
