import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var s: TradingStore

    var body: some View {
        NavigationStack {
            List {
                Section("Positions") {
                    if s.positions.isEmpty {
                        Text("No positions yet")
                    }

                    ForEach(s.positions) { p in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(p.symbol)
                                    .bold()

                                Spacer()

                                Text(
                                    p.value.formatted(
                                        .currency(code: "USD")
                                    )
                                )
                            }

                            Text(
                                "P/L \(p.pnl.formatted(.currency(code: "USD"))) • Stop \(p.stop.formatted(.currency(code: "USD")))"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                p.pnl >= 0 ? .green : .red
                            )
                        }
                    }
                }

                Section("Trade Journal") {
                    ForEach(s.trades) { t in
                        VStack(alignment: .leading) {
                            Text("\(t.side) \(t.symbol)")
                                .bold()

                            Text(t.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Portfolio")
        }
    }
}
