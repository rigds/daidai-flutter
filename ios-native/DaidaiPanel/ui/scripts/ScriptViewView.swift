import SwiftUI

struct ScriptViewView: View {
    @ObservedObject var viewModel: ScriptViewModel
    @EnvironmentObject var apiService: ApiService
    let filePath: String

    @State private var editedContent = ""
    @State private var showRunOutput = false
    @State private var hasUnsavedChanges = false
    @State private var showSaveAlert = false

    var body: some View {
        GlassScaffold {
            VStack(spacing: 0) {
                // Toolbar
                toolbarView

                Divider()

                // Editor
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    editorView
                }

                // Output panel
                if showRunOutput, let output = viewModel.runOutput {
                    Divider()
                    outputPanel(output)
                }
            }
        }
        .navigationTitle((filePath as NSString).lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.updateAPI(apiService)
            await viewModel.loadContent(path: filePath)
            editedContent = viewModel.fileContent
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("保存") { save() }
                    .disabled(!hasUnsavedChanges || viewModel.isSaving)
            }
        }
        .alert("未保存的更改", isPresented: $showSaveAlert) {
            Button("放弃", role: .destructive) {}
            Button("保存") { save() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("有未保存的更改，是否保存？")
        }
    }

    // MARK: - Toolbar

    private var toolbarView: some View {
        HStack(spacing: 16) {
            Button {
                Task { await viewModel.format() }
                editedContent = viewModel.fileContent
            } label: {
                Label("格式化", systemImage: "text.alignleft")
                    .font(.caption)
            }

            Button {
                Task { await viewModel.run(path: filePath) }
                showRunOutput = true
            } label: {
                Label("运行", systemImage: "play.fill")
                    .font(.caption)
            }
            .foregroundColor(AppColors.primary)

            Spacer()

            if hasUnsavedChanges {
                Text("未保存")
                    .font(.caption2)
                    .foregroundColor(AppColors.warning)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(AppColors.glassCard)
    }

    // MARK: - Editor

    private var editorView: some View {
        TextEditor(text: $editedContent)
            .font(.system(.body, design: .monospaced))
            .onChange(of: editedContent) { _ in
                hasUnsavedChanges = editedContent != viewModel.fileContent
            }
    }

    // MARK: - Output Panel

    private func outputPanel(_ output: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("输出")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Button { showRunOutput = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            ScrollView {
                Text(output)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .background(AppColors.termBg)
        .frame(maxHeight: 200)
    }

    private func save() {
        viewModel.fileContent = editedContent
        Task {
            await viewModel.save()
            hasUnsavedChanges = false
        }
    }
}
