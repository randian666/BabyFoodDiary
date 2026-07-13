import Foundation

/// A self-contained backup bundle: structured JSON payload plus binary file blobs (photos).
struct BackupBundle {
    /// Will be serialized to `data.json` via `JSONSerialization`.
    var payload: [String: Any]
    /// Relative archive path → file data. e.g. `"photos/avatar.jpg"`.
    var files: [String: Data]

    init(payload: [String: Any] = [:], files: [String: Data] = [:]) {
        self.payload = payload
        self.files = files
    }
}

/// Minimal, dependency-free ZIP container codec using the STORE method (no compression).
///
/// Photos are already-compressed JPEGs, so re-compressing would not help and STORE keeps the
/// implementation small and auditable. Produced archives are readable by macOS Archive Utility
/// and the system `unzip`.
enum BackupArchive {
    enum Error: Swift.Error {
        case read(String)
        case unsupportedCompression(UInt16)
        case truncated
    }

    private static let localHeaderSignature: UInt32 = 0x04034b50
    private static let centralHeaderSignature: UInt32 = 0x02014b50
    private static let endOfCentralDirectorySignature: UInt32 = 0x06054b50

    // MARK: Write

    /// Writes the bundle (data.json + photo blobs) as a STORE-only `.zip` at `url`.
    static func writeZip(_ bundle: BackupBundle, to url: URL) throws {
        var out = Data()
        var central = Data()
        var entries: [(name: String, crc: UInt32, size: UInt32, offset: UInt32)] = []

        let jsonData = try JSONSerialization.data(withJSONObject: bundle.payload, options: [.prettyPrinted, .sortedKeys])
        var allFiles = bundle.files
        allFiles["data.json"] = jsonData

        // Deterministic order: data.json first, then photos sorted by name.
        let orderedNames = allFiles.keys.sorted(by: { lhs, rhs in
            if lhs == "data.json" { return true }
            if rhs == "data.json" { return false }
            return lhs < rhs
        })

        for name in orderedNames {
            let data = allFiles[name] ?? Data()
            let nameBytes = Array(name.utf8)
            let crc = crc32(data)
            let offset = UInt32(out.count)

            // Local file header (signature 0x04034b50)
            out.appendLE(localHeaderSignature)
            out.appendLE(UInt16(20))            // version needed to extract
            out.appendLE(UInt16(0x0800))        // general purpose bit flag: bit 11 = UTF-8 filename
            out.appendLE(UInt16(0))             // compression method = STORE
            out.appendLE(UInt16(0))             // last mod file time
            out.appendLE(UInt16(0))             // last mod file date
            out.appendLE(crc)                   // CRC-32
            out.appendLE(UInt32(data.count))    // compressed size
            out.appendLE(UInt32(data.count))    // uncompressed size
            out.appendLE(UInt16(nameBytes.count))
            out.appendLE(UInt16(0))             // extra field length
            out.append(contentsOf: nameBytes)
            out.append(data)

            entries.append((name, crc, UInt32(data.count), offset))
        }

        // Central directory records (signature 0x02014b50)
        for entry in entries {
            let nameBytes = Array(entry.name.utf8)
            central.appendLE(centralHeaderSignature)
            central.appendLE(UInt16(20))            // version made by
            central.appendLE(UInt16(20))            // version needed to extract
            central.appendLE(UInt16(0x0800))        // GP bit flag (UTF-8)
            central.appendLE(UInt16(0))             // compression method = STORE
            central.appendLE(UInt16(0))             // last mod file time
            central.appendLE(UInt16(0))             // last mod file date
            central.appendLE(entry.crc)
            central.appendLE(entry.size)            // compressed size
            central.appendLE(entry.size)            // uncompressed size
            central.appendLE(UInt16(nameBytes.count))
            central.appendLE(UInt16(0))             // extra field length
            central.appendLE(UInt16(0))             // file comment length
            central.appendLE(UInt16(0))             // disk number start
            central.appendLE(UInt16(0))             // internal file attributes
            central.appendLE(UInt32(0))             // external file attributes
            central.appendLE(entry.offset)          // relative offset of local header
            central.append(contentsOf: nameBytes)
        }

        let centralStart = UInt32(out.count)
        out.append(central)

        // End of central directory record (signature 0x06054b50)
        out.appendLE(endOfCentralDirectorySignature)
        out.appendLE(UInt16(0))                         // number of this disk
        out.appendLE(UInt16(0))                         // disk where central dir starts
        out.appendLE(UInt16(entries.count))             // entries on this disk
        out.appendLE(UInt16(entries.count))             // total entries
        out.appendLE(UInt32(central.count))             // size of central directory
        out.appendLE(centralStart)                      // offset of start of central directory
        out.appendLE(UInt16(0))                         // comment length

        try out.write(to: url, options: .atomic)
    }

