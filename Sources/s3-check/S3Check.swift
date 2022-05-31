import Foundation

import ArgumentParser
import Parsing
import SotoS3


@main
struct S3Check: AsyncParsableCommand {
    @Option(help: "AWS access key ID")
    var awsAccessKeyId: String

    @Option(help: "AWS bucket name")
    var awsBucketName: String

    @Option(help: "AWS secrete access key")
    var awsSecretAccessKey: String

    func run() async throws {
        print("Checking \(awsBucketName)")

        let key = S3StoreKey(bucket: awsBucketName, directory: "apple/swift-docc")
        let client = AWSClient(credentialProvider: .static(accessKeyId: awsAccessKeyId,
                                                           secretAccessKey: awsSecretAccessKey),
                               httpClientProvider: .createNew)
        defer { try? client.syncShutdown() }

        let s3 = S3(client: client, region: .useast2)

        // filter this down somewhat by eliminating `.json` files
        let files = try await s3.listFiles(in: awsBucketName, key: key, delimiter: ".json")
        for f in files {
            if let path = try? folder.parse(f.file.key) {
                print(path.ref, path.product)
            }
        }
        print("Count: \(files.count)")
    }

}


struct Path {
    var owner: String
    var repository: String
    var ref: String
    var product: String
}


let pathSegment = Parse {
    PrefixUpTo("/").map(.string)
    "/"
}

let folder = Parse(Path.init) {
    pathSegment
    pathSegment
    pathSegment
    "documentation/"
    pathSegment
    "index.html"
}

struct S3File {
    var bucket: String
    var key: String
}


struct S3FileDescriptor {
    let file: S3File
    let modificationDate: Date
    let size: Int
}

extension S3 {
    func listFiles(in bucket: String, key: S3StoreKey, delimiter: String? = nil) async throws -> [S3FileDescriptor] {
        try await listFiles(in: bucket, key: key, delimiter: delimiter).get()
    }

    func listFiles(in bucket: String, key: S3StoreKey, delimiter: String? = nil) -> EventLoopFuture<[S3FileDescriptor]> {
        let request = S3.ListObjectsV2Request(bucket: bucket, delimiter: delimiter, prefix: key.filename)
        return self.listObjectsV2Paginator(request, []) { accumulator, response, eventLoop in
            let files: [S3FileDescriptor] = response.contents?.compactMap {
                guard let key = $0.key,
                      let lastModified = $0.lastModified,
                      let fileSize = $0.size else { return nil }
                return S3FileDescriptor(
                    file: S3File(bucket: bucket, key: key),
                    modificationDate: lastModified,
                    size: Int(fileSize)
                )
            } ?? []
            return eventLoop.makeSucceededFuture((true, accumulator + files))
        }
    }
}


struct S3StoreKey {
    let bucket: String
    let directory: String

    var filename: String { directory }
    var url: String { "s3://\(bucket)/\(filename)" }
}
