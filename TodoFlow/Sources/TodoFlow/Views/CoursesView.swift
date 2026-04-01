import SwiftUI

// MARK: - CoursesView

struct CoursesView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var eLearning: ELearningService

    @State private var showAddCourse = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {

                // ── Header ─────────────────────────────────────
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("课程")
                            .font(Theme.titleFont)
                            .foregroundColor(Theme.textPrimary)
                        Text("\(store.courses.count) 门课程 · \(totalPending) 项待完成")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    Button { showAddCourse = true } label: {
                        Label("添加课程", systemImage: "plus")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // ── Course grid ────────────────────────────────
                if store.courses.isEmpty {
                    EmptyPlaceholder(
                        icon: "books.vertical",
                        title: "还没有课程",
                        subtitle: "点击右上角「添加课程」开始"
                    )
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(store.courses) { course in
                            NavigationLink {
                                CourseDetailView(course: course)
                                    .environmentObject(store)
                                    .environmentObject(eLearning)
                            } label: {
                                CourseCard(course: course)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 40)
            }
        }
        .background(Theme.background)
        .sheet(isPresented: $showAddCourse) {
            AddCourseSheet().environmentObject(store)
        }
    }

    private var totalPending: Int {
        store.courses.reduce(0) { $0 + $1.assignments.filter { !$0.isCompleted }.count }
    }
}

// MARK: - CourseCard

struct CourseCard: View {
    let course: Course
    @EnvironmentObject var store: AppStore

    private var pending: Int { course.assignments.filter { !$0.isCompleted }.count }

    private var nextDue: Assignment? {
        course.assignments
            .filter { !$0.isCompleted && $0.dueDate >= Date() }
            .sorted { $0.dueDate < $1.dueDate }
            .first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Colour accent bar
            Rectangle()
                .fill(Color(hex: course.colorHex))
                .frame(height: 4)
                .cornerRadius(Theme.cornerRadius, corners: [.topLeft, .topRight])

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(course.code)
                        .font(Theme.englishBodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: course.colorHex))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: course.colorHex).opacity(0.12))
                        .cornerRadius(5)
                    Spacer()
                }

                Text(course.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)

                Text(course.professor)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.cardPadding)

            Divider()

            // Next deadline footer
            Group {
                if let next = nextDue {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textTertiary)
                        Text(next.title)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                        Spacer()
                        Text(next.dueDate, style: .date)
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textTertiary)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.success)
                        Text("暂无待完成作业")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, Theme.cardPadding)
            .padding(.vertical, 10)
        }
        .background(Theme.cardBg)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Rounded corners helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorners(radius: radius, corners: corners))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    static let topLeft     = RectCorner(rawValue: 1 << 0)
    static let topRight    = RectCorner(rawValue: 1 << 1)
    static let bottomLeft  = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let all: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: RectCorner
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = corners.contains(.topLeft)
        let tr = corners.contains(.topRight)
        let bl = corners.contains(.bottomLeft)
        let br = corners.contains(.bottomRight)
        path.move(to: CGPoint(x: rect.minX + (tl ? radius : 0), y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - (tr ? radius : 0), y: rect.minY))
        if tr { path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false) }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - (br ? radius : 0)))
        if br { path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius), radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false) }
        path.addLine(to: CGPoint(x: rect.minX + (bl ? radius : 0), y: rect.maxY))
        if bl { path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius), radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false) }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + (tl ? radius : 0)))
        if tl { path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false) }
        path.closeSubpath()
        return path
    }
}

// MARK: - Shared empty state

struct EmptyPlaceholder: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Theme.textTertiary)
            Text(title)
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textSecondary)
            Text(subtitle)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }
}
