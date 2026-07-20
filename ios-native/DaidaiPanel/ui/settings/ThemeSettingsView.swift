import SwiftUI
import PhotosUI

struct ThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var backgroundImage: UIImage?
    @State private var showClearImageAlert = false

    var body: some View {
        GlassScaffold {
            List {
                themeModeSection
                glassModeSection
                backgroundImageSection
                blurSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("主题设置")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { newItem in
            Task { await loadImage(from: newItem) }
        }
    }

    // MARK: - Theme Mode

    private var themeModeSection: some View {
        Section {
            Picker("主题模式", selection: Binding(
                get: { themeManager.themeMode },
                set: { themeManager.setThemeMode($0) }
            )) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("外观")
        }
    }

    // MARK: - Glass Mode

    private var glassModeSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { themeManager.glassMode },
                set: { _ in themeManager.toggleGlassMode() }
            )) {
                Label {
                    Text("玻璃模式")
                } icon: {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppColors.primary)
                }
            }
        } header: {
            Text("效果")
        } footer: {
            Text("开启后使用半透明玻璃质感背景")
        }
    }

    // MARK: - Background Image

    private var backgroundImageSection: some View {
        Section {
            if let image = backgroundImage {
                VStack(spacing: 12) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("清除背景图") {
                        showClearImageAlert = true
                    }
                    .font(.subheadline)
                    .foregroundColor(AppColors.error)
                }
            } else {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("选择背景图片", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
            }
        } header: {
            Text("背景图片")
        }
        .alert("确认清除", isPresented: $showClearImageAlert) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                backgroundImage = nil
                themeManager.setBackgroundImage(nil)
            }
        } message: {
            Text("确定要清除背景图片吗？")
        }
    }

    // MARK: - Blur Intensity

    private var blurSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("模糊强度")
                    Spacer()
                    Text("\(Int(themeManager.blurIntensity))")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Slider(
                    value: Binding(
                        get: { themeManager.blurIntensity },
                        set: { themeManager.setBlurIntensity($0) }
                    ),
                    in: 0...50,
                    step: 1
                )
                .tint(AppColors.primary)
            }
        } header: {
            Text("模糊")
        } footer: {
            Text("调整背景图片的模糊程度，值越大越模糊")
        }
    }

    // MARK: - Helpers

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            backgroundImage = image
            themeManager.setBackgroundImage("custom")
        }
    }
}
