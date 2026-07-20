import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearchButtonClicked: (() -> Void)?
    let onCancelButtonClicked: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String = "搜索",
        onSearchButtonClicked: (() -> Void)? = nil,
        onCancelButtonClicked: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onCancelButtonClicked = onCancelButtonClicked
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            // Text field
            TextField(placeholder, text: $text)
                .font(.body)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .onSubmit {
                    onSearchButtonClicked?()
                }
            
            // Clear button
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Cancel button (when focused)
            if isFocused {
                Button("取消") {
                    text = ""
                    isFocused = false
                    onCancelButtonClicked?()
                }
                .font(.body)
                .foregroundColor(Color(AppColors.primary))
                .buttonStyle(PlainButtonStyle())
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Group {
                if themeManager.glassMode {
                    // Glass mode with ultra thin material
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                } else {
                    // Classic mode with filled style
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(AppColors.glassCard))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused ? Color(AppColors.primary) : Color(AppColors.glassCardBorder),
                    lineWidth: isFocused ? 1.5 : 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// Convenience initializer for simple search bars
extension SearchBar {
    /// Create a simple search bar with just text binding
    init(text: Binding<String>, placeholder: String = "搜索") {
        self._text = text
        self.placeholder = placeholder
        self.onSearchButtonClicked = nil
        self.onCancelButtonClicked = nil
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var searchText = ""
        @State private var searchText2 = "Initial text"
        
        var body: some View {
            VStack(spacing: 20) {
                SearchBar(
                    text: $searchText,
                    placeholder: "搜索任务、日志..."
                )
                
                SearchBar(
                    text: $searchText2,
                    placeholder: "搜索",
                    onSearchButtonClicked: {
                        print("Search: \(searchText2)")
                    },
                    onCancelButtonClicked: {
                        print("Cancelled")
                    }
                )
                
                Text("Search text: \(searchText)")
                    .foregroundColor(.secondary)
                
                Text("Search text 2: \(searchText2)")
                    .foregroundColor(.secondary)
            }
            .padding()
                    .environmentObject(ThemeManager.shared)
        }
    }
    
    return PreviewWrapper()
}