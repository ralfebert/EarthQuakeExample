import CoreLocation
import SwiftUI

struct Earthquake: Identifiable {
    var id = UUID()
    let date: Date
    let location: CLLocationCoordinate2D
    let depth: Decimal
    let mag: Decimal

    static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter
    }()

    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        return formatter
    }()

    init(line: String) {
        let fields = line.split(separator: ",")
        self.date = Self.dateFormatter.date(from: String(fields[0]))!
        self.location = CLLocationCoordinate2D(latitude: .init(fields[1])!, longitude: .init(fields[2])!)
        self.depth = Self.numberFormatter.number(from: String(fields[2]))!.decimalValue
        self.mag = Self.numberFormatter.number(from: String(fields[3]))!.decimalValue
    }
}

class EarthquakesModel: ObservableObject {
    @Published var earthquakes = [Earthquake]()

    func load() async throws {
        self.earthquakes = []
        let url = URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv")!

        var bufferedResults = [Earthquake]()
        for try await line in url.lines {
            if !line.hasPrefix("time,latitude,") {
                bufferedResults.append(Earthquake(line: line))
            }
            if bufferedResults.count > 100 {
                let results = bufferedResults
                Task { @MainActor in earthquakes.append(contentsOf: results) }
                bufferedResults.removeAll()
            }
        }
        let results = bufferedResults
        Task { @MainActor in earthquakes.append(contentsOf: results) }
    }

}

struct ContentView: View {
    @StateObject var earthquakesModel = EarthquakesModel()

    var body: some View {
        NavigationView {
            List(earthquakesModel.earthquakes) { earthquake in
                VStack(alignment: .leading) {
                    Text("\(earthquake.date, format: .dateTime)")
                    Text("Magnitude: \(earthquake.mag, format: .number.precision(.significantDigits(2)))")
                }
            }
            .navigationTitle("Earthquakes")
            .navigationBarItems(trailing: self.navBarButtons)
        }
    }

    @ViewBuilder var navBarButtons: some View {
        Button(
            action: {
                Task {
                    try! await earthquakesModel.load()
                }
            },
            label: {
                Image(systemName: "arrow.clockwise")
            }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
