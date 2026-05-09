import Foundation

public struct LFSPointer: Equatable, Sendable {
    public let oid: String
    public let size: Int64

    public static func parse(data: Data) -> LFSPointer? {
        guard data.count <= 1024,
              let content = String(data: data, encoding: .utf8),
              content.hasPrefix("version https://git-lfs.github.com/spec/v1") else {
            return nil
        }

        var oid: String?
        var size: Int64?

        for line in content.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("oid sha256:") {
                oid = String(line.dropFirst("oid sha256:".count))
            } else if line.hasPrefix("size ") {
                size = Int64(line.dropFirst("size ".count))
            }
        }

        guard let oid, let size else {
            return nil
        }

        return LFSPointer(oid: oid, size: size)
    }
}
