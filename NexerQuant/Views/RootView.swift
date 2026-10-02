import SwiftUI

struct RootView:View {
    var body:some View {
        TabView {
            DashboardView().tabItem{Label("Home",systemImage:"square.grid.2x2.fill")}
            ScannerView().tabItem{Label("Radar",systemImage:"scope")}
            PortfolioView().tabItem{Label("Portfolio",systemImage:"chart.pie.fill")}
            AnalyticsView().tabItem{Label("Analytics",systemImage:"chart.xyaxis.line")}
            SettingsView().tabItem{Label("System",systemImage:"gearshape.fill")}
        }
    }
}
