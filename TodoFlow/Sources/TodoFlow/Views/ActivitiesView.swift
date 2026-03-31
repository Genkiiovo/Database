import SwiftUI

// MARK: - ActivitiesView

struct ActivitiesView: View {
    @EnvironmentObject var store: AppStore

    @State private var showAddActivity = false
    @State private var selectedActivity: Activity?

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {

                // ── Header ──────────────────────────────────────
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("活动 & 项目")
                            .font(Theme.titleFont).foregroundColor(Theme.textPrimary)
                        Text("\(store.activities.count) 项进行中")
                            .font(Theme.bodyFont).foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    Button { showAddActivity = true } label: {
                        Label("添加", systemImage: "plus")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent).tint(Theme.accent)
                }
                .padding(.horizontal, 24).padding(.top, 24)

                if store.activities.isEmpty {
                    EmptyPlaceholder(icon: "target", title: "还没有活动或项目", subtitle: "点击「添加」创建你的第一个项目")
                } else {
                    // Group by category
                    ForEach(Activity.Category.allCases, id: \.self) { cat in
                        let items = store.activities.filter { $0.category == cat }
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color(hex: cat.colorHex))
                                    Text(cat.rawValue)
                                        .sectionHeader()
                                }
                                .padding(.horizontal, 24)

                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(items) { activity in
                                        ActivityCard(activity: activity)
                                            .onTapGesture { selectedActivity = activity }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .background(Theme.background)
        .sheet(isPresented: $showAddActivity) {
            AddActivitySheet().environmentObject(store)
        }
        .sheet(item: $selectedActivity) { act in
            ActivityDetailView(activity: act).environmentObject(store)
        }
    }
}

// MARK: - ActivityCard

struct ActivityCard: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Category badge
            HStack {
                Label(activity.category.rawValue, systemImage: activity.category.icon)
                    .font(Theme.captionFont).fontWeight(.semibold)
                    .foregroundColor(Color(hex: activity.category.colorHex))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color(hex: activity.category.colorHex).opacity(0.1))
                    .cornerRadius(5)
                Spacer()
                if !activity.stickyNotes.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "note.text")
                            .font(.system(size: 10))
                        Text("\(activity.stickyNotes.count)")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Theme.textTertiary)
                }
            }

            Text(activity.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)

            if !activity.description.isEmpty {
                Text(activity.description)
                    .font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar").font(.system(size: 10)).foregroundColor(Theme.textTertiary)
                Text(activity.startDate, style: .date).font(Theme.captionFont).foregroundColor(Theme.textTertiary)
                if let end = activity.endDate {
                    Text("→").font(Theme.captionFont).foregroundColor(Theme.textTertiary)
                    Text(end, style: .date).font(Theme.captionFont).foregroundColor(Theme.textTertiary)
                }
                Spacer()
            }

            // Sticky note preview (first note)
            if let note = activity.stickyNotes.first {
                Text(note.content)
                    .font(Theme.captionFont).foregroundColor(Theme.textPrimary)
                    .lineLimit(2)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.stickyColor(note.colorName))
                    .cornerRadius(6)
            }
        }
        .padding(Theme.cardPadding)
        .cardStyle()
    }
}

// MARK: - ActivityDetailView

struct ActivityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    let activity: Activity

    @State private var showAddNote = false

    private var live: Activity { store.activities.first { $0.id == activity.id } ?? activity }

    private let noteColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Label(live.category.rawValue, systemImage: live.category.icon)
                            .font(Theme.captionFont).fontWeight(.semibold)
                            .foregroundColor(Color(hex: live.category.colorHex))
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20)).foregroundColor(Theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    Text(live.title)
                        .font(Theme.titleFont).foregroundColor(Theme.textPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: "calendar").font(.system(size: 12)).foregroundColor(Theme.textTertiary)
                        Text(live.startDate, style: .date).font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                        if let end = live.endDate {
                            Text("→").foregroundColor(Theme.textTertiary)
                            Text(end, style: .date).font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                        }
                    }
                    if !live.description.isEmpty {
                        Text(live.description)
                            .font(Theme.bodyFont).foregroundColor(Theme.textSecondary)
                            .padding(.top, 2)
                    }
                }
                .padding(20)
            }
            .background(Color(hex: live.category.colorHex).opacity(0.05))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Sticky notes header
                    HStack {
                        Text("便利贴 (\(live.stickyNotes.count))")
                            .font(Theme.headlineFont).foregroundColor(Theme.textPrimary)
                        Spacer()
                        Button { showAddNote = true } label: {
                            Label("添加便利贴", systemImage: "plus")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .buttonStyle(.borderedProminent).tint(Theme.accent)
                    }
                    .padding(.horizontal, 24).padding(.top, 20)

                    if live.stickyNotes.isEmpty {
                        EmptyPlaceholder(icon: "note.text", title: "还没有便利贴", subtitle: "添加想法、会议记录或备忘")
                    } else {
                        LazyVGrid(columns: noteColumns, spacing: 12) {
                            ForEach(live.stickyNotes) { note in
                                StickyNoteCard(note: note, activityId: live.id)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Theme.background)
        }
        .frame(minWidth: 640, minHeight: 480)
        .sheet(isPresented: $showAddNote) {
            AddStickyNoteSheet(activityId: live.id).environmentObject(store)
        }
    }
}

// MARK: - StickyNoteCard

struct StickyNoteCard: View {
    let note: StickyNote
    let activityId: UUID
    @EnvironmentObject var store: AppStore

    @State private var isEditing = false
    @State private var editedContent = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Color dot picker
                HStack(spacing: 4) {
                    ForEach(StickyNote.StickyColor.allCases, id: \.self) { c in
                        Circle()
                            .fill(Theme.stickyColor(c))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle().stroke(c == note.colorName ? Color.gray.opacity(0.5) : Color.clear, lineWidth: 1.5)
                            )
                            .onTapGesture {
                                var updated = note; updated.colorName = c
                                store.updateStickyNote(updated, in: activityId)
                            }
                    }
                }
                Spacer()
                Button {
                    store.deleteStickyNote(note.id, from: activityId)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            if isEditing {
                TextEditor(text: $editedContent)
                    .font(.system(size: 13))
                    .frame(minHeight: 70)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .onSubmit {
                        var updated = note; updated.content = editedContent
                        store.updateStickyNote(updated, in: activityId)
                        isEditing = false
                    }
                HStack {
                    Spacer()
                    Button("保存") {
                        var updated = note; updated.content = editedContent
                        store.updateStickyNote(updated, in: activityId)
                        isEditing = false
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.accent)
                }
            } else {
                Text(note.content)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        editedContent = note.content
                        isEditing = true
                    }
            }

            Spacer()

            Text(note.createdAt, style: .date)
                .font(.system(size: 10))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(12)
        .frame(minHeight: 120)
        .background(Theme.stickyColor(note.colorName))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
    }
}
