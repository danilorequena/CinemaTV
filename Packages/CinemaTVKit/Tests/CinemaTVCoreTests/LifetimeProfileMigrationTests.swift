import Foundation
import SwiftData
import Testing
@testable import CinemaTVCore

@MainActor
@Suite struct LifetimeProfileMigrationTests {
    @Test func existingLibraryOpensAfterAddingOptionalProfileModel() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "lifetime-migration-\(UUID().uuidString).store")
        defer {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(at: URL(filePath: url.path + suffix))
            }
        }
        let oldSchema = Schema([
            MoviesToWatch.self, MoviesWatched.self,
            TVShowWatchingModel.self, TVShowWatchedModel.self,
            SeasonSD.self, EpisodeSD.self, MovieReview.self,
            PersonalBox.self, BoxAuthorProfile.self
        ])
        do {
            let configuration = ModelConfiguration(schema: oldSchema, url: url, cloudKitDatabase: .none)
            let container = try ModelContainer(for: oldSchema, configurations: configuration)
            container.mainContext.insert(MoviesWatched(id: 603, name: "The Matrix"))
            try container.mainContext.save()
        }
        let newConfiguration = ModelConfiguration(schema: ModelContainerFactory.schema, url: url, cloudKitDatabase: .none)
        let reopened = try ModelContainer(for: ModelContainerFactory.schema, configurations: newConfiguration)
        #expect(try reopened.mainContext.fetch(FetchDescriptor<MoviesWatched>()).first?.name == "The Matrix")
        #expect(try reopened.mainContext.fetch(FetchDescriptor<LifetimeProfile>()).isEmpty)
    }
}
