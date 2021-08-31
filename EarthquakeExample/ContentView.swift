import CoreLocation
import SwiftUI

struct Earthquake: Identifiable {
    var id = UUID()
    var date: Date
    var location: CLLocationCoordinate2D

    init(line: String) {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFractionalSeconds]

        let fields = line.split(separator: ",")
        self.date = dateFormatter.date(from: String(fields[0]))!
        self.location = CLLocationCoordinate2D(latitude: .init(fields[1])!, longitude: .init(fields[2])!)
    }
}

@MainActor
class EarthquakesModel: ObservableObject {

    @Published var earthquakes = [Earthquake]()

    func load() async throws {
        self.earthquakes = []
        let url = URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv")!
        for try await line in url.lines {
            if !line.hasPrefix("time,") {
                self.earthquakes.append(Earthquake(line: line))
            }
        }
    }

}

struct ContentView: View {

    @StateObject var earthquakesModel = EarthquakesModel()

    var body: some View {
        VStack(spacing: 10) {
            Text("\(earthquakesModel.earthquakes.count) earthquakes")
            Button("Reload") {
                Task {
                    try! await earthquakesModel.load()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
