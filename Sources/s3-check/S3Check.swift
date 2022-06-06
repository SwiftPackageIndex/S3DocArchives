import ArgumentParser
import S3DocArchives


@main
struct S3Check: AsyncParsableCommand {
    @Option(help: "AWS access key ID")
    var awsAccessKeyId: String

    @Option(help: "AWS bucket name")
    var awsBucketName: String

    @Option(help: "AWS secrete access key")
    var awsSecretAccessKey: String

    @Argument(help: "path prefix, for example 'apple/swift-docc'")
    var prefix: String

    func run() async throws {
        print("Checking \(awsBucketName)")

        let docSets = try await S3DocArchives.fetch(prefix: prefix,
                                                   awsBucketName: awsBucketName,
                                                   awsAccessKeyId: awsAccessKeyId,
                                                   awsSecretAccessKey: awsSecretAccessKey)

        guard !docSets.isEmpty else {
            print("No results.")
            return
        }

        for d in docSets {
            print(d)
        }
    }

}

