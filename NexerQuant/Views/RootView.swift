import SwiftUI
struct RootView:View { var body:some View { TabView { DashboardView().tabItem{Label("Auto",systemImage:"bolt.fill")}; ScannerView().tabItem{Label("Scanner",systemImage:"scope")}; PortfolioView().tabItem{Label("Portfolio",systemImage:"chart.pie.fill")}; SettingsView().tabItem{Label("Strategy",systemImage:"slider.horizontal.3")} }.preferredColorScheme(.dark) } }
