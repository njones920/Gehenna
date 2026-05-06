import Foundation

let url = URL(fileURLWithPath: "Sources/GehennaEngine/Content/Data/npcs.json")
let data = try Data(contentsOf: url)
print("Loaded data: \(data.count) bytes")
do {
    // We cannot import GehennaEngine from a script easily, but we can see if it parses as JSON array
    let json = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
    print("Parsed JSON array with \(json.count) elements")
} catch {
    print("Failed: \(error)")
}