    // MARK: Read

    /// Reads a `.zip` at `url` into a `BackupBundle` (data.json decoded to payload + all files).
    static func readZip(at url: URL) throws -> BackupBundle {
        let data = try Data(contentsOf: url)
        let bytes = [UInt8](data)
        guard bytes.count >= 22 else { throw Error.truncated }

        // Locate EOCD by scanning backwards for its signature.
        var eocd = -1
        let lowerBound = max(0, bytes.count - 22 - 65535)
        var i = bytes.count - 22
        while i >= lowerBound {
            if readU32(bytes, i) == endOfCentralDirectorySignature {
                eocd = i
                break
            }
            i -= 1
        }
        guard eocd >= 0 else { throw Error.read("EOCD not found") }

        let totalEntries = readU16(bytes, eocd + 10)
        let centralSize = readU32(bytes, eocd + 12)
        let centralOffset = readU32(bytes, eocd + 16)

        var files: [String: Data] = [:]
        var cursor = Int(centralOffset)
        let end = Int(centralOffset) + Int(centralSize)

        for _ in 0..<totalEntries {
            guard cursor + 46 <= end, readU32(bytes, cursor) == centralHeaderSignature else {
                throw Error.read("bad central directory entry")
            }
            let method = readU16(bytes, cursor + 10)
            guard method == 0 else { throw Error.unsupportedCompression(method) }
            let compressedSize = Int(readU32(bytes, cursor + 20))
            let nameLen = Int(readU16(bytes, cursor + 28))
            let extraLen = Int(readU16(bytes, cursor + 30))
            let commentLen = Int(readU16(bytes, cursor + 32))
            let localOffset = Int(readU32(bytes, cursor + 42))
            let nameStart = cursor + 46
            guard let name = String(bytes: Array(bytes[nameStart..<(nameStart + nameLen)]), encoding: .utf8) else {
                throw Error.read("bad filename")
            }

            // Jump to the local header to find the actual data start.
            guard localOffset + 30 <= bytes.count, readU32(bytes, localOffset) == localHeaderSignature else {
                throw Error.read("bad local header for \(name)")
            }
            let localNameLen = Int(readU16(bytes, localOffset + 26))
            let localExtraLen = Int(readU16(bytes, localOffset + 28))
            let dataStart = localOffset + 30 + localNameLen + localExtraLen
            guard dataStart + compressedSize <= bytes.count else { throw Error.read("data truncated for \(name)") }
            files[name] = Data(bytes[dataStart..<(dataStart + compressedSize)])

            cursor = nameStart + nameLen + extraLen + commentLen
        }

        var payload: [String: Any] = [:]
        if let jsonData = files.removeValue(forKey: "data.json") {
            payload = (try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]) ?? [:]
        }
        return BackupBundle(payload: payload, files: files)
    }

    // MARK: CRC-32 (reflected, polynomial 0xEDB88320)

    private static let crcTable: [UInt32] = {
        var table = [UInt32](repeating: 0, count: 256)
        for n in 0..<256 {
            var c = UInt32(n)
            for _ in 0..<8 {
                c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
            }
            table[n] = c
        }
        return table
    }()

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc = crcTable[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }

    // MARK: Little-endian readers

    private static func readU16(_ bytes: [UInt8], _ at: Int) -> UInt16 {
        UInt16(bytes[at]) | (UInt16(bytes[at + 1]) << 8)
    }

    private static func readU32(_ bytes: [UInt8], _ at: Int) -> UInt32 {
        UInt32(bytes[at]) | (UInt32(bytes[at + 1]) << 8) | (UInt32(bytes[at + 2]) << 16) | (UInt32(bytes[at + 3]) << 24)
    }
}

private extension Data {
    mutating func appendLE(_ value: UInt16) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
    }
    mutating func appendLE(_ value: UInt32) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 24) & 0xFF))
    }
}
