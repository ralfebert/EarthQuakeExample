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
        date = Self.dateFormatter.date(from: String(fields[0]))!
        location = CLLocationCoordinate2D(latitude: .init(fields[1])!, longitude: .init(fields[2])!)
        depth = Self.numberFormatter.number(from: String(fields[2]))!.decimalValue
        mag = Self.numberFormatter.number(from: String(fields[3]))!.decimalValue
    }
}

@MainActor
class EarthquakesModel: ObservableObject {
    @Published var earthquakes = [Earthquake]()

    func load() async throws {
        earthquakes = []
        let url = URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv")!
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
