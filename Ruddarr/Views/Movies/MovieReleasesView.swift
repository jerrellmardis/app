import SwiftUI

struct MovieReleasesView: View {
    @Binding var movie: Movie

    @State private var sort: MovieReleaseSort = .init()
    @State private var indexer: String = ""
    @State private var fetched = false

    @Environment(RadarrInstance.self) private var instance

    var body: some View {
        Group {
            List {
                ForEach(displayedReleases) { release in
                    MovieReleaseRow(release: release)
                }
            }
            .listStyle(.inset)
        }
        .navigationTitle("Releases")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarSortingButton
        }
        .task {
            guard !fetched else { return }

            await instance.releases.search(movie)

            fetched = true
        }
        .overlay {
            if instance.releases.isSearching {
                ProgressView {
                    VStack {
                        Text("Loading")
                        Text("(This may take a moment)").font(.callout)
                    }
                }.tint(.secondary)
            }
        }
    }

    var displayedReleases: [MovieRelease] {
        var sortedReleases = instance.releases.items.sorted(
            by: sort.option.isOrderedBefore
        )

        if !indexer.isEmpty {
            sortedReleases = sortedReleases.filter { $0.indexerLabel == indexer }
        }

        return sort.isAscending ? sortedReleases : sortedReleases.reversed()
    }

    var indexers: [String] {
        var seen: Set<String> = []

        return instance.releases.items
            .map { $0.indexerLabel }
            .filter { seen.insert($0).inserted }
            .sorted()
    }

    @ToolbarContentBuilder
    var toolbarSortingButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {

            Menu("Sorting & Filters", systemImage: "line.3.horizontal.decrease") {
                Menu("Indexer") {
                    Picker("Indexer", selection: $indexer) {
                        ForEach(indexers, id: \.self) { indexer in
                            Text(indexer).tag(Optional.some(indexer))
                        }
                    }

                    Text("All Indexers").tag("")
                }

                Picker("Sorting options", selection: $sort.option) {
                    ForEach(MovieReleaseSort.Option.allCases) { sortOption in
                        Text(sortOption.title).tag(sortOption)
                    }
                }

                Section {
                    Picker("Sorting direction", selection: $sort.isAscending) {
                        Text("Ascending").tag(true)
                        Text("Descending").tag(false)
                    }
                }
            }
        }
    }
}

struct MovieReleaseRow: View {
    var release: MovieRelease

    @State private var isShowingPopover = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    if !release.indexerFlags.isEmpty {
                        Image(systemName: "flag")
                            .symbolVariant(.fill)
                            .imageScale(.small)
                            .foregroundStyle(.secondary)
                    }

                    Text(release.title)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                }

                HStack(spacing: 6) {
                    Text(release.quality.quality.name)
                    Text("•")
                    Text(release.sizeLabel)
                    Text("•")
                    Text(release.ageLabel)
                }
                .font(.subheadline)
                .lineLimit(1)

                HStack(spacing: 6) {
                    Text(release.typeLabel)
                        .foregroundStyle(peerColor)
                    Text("•")
                    Text(release.indexerLabel)
                }
                .font(.subheadline)
                .lineLimit(1)
            }
            .padding(.trailing, 10)

            Spacer()

            Group {
                if release.rejected {
                    Image(systemName: "exclamationmark")
                        .symbolVariant(.circle.fill)
                        .imageScale(.large)
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "arrow.down")
                        .symbolVariant(.circle.fill)
                        .imageScale(.large)
                }
            }

        }
        .onTapGesture {
            isShowingPopover = true
        }
        .sheet(isPresented: $isShowingPopover) {
            MovieReleaseSheet(release: release)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }

    }

    var peerColor: any ShapeStyle {
        return switch release.seeders {
        case 50...: .green
        case 10..<50: .blue
        case 1..<10: .orange
        default: .red
        }
    }
}

#Preview {
    let movies: [Movie] = PreviewData.load(name: "movies")
    let movie = movies.first(where: { $0.id == 66 }) ?? movies[0]

    dependencies.router.selectedTab = .movies
    dependencies.router.moviesPath.append(MoviesView.Path.movie(movie.id))
    dependencies.router.moviesPath.append(MoviesView.Path.releases(movie.id))

    return ContentView()
        .withSettings()
        .withRadarrInstance(movies: movies)
}
