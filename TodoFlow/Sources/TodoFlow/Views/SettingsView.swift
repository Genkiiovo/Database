import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var eLearning: ELearningService

    @State private var username    = ""
    @State private var password    = ""
    @State private var isLoggingIn = false
    @State private var syncInterval = 30

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("设置")
                    .font(Theme.titleFont).foregroundColor(Theme.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20)).foregroundColor(Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            Form {
                // ── eLearning ──────────────────────────────────
                Section {
                    if eLearning.isLoggedIn {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.success)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("已连接 Fudan eLearning")
                                    .font(Theme.bodyFont).foregroundColor(Theme.textPrimary)
                                if let d = eLearning.lastSyncDate {
                                    Text("上次同步：\(d, style: .relative)前")
                                        .font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                                }
                            }
                            Spacer()
                            Button("立即同步") { Task { await eLearning.syncAll() } }
                                .buttonStyle(.bordered)
                            Button("退出登录", role: .destructive) { eLearning.logout() }
                                .buttonStyle(.bordered)
                        }

                        Picker("自动同步频率", selection: $syncInterval) {
                            Text("每 15 分钟").tag(15)
                            Text("每 30 分钟").tag(30)
                            Text("每 1 小时").tag(60)
                            Text("不自动同步").tag(0)
                        }
                        .onChange(of: syncInterval) { _, new in
                            eLearning.startAutoSync(intervalMinutes: new)
                        }

                        let newCount = eLearning.resources.filter(\.isNew).count
                        if newCount > 0 {
                            Label("\(newCount) 个未查看的新内容", systemImage: "bell.badge")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.warning)
                        }

                    } else {
                        // Login form
                        TextField("学号 / 用户名", text: $username)
                        SecureField("密码", text: $password)

                        HStack {
                            Button {
                                isLoggingIn = true
                                Task {
                                    _ = await eLearning.login(username: username, password: password)
                                    isLoggingIn = false
                                    if eLearning.isLoggedIn { password = "" }
                                }
                            } label: {
                                HStack {
                                    if isLoggingIn { ProgressView().scaleEffect(0.7) }
                                    Text("登录 eLearning")
                                }
                            }
                            .disabled(username.isEmpty || password.isEmpty || isLoggingIn)
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)

                            Spacer()
                        }

                        if let err = eLearning.errorMessage {
                            Text(err)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.danger)
                        }

                        Text("账号密码仅存储于本地 macOS Keychain，不会上传至任何服务器。")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textTertiary)
                    }
                } header: {
                    Text("eLearning 集成")
                }

                // ── Data ──────────────────────────────────────
                Section {
                    HStack {
                        Text("课程数据")
                        Spacer()
                        Text("~/Library/Application Support/TodoFlow/")
                            .font(Theme.captionFont).foregroundColor(Theme.textTertiary)
                    }
                    Button("重置为示例数据", role: .destructive) {
                        // Clear existing and reload sample data
                        store.courses = []
                        store.activities = []
                        store.save()
                        store.load()
                    }
                } header: {
                    Text("数据")
                }

                // ── About ─────────────────────────────────────
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0").foregroundColor(Theme.textSecondary)
                    }
                    HStack {
                        Text("作者")
                        Spacer()
                        Text("TodoFlow").foregroundColor(Theme.textSecondary)
                    }
                    Text("专为复旦学子设计的学期整理工具。支持课程管理、本地文件展示、eLearning 更新追踪与活动便利贴。")
                        .font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                } header: {
                    Text("关于")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 520, height: 500)
        .background(Theme.background)
        .onAppear {
            eLearning.restoreSession()
        }
    }
}
