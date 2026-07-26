import SwiftUI

/// 設定視窗主框架
struct SettingsWindow: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label(L("tab.general"), systemImage: "gearshape")
                }

            APISettingsTab()
                .tabItem {
                    Label(L("tab.api"), systemImage: "key")
                }

            LanguageSettingsTab()
                .tabItem {
                    Label(L("tab.language"), systemImage: "globe")
                }

            VocabularyTab()
                .tabItem {
                    Label(L("tab.vocabulary"), systemImage: "text.book.closed")
                }
        }
        .frame(width: 550, height: 450)
    }
}
