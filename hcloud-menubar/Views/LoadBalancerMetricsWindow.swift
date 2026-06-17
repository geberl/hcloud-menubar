import Charts
import SwiftUI

/// Value identifying which Load Balancer a metrics window is for. Used as the `WindowGroup` value,
/// so it must be `Codable & Hashable`; an identical value reuses the existing window rather than
/// opening a duplicate. The token is deliberately *not* carried here — it is read from the Keychain
/// inside the window using `projectUUID`.
struct LoadBalancerMetricsTarget: Codable, Hashable {
    let projectUUID: UUID
    let customApiBaseUrl: String
    let loadBalancerId: Int
    let name: String
    let created: String?
}

struct LoadBalancerMetricsView: View {
    let target: LoadBalancerMetricsTarget
    @StateObject private var model: LoadBalancerMetricsModel

    init(target: LoadBalancerMetricsTarget) {
        self.target = target
        _model = StateObject(wrappedValue: LoadBalancerMetricsModel(
            customApiBaseUrl: target.customApiBaseUrl,
            loadBalancerId: target.loadBalancerId,
            token: KeychainTokenStore.read(for: target.projectUUID)
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            titleSection
            chartsSection
        }
        .padding(20)
        .frame(minWidth: LoadBalancerMetricsWindowWidth, minHeight: LoadBalancerMetricsWindowHeight)
        .navigationTitle("Load Balancer: \(target.name)")
        .toolbar { toolbarContent }
        .onAppear { model.refresh() }
        .onDisappear { model.stop() }
    }

    // MARK: Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Metrics")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                // `String(...)` avoids SwiftUI's locale grouping separators in the integer ID.
                Text("ID \(String(target.loadBalancerId))")
                Spacer()
                Text("Last refreshed \(formattedLastRefreshed)")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var formattedLastRefreshed: String {
        guard let last = model.lastRefreshed else { return "—" }
        return last.formatted(date: .omitted, time: .standard)
    }

    // MARK: Charts

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            chartSection(title: "HTTP Requests Per Second",
                         type: MetricTypeRequestsPerSecond,
                         color: .accentColor,
                         yLabel: "Requests/s")
            chartSection(title: "Open Connections",
                         type: MetricTypeOpenConnections,
                         color: .green,
                         yLabel: "Connections")
            chartSection(title: "Connections Per Second",
                         type: MetricTypeConnectionsPerSecond,
                         color: .orange,
                         yLabel: "Connections/s")
        }
    }

    private func chartSection(title: String, type: String, color: Color, yLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            chartBody(type: type, color: color, yLabel: yLabel)
                .frame(height: MetricChartHeight)
        }
    }

    @ViewBuilder
    private func chartBody(type: String, color: Color, yLabel: String) -> some View {
        let samples = model.series[type] ?? []

        if case let .failed(error) = model.loadState {
            placeholder(Text(error.menuDescription).foregroundStyle(.secondary))
        } else if !samples.isEmpty {
            // Keep the existing chart visible while a refresh is in flight.
            chart(samples, color: color, yLabel: yLabel)
        } else if model.loadState == .loaded {
            placeholder(Text("No data for this period").foregroundStyle(.secondary))
        } else {
            placeholder(ProgressView())
        }
    }

    private func chart(_ samples: [MetricSample], color: Color, yLabel: String) -> some View {
        Chart(samples) { sample in
            AreaMark(
                x: .value("Time", sample.date),
                y: .value(yLabel, sample.value)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [color.opacity(0.35), color.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.monotone)

            LineMark(
                x: .value("Time", sample.date),
                y: .value(yLabel, sample.value)
            )
            .foregroundStyle(color)
            .interpolationMethod(.monotone)
        }
        .chartYAxisLabel(yLabel)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func placeholder(_ content: some View) -> some View {
        content.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            if model.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(action: { model.refresh() }) {
                    Label("Refresh Now", systemImage: "arrow.clockwise")
                }
                .help("Refresh data now")
            }
        }

        ToolbarItem {
            Button(action: { model.autoRefresh.toggle() }) {
                Label("Auto-refresh",
                      systemImage: model.autoRefresh ? "pause.circle.fill" : "play.circle")
            }
            .help(model.autoRefresh ? "Stop auto-refresh" : "Start auto-refresh")
        }

        ToolbarItem {
            Picker("Refresh rate", selection: $model.rate) {
                ForEach(RefreshRate.allCases) { rate in
                    Text(rate.label).tag(rate)
                }
            }
            .help("Auto-refresh interval")
        }

        ToolbarItem {
            Picker("Range", selection: $model.range) {
                ForEach(DisplayRange.allCases) { range in
                    Text(range.label).tag(range)
                }
            }
            .help("Displayed time range")
        }
    }
}
