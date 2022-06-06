import Foundation
import Parsing
import SotoS3


public enum S3DocArchives {

    public static func fetch(
        prefix: String,
        awsBucketName: String,
        awsAccessKeyId: String,
        awsSecretAccessKey: String) async throws -> [DocArchive] {

            let key = S3.StoreKey(bucket: awsBucketName, path: prefix)
            let client = AWSClient(credentialProvider: .static(accessKeyId: awsAccessKeyId,
                                                               secretAccessKey: awsSecretAccessKey),
                                   httpClientProvider: .createNew)
            defer { try? client.syncShutdown() }

            let s3 = S3(client: client, region: .useast2)

            // filter this down somewhat by eliminating `.json` files
            let paths = try await s3.listFiles(key: key, delimiter: ".json")
                .compactMap { try? DocArchive.path.parse($0.file.key) }

            var archives = [DocArchive]()
            for path in paths {
                archives.append(await DocArchive(s3: s3, in: awsBucketName, path: path))
            }

            return archives
        }


    public struct DocArchive: CustomStringConvertible {
        var path: Path
        var title: String

        init(s3: S3, in bucket: String, path: Path) async {
            self.path = path
            self.title = (try? await s3.getDocArchiveTitle(in: bucket, path: path)) ?? path.product
        }

        public var description: String {
            "\(path) - \(title)"
        }

        struct Path: CustomStringConvertible {
            var owner: String
            var repository: String
            var ref: String
            var product: String

            var s3path: String { "\(owner)/\(repository)/\(ref)" }

            public var description: String {
                "\(owner)/\(repository) @ \(ref) - \(product)"
            }

            func getTitle(s3: S3, in bucket: String) async throws -> String {
                let key = S3.StoreKey(bucket: bucket, path: s3path)
                if let data = try await s3.getFileContent(key: key) {
                    return try JSONDecoder().decode(DocumentationData.self, from: data)
                        .metadata.title
                } else {
                    return product
                }
            }
        }

        static let pathSegment = Parse {
            PrefixUpTo("/").map(.string)
            "/"
        }


        static let path = Parse(DocArchive.Path.init) {
            pathSegment
            pathSegment
            pathSegment
            "documentation/"
            pathSegment
            "index.html"
        }

    }

    struct DocumentationData: Codable, Equatable {
        var metadata: Metadata

        struct Metadata: Codable, Equatable {
                var title: String
        }
    }

}


private extension S3 {

    struct File {
        var bucket: String
        var key: String
    }


    struct FileDescriptor {
        let file: File
        let modificationDate: Date
        let size: Int
    }


    struct StoreKey {
        let bucket: String
        var path: String

        var url: String { "s3://\(bucket)/\(path)" }
    }

    func getFileContent(key: StoreKey) async throws -> Data? {
        let getObjectRequest = S3.GetObjectRequest(bucket: key.bucket, key: key.path)
        return try await self.getObject(getObjectRequest)
            .body?.asData()
    }

    func listFiles(key: StoreKey, delimiter: String? = nil) async throws -> [FileDescriptor] {
        try await listFiles(key: key, delimiter: delimiter).get()
    }

    func listFiles(key: StoreKey, delimiter: String? = nil) -> EventLoopFuture<[FileDescriptor]> {
        let bucket = key.bucket
        let request = S3.ListObjectsV2Request(bucket: bucket, delimiter: delimiter, prefix: key.path)
        return listObjectsV2Paginator(request, []) { accumulator, response, eventLoop in
            let files: [FileDescriptor] = response.contents?.compactMap {
                guard let key = $0.key,
                      let lastModified = $0.lastModified,
                      let fileSize = $0.size else { return nil }
                return FileDescriptor(
                    file: File(bucket: bucket, key: key),
                    modificationDate: lastModified,
                    size: Int(fileSize)
                )
            } ?? []
            return eventLoop.makeSucceededFuture((true, accumulator + files))
        }
    }

    func getDocArchiveTitle(in bucket: String,
                            path: S3DocArchives.DocArchive.Path) async throws -> String? {
        let key = S3.StoreKey(bucket: bucket,
                              path: path.s3path + "/data/documentation/\(path.product).json")
        guard let data = try await getFileContent(key: key) else { return nil }
        return try JSONDecoder().decode(S3DocArchives.DocumentationData.self, from: data)
            .metadata.title
    }

}


