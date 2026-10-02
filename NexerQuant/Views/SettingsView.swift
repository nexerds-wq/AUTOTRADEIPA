import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var s: TradingStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Automation") {
                    Toggle("Automatic paper trading", isOn: $s.settings.autoEnabled)
                    Text("The scanner ranks the full built-in stock and ETF universe using 12-month momentum, 6-month momentum, the 200-day trend, breakouts and volatility. The portfolio can hold the strongest qualifying assets instead of being locked to three symbols.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Capital") {
                    Text("Starting paper cash: $\(s.settings.startingCash, specifier:"%.0f")")
                    Text("Position size is calculated from total portfolio value and the number of qualifying assets. It is not hard-coded to $1,000.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Data") {
                    Text("Keyless daily market data")
                    Text("No API key is required by the current market-data service.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Reset Paper Account", role:.destructive) { s.reset() }
                }
            }
            .navigationTitle("Strategy Lab")
        }
    }
}
