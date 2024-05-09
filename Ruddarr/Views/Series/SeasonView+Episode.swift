import SwiftUI
import TelemetryClient

struct EpisodeRow: View {
    var episode: Episode

    @EnvironmentObject var settings: AppSettings
    @Environment(SonarrInstance.self) var instance

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Text("\(episode.episodeNumber.formatted()).", comment: "Prefix for episode title (episode number)")
                        .foregroundStyle(.secondary)

                    Text(episode.titleLabel)
                        .lineLimit(1)
                }

                // TODO: quality & file size (instead of status?)
                HStack(spacing: 6) {
                    Text(episode.statusLabel)
                    Bullet()
                    Text(episode.airingToday ? episode.airDateTimeLabel : episode.airDateLabel)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let finale = episode.finaleType {
                    Text(finale.label)
                        .font(.subheadline)
                        .foregroundStyle(settings.theme.tint)
                }
            }.padding(.trailing)

            Spacer()

            monitorButton
        }
        .contentShape(Rectangle())
    }

    var series: Series? {
        instance.series.byId(episode.seriesId).wrappedValue
    }

    var monitorButton: some View {
        Button {
            Task { await toggleMonitor() }
        } label: {
            Image(systemName: "bookmark")
                .symbolVariant(episode.monitored ? .fill : .none)
        }
        .buttonStyle(.plain)
        .overlay(Rectangle().padding(18))
        .allowsHitTesting(!instance.episodes.isMonitoring)
        .disabled(!(series?.monitored ?? false))
    }

    @MainActor
    func toggleMonitor() async {
        guard let index = instance.episodes.items.firstIndex(where: { $0.id == episode.id }) else {
            return
        }

        instance.episodes.items[index].monitored.toggle()

        guard await instance.episodes.monitor([episode.id], episode.monitored) else {
            return
        }

        dependencies.toast.show(episode.monitored ? .monitored : .unmonitored)
    }
}

#Preview {
    let series: [Series] = PreviewData.load(name: "series")
    let item = series.first(where: { $0.id == 67 }) ?? series[0] // 15

    dependencies.router.selectedTab = .series

    dependencies.router.seriesPath.append(
        SeriesPath.series(item.id)
    )

    dependencies.router.seriesPath.append(
        SeriesPath.season(item.id, 2)
    )

    return ContentView()
        .withSonarrInstance(series: series)
        .withAppState()
}
